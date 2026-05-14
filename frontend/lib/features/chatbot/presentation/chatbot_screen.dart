import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:simcap/core/constant/app_constants.dart';
import 'package:simcap/features/cabinet/domain/dataModels/supplement_model.dart';
import 'package:simcap/providers/supplement_provider.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  // 추천 질문 목록
  static const _suggestions = [
    '비타민D 언제 먹는 게 좋아요?',
    '오메가3와 같이 먹으면 안 되는 영양제가 있나요?',
    '영양제 공복에 먹어도 되나요?',
    '철분제 부작용이 있을 수 있나요?',
    '종합비타민과 개별 영양제 차이가 뭔가요?',
  ];

  // 질문 키워드 기반 더미 응답
  static String _getDummyResponse(String text, int supplementCount) {
    final t = text.toLowerCase();
    if (t.contains('비타민d') || t.contains('비타민 d')) {
      return '비타민D는 지용성 비타민이라 식후 복용이 가장 좋습니다. 특히 지방이 포함된 식사 후에 흡수율이 높아져요. 하루 권장량은 성인 기준 600~800IU이지만 결핍이 있다면 의사 상담 후 고용량을 복용하기도 합니다.';
    } else if (t.contains('오메가') || t.contains('omega')) {
      return '오메가3는 혈액 희석 효과가 있어 항응고제(아스피린 등)와 함께 복용 시 출혈 위험이 높아질 수 있습니다. 또한 비타민E와 함께 복용하면 산화 방지에 도움이 돼요. 식후 복용을 권장합니다.';
    } else if (t.contains('공복')) {
      return '공복 복용이 좋은 영양제: 철분(흡수율↑), 프로바이오틱스\n식후 복용이 좋은 영양제: 지용성 비타민(A·D·E·K), 오메가3, 마그네슘\n\n대부분의 영양제는 위장 자극을 줄이기 위해 식후 복용을 권장합니다.';
    } else if (t.contains('철분')) {
      return '철분제의 흔한 부작용으로는 변비, 복통, 검은 변이 있습니다. 공복 복용 시 흡수율이 높지만 위장 자극이 심할 수 있어요. 비타민C와 함께 복용하면 흡수율이 올라가고, 칼슘·카페인은 흡수를 방해하니 2시간 간격을 두세요.';
    } else if (t.contains('종합비타민') || t.contains('멀티')) {
      return '종합비타민은 여러 영양소를 한 번에 섭취할 수 있어 편리하지만, 특정 영양소가 결핍된 경우 개별 보충제가 더 효과적입니다. 예를 들어 비타민D 결핍이 심하다면 종합비타민의 함량만으로는 부족할 수 있어요.';
    } else if (supplementCount > 0) {
      return '현재 등록하신 ${supplementCount}가지 영양제를 참고해 답변드리겠습니다. 구체적으로 어떤 점이 궁금하신가요? 복용 시간, 상호작용, 부작용 등에 대해 도움드릴 수 있어요.';
    } else {
      return '좋은 질문이에요! 영양제 복용에 관한 더 정확한 답변을 위해 캐비닛에 복용 중인 영양제를 등록해 주시면 맞춤 상담이 가능합니다. 다른 궁금한 점이 있으시면 언제든지 물어보세요.';
    }
  }

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // isLoading: true이면 말풍선 로딩 애니메이션 표시
  bool _isLoading = false;

  final List<Map<String, dynamic>> _messages = [
    {
      'role': 'bot',
      'message': '안녕하세요! OnePerDay AI 영양사입니다. \n어떤 영양제나 건강 고민에 대해 도와드릴까요?',
      'time': DateTime.now(),
    },
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 현재 복용 중인 영양제 목록을 시스템 프롬프트용 텍스트로 변환
  String _buildSupplementContext(List<Supplement> supplements) {
    if (supplements.isEmpty) return '현재 등록된 영양제 없음';
    return supplements
        .map((s) {
          final nutrients = s.nutrients.map((n) => n.name).join(', ');
          return '- ${s.name} (${s.brand}): 잔여 ${s.remaining}정, '
              '주요 성분: $nutrients';
        })
        .join('\n');
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    // 영양제 컨텍스트 수집
    final supplements = SupplementProvider.of(context).supplements;
    final supplementCtx = _buildSupplementContext(supplements);

    setState(() {
      _messages.add({'role': 'user', 'message': text, 'time': DateTime.now()});
      _isLoading = true;
      _controller.clear();
    });
    _scrollToBottom();

    // TODO: 실제 AI API 호출로 교체 (Gemini 등)
    // 아래 supplementCtx를 시스템 프롬프트에 포함:
    // final systemPrompt = '''
    // 당신은 OnePerDay 앱의 AI 영양사입니다.
    // 사용자가 현재 복용 중인 영양제 목록:
    // $supplementCtx
    // 이 정보를 바탕으로 개인화된 영양 상담을 제공하세요.
    // ''';
    debugPrint('[Chatbot] 시스템 프롬프트에 포함될 영양제 컨텍스트:\n$supplementCtx');

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _messages.add({
          'role': 'bot',
          'message': supplements.isEmpty
              ? '현재 등록된 영양제가 없네요. 캐비닛에 영양제를 추가하면 맞춤 상담이 가능합니다!'
              : _getDummyResponse(text, supplements.length),
          'time': DateTime.now(),
        });
      });
      _scrollToBottom();
    });
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$period $displayHour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'AI 영양사 챗봇',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        actions: [
          // 현재 등록된 영양제 수 표시
          Builder(
            builder: (ctx) {
              final count = SupplementProvider.of(ctx).supplements.length;
              if (count == 0) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '영양제 $count개 참고 중',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.length <= 1 && !_isLoading
                ? Column(children: [Expanded(child: _buildEmptyState())])
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    // 로딩 중이면 아이템 1개 추가 (로딩 말풍선)
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      // 마지막 아이템이고 로딩 중이면 로딩 버블 표시
                      if (_isLoading && index == _messages.length) {
                        return _buildLoadingBubble();
                      }
                      final chat = _messages[index];
                      final isBot = chat['role'] == 'bot';
                      return _buildMessageBubble(
                        isBot: isBot,
                        message: chat['message'] as String,
                        time: chat['time'] as DateTime,
                      );
                    },
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: AppColors.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '무엇이든 물어보세요!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '영양제 복용법, 상호작용, 부작용 등\n궁금한 점을 질문해 보세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '추천 질문',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions
                .map(
                  (q) => GestureDetector(
                    onTap: () {
                      _controller.text = q;
                      _sendMessage();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 11,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            q,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required bool isBot,
    required String message,
    required DateTime time,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isBot
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isBot) ...[
            const CircleAvatar(
              backgroundColor: Color(0xFFE8F5E9),
              child: Icon(Icons.smart_toy, color: Color(0xFF4CAF50), size: 20),
            ),
            const SizedBox(width: 8),
          ],
          // 유저 말풍선 오른쪽에 시간 표시
          if (!isBot)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                _formatTime(time),
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isBot ? Colors.white : const Color(0xFF4CAF50),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isBot ? 4 : 16),
                  bottomRight: Radius.circular(isBot ? 16 : 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: isBot ? Colors.black87 : Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
          // 봇 말풍선 오른쪽에 시간 표시
          if (isBot)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(
                _formatTime(time),
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  /// 봇 응답 대기 중 점 3개 애니메이션 말풍선
  Widget _buildLoadingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFE8F5E9),
            child: Icon(Icons.smart_toy, color: Color(0xFF4CAF50), size: 20),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const _TypingIndicator(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_isLoading,
              decoration: InputDecoration(
                hintText: _isLoading ? '응답을 기다리는 중...' : '영양제에 대해 물어보세요...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _isLoading ? Colors.grey[300] : const Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send_rounded,
                color: _isLoading ? Colors.grey[500] : Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 점 3개가 순서대로 커졌다 작아지는 타이핑 애니메이션 위젯
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_controller.value - i * 0.2).clamp(0.0, 1.0);
            final scale = 1.0 + 0.5 * (1 - (2 * phase - 1).abs());
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
