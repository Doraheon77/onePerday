import { Injectable } from '@nestjs/common';
import { PrismaService } from './prisma/prisma.service';

export interface LlmExtracted {
  product_name: string;
  brand_name?: string;
}

export interface SearchResult {
  status: 'found' | 'confirm_needed' | 'not_found';
  confidence: number;
  data?: any;
}

export interface TopOneSearchResult {
  status: 'found' | 'not_found';
  confidence: number;
  data?: any;
}

@Injectable()
export class SupplementSearchService {
  constructor(private prisma: PrismaService) {}

  async search(llm: LlmExtracted): Promise<SearchResult> {

    // 1단계: product_name 완전 일치
    const exact = await this.prisma.supplementsTemp.findFirst({
      where: {
        product_name: { equals: llm.product_name, mode: 'insensitive' },
      },
    });
    if (exact) {
      return { status: 'found', confidence: 1.0, data: await this.attachIngredients(exact) };
    }

    // 2단계: product_name 부분 일치
    const partial = await this.prisma.supplementsTemp.findMany({
      where: {
        product_name: { contains: llm.product_name, mode: 'insensitive' },
      },
      take: 5,
    });
    if (partial.length === 1) {
      return { status: 'found', confidence: 0.85, data: await this.attachIngredients(partial[0]) };
    }
    if (partial.length > 1) {
      return { status: 'confirm_needed', confidence: 0.6, data: await this.attachIngredientsMany(partial) };
    }

    // 3단계: brand_name + product_name 첫 키워드 조합
    if (llm.brand_name) {
      const brandMatch = await this.prisma.supplementsTemp.findMany({
        where: {
          AND: [
            { brand_name: { contains: llm.brand_name, mode: 'insensitive' } },
            { product_name: { contains: llm.product_name.split(' ')[0], mode: 'insensitive' } },
          ],
        },
        take: 5,
      });
      if (brandMatch.length === 1) {
        return { status: 'found', confidence: 0.7, data: await this.attachIngredients(brandMatch[0]) };
      }
      if (brandMatch.length > 1) {
        return { status: 'confirm_needed', confidence: 0.5, data: await this.attachIngredientsMany(brandMatch) };
      }
    }

    return { status: 'not_found', confidence: 0 };
  }

  async searchTopOne(llm: LlmExtracted): Promise<TopOneSearchResult> {
    const productName = llm.product_name?.trim();
    const brandName = llm.brand_name?.trim();

    if (!productName) {
      return { status: 'not_found', confidence: 0 };
    }

    const exact = await this.prisma.supplementsTemp.findFirst({
      where: {
        product_name: { equals: productName, mode: 'insensitive' as const },
        ...(brandName
          ? {
              brand_name: {
                contains: brandName,
                mode: 'insensitive' as const,
              },
            }
          : {}),
      },
    });

    if (exact) {
      return { status: 'found', confidence: 1.0, data: await this.attachIngredients(exact) };
    }

    const candidates = await this.prisma.supplementsTemp.findMany({
      where: {
        OR: [
          {
            product_name: {
              contains: productName,
              mode: 'insensitive' as const,
            },
          },
          ...(brandName
            ? [
                {
                  brand_name: {
                    contains: brandName,
                    mode: 'insensitive' as const,
                  },
                },
              ]
            : []),
          ...this.extractKeywords(productName).map((keyword) => ({
            product_name: { contains: keyword, mode: 'insensitive' as const },
          })),
        ],
      },
      take: 10,
    });

    if (candidates.length === 0) {
      return { status: 'not_found', confidence: 0 };
    }

    const candidatesWithIngredients = await this.attachIngredientsMany(candidates);

    const ranked = candidatesWithIngredients
      .map((candidate) => ({
        candidate,
        score: this.scoreCandidate(candidate, productName, brandName),
      }))
      .sort((a, b) => b.score - a.score);

    const best = ranked[0];
    return {
      status: 'found',
      confidence: Math.min(0.95, Math.max(0.45, best.score)),
      data: best.candidate,
    };
  }

  async attachIngredients(product: any) {
    if (!product) return null;
    const ingredients = await this.prisma.supplementsIngredients.findMany({
      where: { product_name: product.product_name },
    });
    return {
      ...product,
      ingredients: ingredients,
    };
  }

  async attachIngredientsMany(products: any[]) {
    if (!products || products.length === 0) return [];
    const productNames = products.map(p => p.product_name).filter(Boolean) as string[];
    const ingredients = await this.prisma.supplementsIngredients.findMany({
      where: { product_name: { in: productNames } },
    });
    return products.map(product => ({
      ...product,
      ingredients: ingredients.filter(ing => ing.product_name === product.product_name),
    }));
  }

  private extractKeywords(text: string) {
    return Array.from(
      new Set(
        text
          .replace(/[^\p{L}\p{N}\s]/gu, ' ')
          .split(/\s+/)
          .map((keyword) => keyword.trim())
          .filter((keyword) => keyword.length >= 2),
      ),
    ).slice(0, 6);
  }

  private scoreCandidate(
    candidate: {
      product_name: string;
      brand_name: string | null;
      ingredients?: { ingredient_name: string | null }[];
    },
    productName: string,
    brandName?: string,
  ) {
    const target = productName.toLowerCase();
    const candidateName = candidate.product_name.toLowerCase();
    let score = 0;

    if (candidateName === target) score += 1;
    if (candidateName.includes(target)) score += 0.75;

    const keywords = this.extractKeywords(productName);
    const matchedKeywords = keywords.filter((keyword) =>
      candidateName.includes(keyword.toLowerCase()),
    );
    if (keywords.length > 0) {
      score += (matchedKeywords.length / keywords.length) * 0.45;
    }

    if (
      brandName &&
      candidate.brand_name?.toLowerCase().includes(brandName.toLowerCase())
    ) {
      score += 0.2;
    }

    const ingredientText =
      candidate.ingredients
        ?.map((ingredient) => ingredient.ingredient_name ?? '')
        .join(' ')
        .toLowerCase() ?? '';
    if (
      keywords.some((keyword) => ingredientText.includes(keyword.toLowerCase()))
    ) {
      score += 0.1;
    }

    return score;
  }
}
