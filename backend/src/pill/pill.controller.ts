import { Controller, Get, Post, Body, Patch, Param, Delete } from '@nestjs/common';
import { PillService } from './pill.service';
import { CreatePillDto } from './dto/create-pill.dto';
import { UpdatePillDto } from './dto/update-pill.dto';
import { Pill } from './entities/pill.entity';

@Controller('pill')
export class PillController {
  constructor(private readonly pillService: PillService) { }

  @Post('check-conflicts')
  check(@Body() pills: Pill[]) {
    return this.pillService.checkConflicts(pills);
  }

  @Post()
  create(@Body() createPillDto: CreatePillDto) {
    return this.pillService.create(createPillDto);
  }


  @Get()
  findAll() {
    return this.pillService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.pillService.findOne(+id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() updatePillDto: UpdatePillDto) {
    return this.pillService.update(+id, updatePillDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.pillService.remove(+id);
  }
}

