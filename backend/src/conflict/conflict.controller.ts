import { Controller, Post, Body } from '@nestjs/common';
import { ConflictService } from './conflict.service';
import { Conflict } from './entities/conflict.entity';

@Controller('conflict')
export class ConflictController {
  constructor(private readonly conflictService: ConflictService) { }

  @Post('check')
  async checkConflictTest(@Body() reqBody: { data: Conflict[] }) {
    // Postman에서 { "data": [ ... ] } 형태로 받는다고 가정합니다.
    return this.conflictService.checkConflicts(reqBody.data);
  }

  @Post('check-safety')
  async checkConflictSafety(@Body() reqBody: { 
    supplementIds: number[];
    cabinetSupplements?: { name: string; ingredients: string[] }[];
    userHealth?: string[];
    userAllergies?: string[];
  }) {
    return this.conflictService.checkConflictsByIds(
      reqBody.supplementIds,
      reqBody.cabinetSupplements || [],
      reqBody.userHealth || [],
      reqBody.userAllergies || [],
    );
  }
}
