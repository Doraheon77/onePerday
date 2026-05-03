import { Controller, Post, Body } from '@nestjs/common';
import { IntakeService } from './intake.service';
import { CheckIntakeDto } from './dto/check-intake.dto';

@Controller('intake')
export class IntakeController {
  constructor(private readonly intakeService: IntakeService) {}

  @Post('check-safety')
  async checkSafety(@Body() dto: CheckIntakeDto) {
    const analysis = await this.intakeService.checkOverdose(dto);

    const hasWarning = analysis.some((item) => item.isExceeded);

    return {
      success: true,
      hasWarning,
      results: analysis,
    };
  }
}
