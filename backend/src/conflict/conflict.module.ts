import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { ConfigModule } from '@nestjs/config';
import { ConflictService } from './conflict.service';

@Module({
  imports: [
    HttpModule,
    ConfigModule,
  ],
  providers: [ConflictService],
  exports: [ConflictService],
})
export class ConflictModule { }
