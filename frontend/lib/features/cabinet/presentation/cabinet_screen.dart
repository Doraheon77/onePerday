import 'package:flutter/material.dart';
import 'package:simcap/core/constant/app_constants.dart';
import 'package:simcap/features/cabinet/widgets/supplement_card.dart';
import 'package:simcap/features/cabinet/domain/dataModels/supplement_model.dart';
import 'package:simcap/providers/supplement_provider.dart';
import 'package:go_router/go_router.dart';

// ── 정렬 옵션 ─────────────────────────────────────────────────────────────────
enum _SortOption {
  registeredDesc, // 등록순 (기본)
  nameAsc, // 이름순
  stockAsc, // 소진 임박순
}

extension _SortOptionLabel on _SortOption {
  String get label {
    switch (this) {
      case _SortOption.registeredDesc:
        return '등록순';
      case _SortOption.nameAsc:
        return '이름순';
      case _SortOption.stockAsc:
        return '소진 임박순';
    }
  }

  IconData get icon {
    switch (this) {
      case _SortOption.registeredDesc:
        return Icons.access_time_rounded;
      case _SortOption.nameAsc:
        return Icons.sort_by_alpha_rounded;
      case _SortOption.stockAsc:
        return Icons.warning_amber_rounded;
    }
  }
}

class CabinetScreen extends StatefulWidget {
  const CabinetScreen({super.key});

  @override
  State<CabinetScreen> createState() => _CabinetScreenState();
}

class _CabinetScreenState extends State<CabinetScreen> {
  _SortOption _sortOption = _SortOption.registeredDesc;
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Supplement> _sorted(List<Supplement> all) {
    final list = List<Supplement>.from(all);
    final filtered = _searchQuery.isEmpty
        ? list
        : list
              .where(
                (s) =>
                    s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    s.brand.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    s.nutrients.any(
                      (n) => n.name.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ),
                    ),
              )
              .toList();

    switch (_sortOption) {
      case _SortOption.registeredDesc:
        return filtered;
      case _SortOption.nameAsc:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        return filtered;
      case _SortOption.stockAsc:
        filtered.sort((a, b) {
          final dA = a.daysUntilEmpty ?? 9999;
          final dB = b.daysUntilEmpty ?? 9999;
          return dA.compareTo(dB);
        });
        return filtered;
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  /// 정렬 옵션 선택 바텀시트
  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '정렬 기준',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._SortOption.values.map(
              (opt) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  opt.icon,
                  color: _sortOption == opt ? AppColors.primary : Colors.grey,
                ),
                title: Text(
                  opt.label,
                  style: TextStyle(
                    fontWeight: _sortOption == opt
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: _sortOption == opt
                        ? AppColors.primary
                        : Colors.black87,
                  ),
                ),
                trailing: _sortOption == opt
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _sortOption = opt);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateAndAddSupplement() async {
    final notifier = SupplementProvider.of(context);
    final Supplement? newSupplement = await context.push<Supplement>(
      '/cabinet/add',
    );

    if (newSupplement != null) {
      notifier.addSupplement(newSupplement);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newSupplement.name}이(가) 등록되었습니다!'),
            duration: const Duration(milliseconds: 1500),
            behavior: SnackBarBehavior.floating,
            dismissDirection: DismissDirection.horizontal,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '영양제 이름, 브랜드, 성분 검색',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(fontSize: 16),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : const Text(
                '내 영양제 캐비닛',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // 현재 정렬 기준 칩 (검색 중 숨김)
          if (!_isSearching)
            GestureDetector(
              onTap: _showSortSheet,
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_sortOption.icon, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      _sortOption.label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.black87,
            ),
            onPressed: _toggleSearch,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryCard(),
          Expanded(
            child: Builder(
              builder: (context) {
                final supplements = SupplementProvider.of(context).supplements;
                final sorted = _sorted(supplements);

                if (sorted.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty
                              ? Icons.search_off_rounded
                              : Icons.inventory_2_outlined,
                          size: 56,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? "'$_searchQuery' 검색 결과가 없습니다"
                              : '등록된 영양제가 없습니다',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _searchQuery.isNotEmpty
                              ? '다른 키워드로 검색해보세요'
                              : '아래 버튼으로 영양제를 추가해보세요',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final supp = sorted[index];
                    return Dismissible(
                      key: ValueKey(supp.name),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text(
                              '영양제 삭제',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            content: Text(
                              '${supp.name}을(를) 삭제하시겠습니까?\n복용 기록도 함께 삭제됩니다.',
                              style: const TextStyle(height: 1.5),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text(
                                  '취소',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.danger,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('삭제'),
                              ),
                            ],
                          ),
                        );
                        return confirmed == true;
                      },
                      onDismissed: (_) {
                        SupplementProvider.of(
                          context,
                        ).removeSupplement(supp.name);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${supp.name}이(가) 삭제되었습니다.'),
                            duration: const Duration(milliseconds: 1500),
                            behavior: SnackBarBehavior.floating,
                            dismissDirection: DismissDirection.horizontal,
                          ),
                        );
                      },
                      background: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                            SizedBox(height: 4),
                            Text(
                              '삭제',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      child: SupplementCard(item: supp),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateAndAddSupplement,
        label: const Text('영양제 추가'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '현재 복용 중',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            '${SupplementProvider.of(context).supplements.length}개의 영양제',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
