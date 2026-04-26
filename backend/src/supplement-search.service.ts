import { Injectable } from '@nestjs/common';
import { PrismaService } from './prisma.service';

export interface LlmExtracted {
  product_name: string;
  brand_name?: string;
}

export interface SearchResult {
  status: 'found' | 'confirm_needed' | 'not_found';
  confidence: number;
  data?: any;
}

@Injectable()
export class SupplementSearchService {
  constructor(private prisma: PrismaService) {}

  async search(llm: LlmExtracted): Promise<SearchResult> {

    // 1단계: product_name 완전 일치
    const exact = await this.prisma.supplements.findFirst({
      where: {
        product_name: { equals: llm.product_name, mode: 'insensitive' },
      },
    });
    if (exact) {
      return { status: 'found', confidence: 1.0, data: exact };
    }

    // 2단계: product_name 부분 일치
    const partial = await this.prisma.supplements.findMany({
      where: {
        product_name: { contains: llm.product_name, mode: 'insensitive' },
      },
      take: 5,
    });
    if (partial.length === 1) {
      return { status: 'found', confidence: 0.85, data: partial[0] };
    }
    if (partial.length > 1) {
      return { status: 'confirm_needed', confidence: 0.6, data: partial };
    }

    // 3단계: brand_name + product_name 첫 키워드 조합
    if (llm.brand_name) {
      const brandMatch = await this.prisma.supplements.findMany({
        where: {
          AND: [
            { brand_name: { contains: llm.brand_name, mode: 'insensitive' } },
            { product_name: { contains: llm.product_name.split(' ')[0], mode: 'insensitive' } },
          ],
        },
        take: 5,
      });
      if (brandMatch.length === 1) {
        return { status: 'found', confidence: 0.7, data: brandMatch[0] };
      }
      if (brandMatch.length > 1) {
        return { status: 'confirm_needed', confidence: 0.5, data: brandMatch };
      }
    }

    return { status: 'not_found', confidence: 0 };
  }
}