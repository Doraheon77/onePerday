import { Controller, Get, Post, Body } from '@nestjs/common';
import { AppService } from './app.service';
import { PrismaService } from './prisma/prisma.service';
import { SupplementSearchService } from './supplement-search.service';
import type { LlmExtracted } from './supplement-search.service';

@Controller()
export class AppController {
  constructor(
    private readonly appService: AppService,
    private readonly prisma: PrismaService,
    private readonly searchService: SupplementSearchService,
  ) { }

  @Get()
  getHello(): string {
    return this.appService.getHello();
  }

  @Get('supplements')
  async getSupplements() {

    // 기존 코드
    // const data = await this.prisma.supplements.findMany({ take: 3 });

    // 1. price가 존재하는 것만 가져오도록 변경
    const data = await this.prisma.supplements.findMany({
      take: 3,
      where: {
        price: {
          not: null,
        }
      },
    });

    // BigInt 처리 (JSON 변환)
    return JSON.parse(
      JSON.stringify(data, (key, value) =>
        typeof value === 'bigint' ? value.toString() : value,
      ),
    );
  }

  @Post('supplements/search') // 추가
  async searchSupplement(@Body() body: LlmExtracted) {
    const result = await this.searchService.search(body);

    // BigInt 처리
    return JSON.parse(
      JSON.stringify(result, (key, value) =>
        typeof value === 'bigint' ? value.toString() : value,
      ),
    );
  }
}
