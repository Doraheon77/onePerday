import { Test, TestingModule } from '@nestjs/testing';
import { PillController } from './pill.controller';
import { PillService } from './pill.service';

describe('PillController', () => {
  let controller: PillController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [PillController],
      providers: [PillService],
    }).compile();

    controller = module.get<PillController>(PillController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
