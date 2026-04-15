import { PartialType } from '@nestjs/mapped-types';
import { CreatePillDto } from './create-pill.dto';

export class UpdatePillDto extends PartialType(CreatePillDto) {}
