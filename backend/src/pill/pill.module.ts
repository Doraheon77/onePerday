import { Module } from '@nestjs/common';
import { PillService } from './pill.service';
import { PillController } from './pill.controller';
import { HttpModule } from '@nestjs/axios';

@Module({
  imports: [HttpModule],
  controllers: [PillController],
  providers: [PillService],
})
export class PillModule {}
