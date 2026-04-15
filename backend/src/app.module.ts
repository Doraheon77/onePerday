import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth/auth.module';
import { IntakeModule } from './intake/intake.module';
import { PrismaService } from './prisma.service';

@Module({
  imports: [AuthModule, IntakeModule],
  controllers: [AppController],
  providers: [AppService, PrismaService],
})
export class AppModule {}
