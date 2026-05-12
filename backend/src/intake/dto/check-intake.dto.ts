import {
  ArrayNotEmpty,
  IsArray,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

class CartItemDto {
  @Type(() => Number)
  @IsInt()
  productId!: number;

  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsString()
  brand?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  count?: number;
}

export class CheckIntakeDto {
  @Type(() => Number)
  @IsInt()
  age!: number;

  @IsIn(['male', 'female'])
  gender!: 'male' | 'female';

  @IsArray()
  @ArrayNotEmpty()
  @ValidateNested({ each: true })
  @Type(() => CartItemDto)
  cartItems!: CartItemDto[];
}
