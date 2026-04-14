import { Injectable } from '@nestjs/common';
import { CheckIntakeDto } from './dto/check-intake.dto';

export interface IntakeResult {
  nutrientName: string;
  currentTotal: number;
  upperLimit: number;
  isExceeded: boolean;
  unit: string;
}

@Injectable()
export class IntakeService {
  checkOverdose(dto: CheckIntakeDto): IntakeResult[] {
    const { supplementIds, age, gender } = dto;

    if (!supplementIds || supplementIds.length === 0) {
      return [];
    }

    const selectedNutrients = this.getNutrientsBySupplements(supplementIds);

    const aggregated = selectedNutrients.reduce<Record<string, number>>(
      (acc, curr) => {
        acc[curr.name] = (acc[curr.name] || 0) + curr.amount;
        return acc;
      },
      {},
    );

    const results: IntakeResult[] = Object.entries(aggregated).map(
      ([name, totalAmount]) => {
        const limit = this.getUpperLimit(name, age, gender);

        return {
          nutrientName: name,
          currentTotal: totalAmount,
          upperLimit: limit,
          isExceeded: totalAmount > limit,
          unit: 'mg',
        };
      },
    );

    return results;
  }

  private getNutrientsBySupplements(ids: number[]) {
    void ids;

    return [
      { name: '비타민C', amount: 1000 },
      { name: '비타민C', amount: 1500 },
      { name: '아연', amount: 20 },
    ];
  }

  private getUpperLimit(name: string, age: number, gender: 'male' | 'female') {
    void age;
    void gender;

    if (name === '비타민C') return 2000;
    if (name === '아연') return 40;

    return 1000;
  }
}
