import { PrismaClient } from '@prisma/client';

async function main() {
  const prisma = new PrismaClient();
  try {
    const lastReview = await prisma.review.findFirst({
      orderBy: { review_id: 'desc' },
    });
    const newReviewId = lastReview ? lastReview.review_id + BigInt(1) : BigInt(1);
    console.log('Calculated newReviewId:', newReviewId.toString());

    const newReview = await prisma.review.create({
      data: {
        review_id: newReviewId,
        supplements_id: BigInt(1),
        user_id: '65e03eda-36a2-4dff-9d8e-06e40614a941',
        score: BigInt(5),
        content: '수동 ID를 적용한 테스트 리뷰 내용입니다.',
      },
    });
    console.log('Success to create review:', newReview);
  } catch (err) {
    console.error('Error creating review via Prisma:', err);
  } finally {
    await prisma.$disconnect();
  }
}

main();
