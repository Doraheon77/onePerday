import {
  BadRequestException,
  Controller,
  Post,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { LabelRecognitionService } from './label-recognition.service';

@Controller('label-recognition')
export class LabelRecognitionController {
  constructor(
    private readonly labelRecognitionService: LabelRecognitionService,
  ) {}

  @Post('analyze')
  @UseInterceptors(
    FileInterceptor('image', {
      limits: { fileSize: 10 * 1024 * 1024 },
    }),
  )
  async analyze(@UploadedFile() file: any) {
    if (!file?.buffer) {
      throw new BadRequestException('image 파일이 필요합니다.');
    }

    const result = await this.labelRecognitionService.analyze(file);
    return JSON.parse(
      JSON.stringify(result, (_key, value) =>
        typeof value === 'bigint' ? value.toString() : value,
      ),
    );
  }
}
