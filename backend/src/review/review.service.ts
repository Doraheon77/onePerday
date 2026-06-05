import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateReviewDto } from './dto/create-review.dto';

@Injectable()
export class ReviewService {
  constructor(private readonly prisma: PrismaService) {}

  async createReview(dto: CreateReviewDto) {
    // 1. 상품 존재 여부 검증
    const product = await this.prisma.supplementsTemp.findUnique({
      where: { id: BigInt(dto.productId) },
    });
    if (!product) {
      throw new NotFoundException('해당 영양제 상품을 찾을 수 없습니다.');
    }

    // 2. 사용자 존재 여부 검증
    const user = await this.prisma.usersInfo.findUnique({
      where: { id: dto.userId },
    });
    if (!user) {
      throw new NotFoundException('해당 사용자를 찾을 수 없습니다.');
    }

    // 3. 수동으로 새로운 review_id 번호 계산 (DB 시퀀스 부재 우회)
    const lastReview = await this.prisma.review.findFirst({
      orderBy: { review_id: 'desc' },
    });
    const newReviewId = lastReview ? lastReview.review_id + BigInt(1) : BigInt(1);

    // 4. 리뷰 데이터 삽입
    const newReview = await this.prisma.review.create({
      data: {
        review_id: newReviewId,
        supplements_id: BigInt(dto.productId),
        user_id: dto.userId,
        score: BigInt(dto.score),
        content: dto.content,
      },
      include: {
        user: {
          select: {
            name: true,
          },
        },
      },
    });

    return this.serializeReview(newReview);
  }

  async getReviewsByProduct(productId: string) {
    const reviews = await this.prisma.review.findMany({
      where: {
        supplements_id: BigInt(productId),
      },
      include: {
        user: {
          select: {
            name: true,
          },
        },
      },
      orderBy: {
        write_time: 'desc',
      },
    });

    return reviews.map((r) => this.serializeReview(r));
  }

  /**
   * BigInt 값들을 JSON 직렬화에 안전하도록 타입 변환
   */
  private serializeReview(review: any) {
    if (!review) return null;
    return {
      ...review,
      review_id: review.review_id.toString(),
      supplements_id: review.supplements_id?.toString() || null,
      score: review.score ? Number(review.score) : 0,
      userName: review.user?.name || '익명 사용자',
    };
  }

  async getReviewsByUser(userId: string) {
    const reviews = await this.prisma.review.findMany({
      where: {
        user_id: userId,
      },
      include: {
        supplement: {
          select: {
            product_name: true,
            brand_name: true,
          },
        },
      },
      orderBy: {
        write_time: 'desc',
      },
    });

    return reviews.map((r) => {
      const serialized = this.serializeReview(r);
      return {
        ...serialized,
        productName: r.supplement?.product_name || '알 수 없는 영양제',
        brandName: r.supplement?.brand_name || '',
      };
    });
  }
}
