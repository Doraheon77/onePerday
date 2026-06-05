import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:simcap/core/constant/app_constants.dart';
import 'package:simcap/features/cabinet/domain/dataModels/supplement_model.dart';
import 'package:simcap/features/cabinet/widgets/drum_roll_time_picker.dart';
import 'package:simcap/providers/supplement_provider.dart';
import 'package:simcap/services/conflict_api_service.dart';
import 'package:simcap/services/store_api_service.dart';
import 'package:simcap/services/auth_service.dart';
import 'package:simcap/services/cabinet_api_service.dart';
import 'package:simcap/features/store/data/store_product_data.dart';
import 'package:simcap/features/store/presentation/supplement_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SupplementInfoScreen extends StatefulWidget {
  final Supplement supplement;
  const SupplementInfoScreen({super.key, required this.supplement});

  @override
  State<SupplementInfoScreen> createState() => _SupplementInfoScreenState();
}

class _SupplementInfoScreenState extends State<SupplementInfoScreen> {
  late TextEditingController _remainingController;
  late List<TimeOfDay> _alarmTimes;

  List<Map<String, String>> _overdoseConflicts = [];
  List<Map<String, String>> _interactionConflicts = [];
  bool _isSafetyLoading = false;
  StoreProduct? _matchedProduct;

  @override
  void initState() {
    super.initState();
    _remainingController = TextEditingController(
      text: widget.supplement.remaining > 0
          ? widget.supplement.remaining.toString()
          : (widget.supplement.total > 0
                ? widget.supplement.total.toString()
                : ''),
    );
    _alarmTimes = List.from(widget.supplement.alarmTimes);
    _resolveAndCheckSafety();
  }

  Future<void> _resolveAndCheckSafety() async {
    if (!mounted) return;
    setState(() {
      _isSafetyLoading = true;
    });

    try {
      // 1. 매칭 상품 찾기 (로컬 & DB)
      StoreProduct? matched;
      for (final p in allProducts) {
        if (p.name.contains(widget.supplement.name) ||
            widget.supplement.name.contains(p.name)) {
          matched = p;
          break;
        }
      }
      if (matched == null) {
        try {
          final realProducts = await StoreApiService().fetchSupplements();
          for (final p in realProducts) {
            if (p.name.contains(widget.supplement.name) ||
                widget.supplement.name.contains(p.name)) {
              matched = p;
              break;
            }
          }
        } catch (e) {
          debugPrint('DB 제품 조회 실패: $e');
        }
      }

      if (mounted) {
        setState(() {
          _matchedProduct = matched;
          if (_remainingController.text.isEmpty && matched != null) {
            final matchedTotal = matched.toSupplement().total;
            if (matchedTotal > 0) {
              _remainingController.text = matchedTotal.toString();
            }
          }
        });
      }

      final cabinets = SupplementProvider.of(context).supplements;

      // 2. 과다복용 여부 분석 (동일 성분 중복 및 함량 계산)
      final List<Map<String, String>> overdoseList = [];
      for (final n in widget.supplement.nutrients) {
        if (n.name.trim().isEmpty) continue;
        final List<Nutrient> matchingOtherNutrients = [];
        for (final cab in cabinets) {
          if (cab.id == widget.supplement.id) continue;
          for (final cn in cab.nutrients) {
            if (cn.name.trim().toLowerCase() == n.name.trim().toLowerCase()) {
              matchingOtherNutrients.add(cn);
            }
          }
        }

        if (matchingOtherNutrients.isNotEmpty) {
          double totalValue = n.value;
          double totalPercent = n.percent;
          for (final cn in matchingOtherNutrients) {
            totalValue += cn.value;
            totalPercent += cn.percent;
          }

          String status = '안전';
          if (totalPercent > 1.5) {
            status = '위험';
          } else if (totalPercent > 1.0) {
            status = '주의';
          }

          overdoseList.add({
            'nutrient': n.name,
            'current':
                '${totalValue.toInt()}${n.unit} (${(totalPercent * 100).round()}%)',
            'limit': '기준치 100%',
            'status': status,
          });
        }
      }

      // 3. 병용금지/만성질환/알레르기 충돌 여부 분석
      final List<Map<String, String>> interactionList = [];
      final prefs = await SharedPreferences.getInstance();
      final userHealth = prefs.getStringList('selectedHealth') ?? [];
      final userAllergies = prefs.getStringList('selectedAllergies') ?? [];

      final currentProductId = matched != null
          ? int.tryParse(matched.id)
          : null;
      final cabinetSuppsJson = cabinets
          .where((s) => s.id != widget.supplement.id) // 본인 제외
          .map(
            (s) => {
              'name': s.name,
              'ingredients': s.nutrients.map((n) => n.name).toList(),
            },
          )
          .toList();

      // 만약 신규 영양제가 DB ID가 없다면, cabinetSuppsJson에 수동 추가해서 충돌을 검사함
      final List<int> supplementIds = [];
      final List<Map<String, dynamic>> checkCabinetSupps = List.from(
        cabinetSuppsJson,
      );

      if (currentProductId != null) {
        supplementIds.add(currentProductId);
      } else {
        checkCabinetSupps.add({
          'name': widget.supplement.name,
          'ingredients': widget.supplement.nutrients
              .map((n) => n.name)
              .toList(),
        });
      }

      final conflictApi = ConflictApiService();
      final backendConflicts = await conflictApi.checkConflictsBySupplementIds(
        supplementIds: supplementIds,
        cabinetSupplements: checkCabinetSupps,
        userHealth: userHealth,
        userAllergies: userAllergies,
      );

      for (final conflict in backendConflicts) {
        // 이 영양제와 관련된 충돌만 추출
        if (conflict.conflicts.contains(widget.supplement.name)) {
          final other = conflict.conflicts.firstWhere(
            (name) => name != widget.supplement.name,
            orElse: () => '',
          );

          interactionList.add({
            'supplement': other.isNotEmpty ? other : '개인 건강 설정',
            'nutrient': conflict.conflictingIngredients.join(', '),
            'reason': conflict.reason,
          });
        }
      }

      if (mounted) {
        setState(() {
          _overdoseConflicts = overdoseList;
          _interactionConflicts = interactionList;
        });
      }
    } catch (e) {
      debugPrint('안전성 분석 실패: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSafetyLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _remainingController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay t) {
    final isPm = t.hour >= 12;
    final h = t.hour == 0 ? 12 : (t.hour > 12 ? t.hour - 12 : t.hour);
    final m = t.minute.toString().padLeft(2, '0');
    return '${isPm ? "오후" : "오전"} $h:$m';
  }

  Future<void> _pickAlarmTime(int index) async {
    final initial = index < _alarmTimes.length
        ? _alarmTimes[index]
        : const TimeOfDay(hour: 9, minute: 0);
    final picked = await showDialog<TimeOfDay>(
      context: context,
      builder: (_) => DrumRollTimePicker(initialTime: initial),
    );
    if (picked != null && mounted) {
      setState(() {
        if (index < _alarmTimes.length) {
          _alarmTimes[index] = picked;
        } else {
          _alarmTimes.add(picked);
        }
      });
    }
  }

  Future<void> _addToCabinet() async {
    if (_alarmTimes.length < widget.supplement.dailyFrequency) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('복용 알림 시간을 모두 설정해주세요!'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final remaining = int.tryParse(_remainingController.text) ?? 0;
    final resolvedTotal = widget.supplement.total > 0
        ? widget.supplement.total
        : (_matchedProduct != null ? _matchedProduct!.toSupplement().total : 0);

    final finalTotal = resolvedTotal > 0 ? resolvedTotal : remaining;

    if (finalTotal > 0 && remaining > finalTotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('잔여 개수는 전체 용량(${finalTotal}정)을 초과할 수 없습니다.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final user = AuthService().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그인이 필요합니다.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final targetSupplementId = int.tryParse(widget.supplement.supplementId ?? _matchedProduct?.id ?? widget.supplement.id ?? '');
    if (targetSupplementId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('영양제 ID를 찾을 수 없습니다. 다시 검색해주세요.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final createdItem = await CabinetApiService().createCabinetItem(
        userUuid: user.id,
        supplementId: targetSupplementId,
        dailyDose: widget.supplement.dailyDose,
        dailyFrequency: widget.supplement.dailyFrequency,
        stockCount: remaining,
        totalCount: finalTotal,
        alarmTimes: _alarmTimes.map((t) {
          final h = t.hour.toString().padLeft(2, '0');
          final m = t.minute.toString().padLeft(2, '0');
          return '$h:$m';
        }).toList(),
      );

      final newSupplement = widget.supplement.copyWith(
        id: createdItem.id,
        supplementId: createdItem.supplementId,
        inventoryId: createdItem.id,
        remaining: remaining,
        total: finalTotal,
        alarmTimes: _alarmTimes,
      );

      final notifier = SupplementProvider.of(context);
      await notifier.addSupplement(
        newSupplement,
        backendSupplementId: createdItem.supplementId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.supplement.name}을(를) 캐비닛에 추가했습니다!'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/cabinet');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('캐비닛 저장 실패: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = SupplementProvider.of(context);
    final cabinets = notifier.supplements;
    final s = widget.supplement;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '영양제 정보',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionTitle('기본 정보'),
          _readOnlyField(
            '제품명',
            s.name.isEmpty || s.name == '데이터 찾는 중...' ? '분석 중...' : s.name,
          ),
          _readOnlyField('브랜드명', s.brand.isNotEmpty ? s.brand : '분석 중...'),
          _readOnlyFieldExpanded(
            '주요 성분',
            s.nutrients.isNotEmpty
                ? s.nutrients.map((n) => n.name).join('\n')
                : '분석 중...',
          ),
          _readOnlyField('1회 복용량', '${s.dailyDose}정'),
          _readOnlyField('하루 복용 횟수', '${s.dailyFrequency}회'),
          _readOnlyField(
            '전체 용량',
            s.total > 0
                ? '${s.total}정'
                : (_matchedProduct != null &&
                          _matchedProduct!.toSupplement().total > 0
                      ? '${_matchedProduct!.toSupplement().total}정'
                      : '정보 없음'),
          ),

          const SizedBox(height: 20),

          _sectionTitle('안전성 정보'),
          _buildSafetySection(cabinets),

          const SizedBox(height: 20),

          _sectionTitle('수량 설정'),
          _subHeader('잔여 개수', '현재 남아있는 수량'),
          Row(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _remainingController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: '예: 30',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (widget.supplement.total > 0)
                        Text(
                          '/ ${widget.supplement.total}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _stepButton('+1', () {
                final cur = int.tryParse(_remainingController.text) ?? 0;
                final total = widget.supplement.total;
                if (total > 0 && cur + 1 > total) return;
                setState(
                  () => _remainingController.text = (cur + 1).toString(),
                );
              }),
              const SizedBox(width: 6),
              _stepButton('-1', () {
                final cur = int.tryParse(_remainingController.text) ?? 0;
                if (cur <= 0) return;
                setState(
                  () => _remainingController.text = (cur - 1).toString(),
                );
              }),
            ],
          ),

          const SizedBox(height: 20),

          _sectionTitle('복용 알림 시간 *'),
          _buildAlarmSection(),

          const SizedBox(height: 32),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: ElevatedButton(
            onPressed: _addToCabinet,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(56),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              '캐비닛에 추가하기',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSafetySection(List<Supplement> cabinets) {
    if (_isSafetyLoading) {
      return Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    final hasOverdose = _overdoseConflicts.any(
      (c) => c['status'] == '위험' || c['status'] == '주의',
    );
    final hasInteraction = _interactionConflicts.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // 충돌 없을 때 ⓘ 버튼
          if (!hasOverdose && !hasInteraction)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 12),
                child: GestureDetector(
                  onTap: _showConsultPopup,
                  child: const Icon(
                    Icons.info_outline,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          // 과다복용
          GestureDetector(
            onTap: () => _showOverdoseDetail(_overdoseConflicts),
            child: _safetyRow(
              Icons.monitor_heart_outlined,
              '과다복용 여부',
              hasOverdose ? '⚠️ 주의 필요' : '확인하기 ›',
              hasOverdose ? AppColors.danger : Colors.grey,
            ),
          ),
          const Divider(height: 1),
          // 병용금지
          GestureDetector(
            onTap: () => _showInteractionDetail(_interactionConflicts),
            child: _safetyRow(
              Icons.warning_amber_rounded,
              '병용금지 여부',
              hasInteraction ? '⚠️ 충돌 있음' : '확인하기 ›',
              hasInteraction ? AppColors.danger : Colors.grey,
            ),
          ),
          const Divider(height: 1),
          _safetyRow(
            Icons.inventory_2_outlined,
            '현재 캐비닛 영양제',
            '${cabinets.length}개 등록 중',
            AppColors.primary,
          ),
        ],
      ),
    );
  }

  void _showConsultPopup() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.local_hospital_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              '전문의 상담 안내',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          '영양제 복용에 관한 정확한 판단은 전문의와 상담하는 것이 가장 안전합니다.\n\n'
          '특히 만성질환, 임신, 약물 복용 중인 경우 반드시 전문의와 상의 후 복용하세요.',
          style: TextStyle(fontSize: 14, height: 1.6),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      '닫기',
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showOverdoseDetail(List<Map<String, String>> conflicts) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.75,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 40,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.monitor_heart_outlined,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '과다복용 분석',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '캐비닛 영양제와 합산한 성분별 섭취량입니다.',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 16),
              if (conflicts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '중복되거나 과다복용 우려가 있는 성분이 없습니다.',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...conflicts.map((c) {
                  final isSafe = c['status'] == '안전';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSafe
                          ? AppColors.primaryLight
                          : AppColors.dangerBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c['nutrient']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '현재 ${c['current']}  /  상한 ${c['limit']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSafe
                                ? AppColors.primary
                                : AppColors.danger,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            c['status']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  void _showInteractionDetail(List<Map<String, String>> conflicts) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.75,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 40,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '병용금지 분석',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '캐비닛 영양제와의 성분 충돌 여부입니다.',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 16),
              conflicts.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '충돌하는 영양제가 없습니다.',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: conflicts
                          .map(
                            (c) => Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.dangerBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.warning_amber_rounded,
                                        color: AppColors.danger,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        c['supplement']!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.danger,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '충돌 성분: ${c['nutrient']}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '사유: ${c['reason']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _safetyRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(widget.supplement.dailyFrequency, (i) {
              final isSet = _alarmTimes.length > i;
              final label = widget.supplement.dailyFrequency == 1
                  ? (isSet ? _formatTime(_alarmTimes[i]) : '알림 시간 설정하기')
                  : (isSet
                        ? '${i + 1}회차 · ${_formatTime(_alarmTimes[i])}'
                        : '알림 시간${i + 1} 설정하기');
              return GestureDetector(
                onTap: () => _pickAlarmTime(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSet ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: isSet ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSet ? Icons.access_time : Icons.add_alarm_outlined,
                        size: 14,
                        color: isSet ? Colors.white : Colors.grey,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSet ? Colors.white : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          if (_alarmTimes.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _alarmTimes = []),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                '초기화',
                style: TextStyle(fontSize: 12, color: AppColors.danger),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _stepButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // 주요 성분 등 긴 텍스트 — 줄바꿈으로 전체 표시
  Widget _readOnlyFieldExpanded(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _readOnlyField(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start, // 줄바꿈 발생 시 정렬 보정
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editableField(
    String hint,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          border: InputBorder.none,
        ),
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }
}
