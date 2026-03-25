import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { IntakeModule } from './intake/intake.module';
@Module({
  imports: [IntakeModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
