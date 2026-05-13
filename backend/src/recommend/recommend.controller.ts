import { Controller, Get, Query, BadRequestException } from '@nestjs/common';
import { RecommendService } from './recommend.service';

@Controller('recommend')
export class RecommendController {
  constructor(private readonly recommendService: RecommendService) { }

  @Get()
  async getRecommendations(@Query('userId') userId: string) {
    if (!userId) {
      throw new BadRequestException('userId 쿼리 파라미터가 필요합니다.');
    }
    return this.recommendService.getPersonalizedRecommendations(userId);
  }
}
