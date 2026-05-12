import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { ConfigModule } from '@nestjs/config';
import { ConflictService } from './conflict.service';
import { ConflictController } from './conflict.controller';

@Module({
  imports: [
    HttpModule,
    ConfigModule,
  ],
  controllers: [ConflictController],
  providers: [ConflictService],
  exports: [ConflictService],
})
export class ConflictModule { }
