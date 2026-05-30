import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateCabinetDto } from './dto/create-cabinet.dto';

@Injectable()
export class CabinetService {
  constructor(private readonly prisma: PrismaService) {}

  async create(dto: CreateCabinetDto) {
    if (dto.alarmTimes.length !== dto.dailyFrequency) {
      throw new BadRequestException(
        'alarmTimes length must match dailyFrequency',
      );
    }

    const supplement = await this.prisma.supplements.findUnique({
      where: {
        id: BigInt(dto.supplementId),
      },
    });

    if (!supplement) {
      throw new NotFoundException('Supplement not found');
    }

    return this.prisma.supplementInventory.create({
      data: {
        user_uuid: dto.userUuid,
        supplement_id: BigInt(dto.supplementId),
        daily_dose: dto.dailyDose,
        daily_frequency: dto.dailyFrequency,
        stock_count: dto.stockCount ?? 0,
        total_count: dto.totalCount ?? dto.stockCount ?? 0,
        alarm_times: dto.alarmTimes,
        status: 'active',
      },
      include: {
        supplements: true,
      },
    });
  }

  async findByUser(userUuid: string) {
    return this.prisma.supplementInventory.findMany({
      where: {
        user_uuid: userUuid,
        status: 'active',
      },
      include: {
        supplements: true,
      },
      orderBy: {
        created_at: 'desc',
      },
    });
  }

  async remove(id: string) {
    const inventoryId = BigInt(id);

    const item = await this.prisma.supplementInventory.findUnique({
      where: {
        id: inventoryId,
      },
    });

    if (!item) {
      throw new NotFoundException('Cabinet item not found');
    }

    return this.prisma.supplementInventory.update({
      where: {
        id: inventoryId,
      },
      data: {
        status: 'deleted',
      },
    });
  }
}
