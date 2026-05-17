import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  // 인메모리 검색어 카운팅 맵
  private searchKeywordCounts = new Map<string, number>();

  getHello(): string {
    return 'OnePerDay!';
  }

  // 1. 검색어 기록 등록
  recordSearch(keyword: string) {
    if (!keyword || keyword.trim() === '') return;
    const cleanKeyword = keyword.trim();
    
    // 낱글자 오염 방지: 공백을 제거한 검색어 길이가 2자 미만이면 기록하지 않음
    if (cleanKeyword.length < 2) return;
    
    const cleanLower = cleanKeyword.toLowerCase();
    
    // 단순 카운터 증가
    const currentCount = this.searchKeywordCounts.get(cleanLower) || 0;
    this.searchKeywordCounts.set(cleanLower, currentCount + 1);
  }

  // 2. 실시간 인기 검색어 상위 8개 추출
  getPopularSearches(): string[] {
    const sorted = Array.from(this.searchKeywordCounts.entries())
      .sort((a, b) => b[1] - a[1]) // 검색 횟수 내림차순 정렬
      .slice(0, 8)
      .map(entry => entry[0]);

    // 실시간 검색어가 부족한 초기를 위해 멋스러운 기본 추천 키워드들로 패딩
    const defaultSuggestions = [
      '비타민D 5000IU',
      '마그네슘 영양제',
      '다이어트 보조제',
      '밀크씨슬',
      '탈모 방지 비오틴',
      '임산부 엽산',
      '어린이 젤리 비타민',
      '남성용 활력제'
    ];

    const result = [...sorted];
    for (const def of defaultSuggestions) {
      if (result.length >= 8) break;
      // 대소문자 무관하게 중복 체크
      if (!result.map(r => r.toLowerCase()).includes(def.toLowerCase())) {
        result.push(def);
      }
    }
    return result;
  }
}
