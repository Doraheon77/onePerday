import 'package:flutter/material.dart';
import 'package:simcap/core/constant/app_constants.dart';
import 'package:simcap/features/store/presentation/review_screen.dart';
import 'package:simcap/services/review_api_service.dart';
import 'package:simcap/services/auth_service.dart';

// ── 내가 쓴 리뷰 관리 화면 ────────────────────────────────────────────────
class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  List<ProductReview> _myReviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyReviews();
  }

  Future<void> _loadMyReviews() async {
    final user = AuthService().currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final reviews = await ReviewApiService().fetchUserReviews(user.id);
      if (mounted) {
        setState(() {
          _myReviews = reviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('내 리뷰 로드 실패: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _deleteReview(String reviewId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '리뷰 삭제',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('이 리뷰를 삭제하시겠습니까?\n삭제된 리뷰는 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _myReviews.removeWhere((r) => r.id == reviewId));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('리뷰가 삭제되었습니다.'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
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
  }

  void _editReview(ProductReview review) {
    double rating = review.rating;
    final controller = TextEditingController(text: review.content);

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
                '리뷰 수정',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                review.productName,
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
                  hintText: '리뷰 내용을 수정해주세요.',
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
                    // TODO: 백엔드 수정 API 호출
                    final idx = _myReviews.indexWhere((r) => r.id == review.id);
                    if (idx != -1) {
                      setState(() {
                        _myReviews[idx] = ProductReview(
                          id: review.id,
                          productId: review.productId,
                          productName: review.productName,
                          userName: review.userName,
                          rating: rating,
                          content: controller.text,
                          createdAt: review.createdAt,
                          isMine: true,
                        );
                      });
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('리뷰가 수정되었습니다.'),
                        backgroundColor: AppColors.primary,
                        duration: const Duration(seconds: 2),
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
                    '수정 완료',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          '내가 쓴 리뷰',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myReviews.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _myReviews.length,
                  itemBuilder: (context, index) =>
                      _buildReviewCard(_myReviews[index]),
                ),
    );
  }

  Widget _buildReviewCard(ProductReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // 상품명 + 별점
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildStars(review.rating),
                          const SizedBox(width: 6),
                          Text(
                            review.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  '${review.createdAt.year}.${review.createdAt.month.toString().padLeft(2, '0')}.${review.createdAt.day.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
          // 리뷰 내용
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Text(
              review.content,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // 수정/삭제 버튼
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _editReview(review),
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: const Text(
                    '수정',
                    style: TextStyle(color: AppColors.primary, fontSize: 13),
                  ),
                ),
              ),
              Container(width: 1, height: 20, color: AppColors.border),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _deleteReview(review.id),
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: AppColors.danger,
                  ),
                  label: const Text(
                    '삭제',
                    style: TextStyle(color: AppColors.danger, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            '아직 작성한 리뷰가 없습니다',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[400],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '구매한 상품에 리뷰를 남겨보세요',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildStars(double rating, {double size = 14}) {
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
