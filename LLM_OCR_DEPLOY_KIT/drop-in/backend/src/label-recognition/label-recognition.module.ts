import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { AiModule } from '../ai/ai.module';
import { LabelRecognitionController } from './label-recognition.controller';
import { LabelRecognitionService } from './label-recognition.service';
import { SupplementSearchService } from '../supplement-search.service';

@Module({
  imports: [PrismaModule, AiModule],
  controllers: [LabelRecognitionController],
  providers: [LabelRecognitionService, SupplementSearchService],
})
export class LabelRecognitionModule {}
