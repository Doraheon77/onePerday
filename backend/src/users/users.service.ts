import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async findById(userId: string) {
    return this.prisma.users.findUnique({
      where: { id: userId },
    });
  }
}