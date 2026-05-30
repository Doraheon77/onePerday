import {
  IsArray,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Min,
} from 'class-validator';
import { Type } from 'class-transformer';

export class CreateCabinetDto {
  @IsUUID()
  userUuid!: string;

  @Type(() => Number)
  @IsInt()
  supplementId!: number;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  dailyDose!: number;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  dailyFrequency!: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  stockCount?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  totalCount?: number;

  @IsArray()
  @IsString({ each: true })
  alarmTimes!: string[];
}
