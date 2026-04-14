import 'package:flutter/material.dart';
import 'package:simcap/core/constant/app_constants.dart';
import 'package:simcap/features/store/presentation/supplement_detail_screen.dart';

// ── 리뷰 모델 ──────────────────────────────────────────────────────────────
class ProductReview {
  final String id;
  final String productId;
  final String productName;
  final String userName;
  final double rating;
  final String content;
  final DateTime createdAt;
  final bool isMine;

  const ProductReview({
    required this.id,
    required this.productId,
    required this.productName,
    required this.userName,
    required this.rating,
    required this.content,
    required this.createdAt,
    this.isMine = false,
  });
}

// ── 더미 리뷰 데이터 ───────────────────────────────────────────────────────
// TODO: 백엔드 연동 후 API로 교체
List<ProductReview> getDummyReviews(String productId) => [
  ProductReview(
    id: 'r001',
    productId: productId,
    productName: '',
    userName: '건강하자**',
    rating: 5.0,
    content: '꾸준히 먹고 있는데 확실히 피로감이 줄었어요. 캡슐도 작아서 삼키기 편하고 냄새도 없어서 좋습니다.',
    createdAt: DateTime(2025, 3, 15),
  ),
  ProductReview(
    id: 'r002',
    productId: productId,
    productName: '',
    userName: '영양지킴**',
    rating: 4.0,
    content: '가격 대비 품질은 괜찮은 것 같아요. 혈액검사 결과가 좋아졌는지는 아직 모르겠지만 일단 꾸준히 복용 중입니다.',
    createdAt: DateTime(2025, 2, 28),
  ),
  ProductReview(
    id: 'r003',
    productId: productId,
    productName: '',
    userName: '비타민마**',
    rating: 4.5,
    content: '배송도 빠르고 포장도 꼼꼼했어요. 성분 함량이 높아서 만족스럽습니다. 재구매 의사 있어요.',
    createdAt: DateTime(2025, 2, 10),
  ),
  ProductReview(
    id: 'r004',
    productId: productId,
    productName: '',
    userName: '하루비타**',
    rating: 3.0,
    content: '효과는 잘 모르겠지만 나쁘지는 않아요. 가격이 좀 더 합리적이면 좋겠습니다.',
    createdAt: DateTime(2025, 1, 22),
  ),
  ProductReview(
    id: 'r005',
    productId: productId,
    productName: '',
    userName: '건강이최**',
    rating: 5.0,
    content:
        '부모님 선물로 드렸는데 좋아하세요. 캡슐이 부드럽게 넘어가고 특유의 냄새도 없어서 호불호 없이 드실 수 있을 것 같아요.',
    createdAt: DateTime(2025, 1, 5),
  ),
];

// ── 상품 리뷰 전체 보기 화면 ───────────────────────────────────────────────
class ReviewScreen extends StatefulWidget {
  final StoreProduct product;

  const ReviewScreen({super.key, required this.product});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  String _sortBy = '최신순'; // 최신순 / 별점높은순 / 별점낮은순

  List<ProductReview> get _sortedReviews {
    final reviews = getDummyReviews(widget.product.id);
    switch (_sortBy) {
      case '별점높은순':
        return reviews..sort((a, b) => b.rating.compareTo(a.rating));
      case '별점낮은순':
        return reviews..sort((a, b) => a.rating.compareTo(b.rating));
      default:
        return reviews..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  double get _avgRating {
    final reviews = getDummyReviews(widget.product.id);
    if (reviews.isEmpty) return 0;
    return reviews.map((r) => r.rating).reduce((a, b) => a + b) /
        reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    final reviews = _sortedReviews;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          '리뷰',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          // ── 평점 요약 카드 ───────────────────────────────────────
          _buildRatingSummary(reviews),

          // ── 정렬 옵션 ───────────────────────────────────────────
          _buildSortBar(),

          // ── 리뷰 목록 ───────────────────────────────────────────
          if (reviews.isEmpty)
            _buildEmptyReview()
          else
            ...reviews.map(_buildReviewCard),

          const SizedBox(height: 32),
        ],
      ),
      // ── 리뷰 작성 버튼 ─────────────────────────────────────────
      bottomNavigationBar: _buildWriteButton(),
    );
  }

  Widget _buildRatingSummary(List<ProductReview> reviews) {
    final avg = _avgRating;
    // 별점별 분포
    final dist = List.generate(5, (i) {
      final star = 5 - i;
      return reviews.where((r) => r.rating.round() == star).length;
    });

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.product.name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 평균 별점
              Column(
                children: [
                  Text(
                    avg.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  _buildStars(avg, size: 18),
                  const SizedBox(height: 4),
                  Text(
                    '${reviews.length}개 리뷰',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              // 별점 분포
              Expanded(
                child: Column(
                  children: List.generate(5, (i) {
                    final star = 5 - i;
                    final count = dist[i];
                    final ratio = reviews.isEmpty
                        ? 0.0
                        : count / reviews.length;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text(
                            '$star',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.star_rounded,
                            size: 12,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 6,
                                backgroundColor: Colors.grey[100],
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 20,
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortBar() {
    const options = ['최신순', '별점높은순', '별점낮은순'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: options.map((opt) {
          final selected = _sortBy == opt;
          return GestureDetector(
            onTap: () => setState(() => _sortBy = opt),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? AppColors.primary : Colors.grey.shade200,
                ),
              ),
              child: Text(
                opt,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : Colors.grey[600],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReviewCard(ProductReview review) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  review.userName.isNotEmpty ? review.userName[0] : 'U',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _buildStars(review.rating, size: 13),
                  ],
                ),
              ),
              Text(
                '${review.createdAt.year}.${review.createdAt.month.toString().padLeft(2, '0')}.${review.createdAt.day.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.content,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyReview() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            '아직 리뷰가 없습니다',
            style: TextStyle(fontSize: 15, color: Colors.grey[400]),
          ),
          const SizedBox(height: 4),
          Text(
            '첫 번째 리뷰를 작성해보세요',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildWriteButton() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showWriteDialog(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text(
            '리뷰 작성하기',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  void _showWriteDialog() {
    double rating = 5.0;
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '리뷰 작성',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                widget.product.name,
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              // 별점 선택
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setModal(() => rating = i + 1.0),
                    child: Icon(
                      i < rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: AppColors.warning,
                      size: 36,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 4,
                maxLength: 300,
                decoration: InputDecoration(
                  hintText: '이 상품에 대한 솔직한 리뷰를 남겨주세요.',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  filled: true,
                  fillColor: AppColors.scaffoldBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('리뷰가 등록되었습니다.'),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '등록하기',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStars(double rating, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < rating.floor()) {
          return Icon(Icons.star_rounded, size: size, color: AppColors.warning);
        } else if (i < rating) {
          return Icon(
            Icons.star_half_rounded,
            size: size,
            color: AppColors.warning,
          );
        }
        return Icon(
          Icons.star_border_rounded,
          size: size,
          color: Colors.grey[300],
        );
      }),
    );
  }
}
