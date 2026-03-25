import { Controller, Post, Body } from '@nestjs/common';
import { IntakeService } from './intake.service';
import { CheckIntakeDto } from './dto/check-intake.dto';

@Controller('intake')
export class IntakeController {
  constructor(private readonly intakeService: IntakeService) {}

  @Post('check-safety')
  checkSafety(@Body() dto: CheckIntakeDto) {
    const analysis = this.intakeService.checkOverdose(dto);

    const hasWarning = analysis.some((item) => item.isExceeded);

    return {
      success: true,
      hasWarning,
      results: analysis,
    };
  }
}
