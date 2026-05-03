import { ArrayNotEmpty, IsArray, IsIn, IsInt } from 'class-validator';
import { Type } from 'class-transformer';

export class CheckIntakeDto {
  @IsArray()
  @ArrayNotEmpty()
  @IsInt({ each: true })
  supplementIds: number[];

  @Type(() => Number)
  @IsInt()
  age: number;

  @IsIn(['male', 'female'])
  gender: 'male' | 'female';
}