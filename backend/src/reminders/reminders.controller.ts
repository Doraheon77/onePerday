import { Controller, Get, Param } from '@nestjs/common';
import { RemindersService } from './reminders.service';

type JsonValue =
  | string
  | number
  | boolean
  | null
  | JsonValue[]
  | { [key: string]: JsonValue };

function serializeBigInt(value: unknown): JsonValue {
  if (typeof value === 'bigint') return value.toString();
  if (value instanceof Date) return value.toISOString();
  if (Array.isArray(value)) return value.map((item) => serializeBigInt(item));

  if (value !== null && typeof value === 'object') {
    const result: { [key: string]: JsonValue } = {};

    for (const [key, nestedValue] of Object.entries(
      value as Record<string, unknown>,
    )) {
      result[key] = serializeBigInt(nestedValue);
    }

    return result;
  }

  if (
    typeof value === 'string' ||
    typeof value === 'number' ||
    typeof value === 'boolean' ||
    value === null
  ) {
    return value;
  }

  return null;
}

@Controller('reminders')
export class RemindersController {
  constructor(private readonly remindersService: RemindersService) {}

  @Get('today/:userUuid')
  async getTodayReminders(@Param('userUuid') userUuid: string) {
    const data = await this.remindersService.getTodayReminders(userUuid);

    return {
      success: true,
      data: serializeBigInt(data),
    };
  }
}
