import { Controller, Get, Post, Body, Param } from '@nestjs/common';
import { ReviewService } from './review.service';
import { CreateReviewDto } from './dto/create-review.dto';

@Controller('review')
export class ReviewController {
  constructor(private readonly reviewService: ReviewService) {}

  @Post()
  async createReview(@Body() dto: CreateReviewDto) {
    return this.reviewService.createReview(dto);
  }

  @Get(':productId')
  async getReviewsByProduct(@Param('productId') productId: string) {
    return this.reviewService.getReviewsByProduct(productId);
  }

  @Get('user/:userId')
  async getReviewsByUser(@Param('userId') userId: string) {
    return this.reviewService.getReviewsByUser(userId);
  }
}
