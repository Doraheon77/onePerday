import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth/auth.module';
import { IntakeModule } from './intake/intake.module';
import { PrismaService } from './prisma.service';
import { ConflictModule } from './conflict/conflict.module';
import { SupplementSearchService } from './supplement-search.service';

@Module({
  imports: [AuthModule, IntakeModule, ConflictModule],
  controllers: [AppController],
  providers: [AppService, PrismaService, SupplementSearchService],
})
export class AppModule { }
