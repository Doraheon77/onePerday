import { IsInt, IsOptional, IsString, IsUUID } from 'class-validator';
import { Type } from 'class-transformer';

export class CompleteIntakeDto {
  @IsUUID()
  userUuid!: string;

  @Type(() => Number)
  @IsInt()
  inventoryId!: number;

  @Type(() => Number)
  @IsInt()
  doseIndex!: number;

  @IsString()
  date!: string;

  @IsOptional()
  @IsString()
  supplementTime?: string;
}
