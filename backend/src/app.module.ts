import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PillModule } from './pill/pill.module';
import { ConfigModule } from '@nestjs/config';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PillModule
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule { }
