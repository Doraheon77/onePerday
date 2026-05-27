import { Injectable, Logger } from '@nestjs/common';

interface GenerateOptions {
  temperature?: number;
  responseMimeType?: 'application/json' | 'text/plain';
}

@Injectable()
export class GeminiService {
  private readonly logger = new Logger(GeminiService.name);

  async generateText(
    systemInstruction: string,
    userPrompt: string,
    options: GenerateOptions = {},
  ): Promise<string> {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      throw new Error('GEMINI_API_KEY is not configured.');
    }

    const model = process.env.GEMINI_MODEL ?? 'gemini-3.5-flash';
    const url =
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent` +
      `?key=${apiKey}`;

    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        systemInstruction: {
          parts: [{ text: systemInstruction }],
        },
        contents: [
          {
            role: 'user',
            parts: [{ text: userPrompt }],
          },
        ],
        generationConfig: {
          temperature: options.temperature ?? 0.2,
          ...(options.responseMimeType
            ? { responseMimeType: options.responseMimeType }
            : {}),
        },
      }),
    });

    if (!response.ok) {
      const body = await response.text();
      this.logger.error(`Gemini request failed: ${response.status} ${body}`);
      throw new Error(`Gemini request failed with status ${response.status}`);
    }

    const json = await response.json();
    const parts = json?.candidates?.[0]?.content?.parts ?? [];
    const text = parts
      .map((part: { text?: string }) => part.text ?? '')
      .join('\n')
      .trim();

    if (!text) {
      throw new Error('Gemini returned an empty response.');
    }

    return text;
  }

  parseJsonObject<T extends Record<string, unknown>>(text: string): T {
    const trimmed = text.trim();
    const fenced = trimmed.match(/```(?:json)?\s*([\s\S]*?)```/i);
    const candidate = fenced?.[1] ?? trimmed;
    const jsonStart = candidate.indexOf('{');
    const jsonEnd = candidate.lastIndexOf('}');

    if (jsonStart === -1 || jsonEnd === -1 || jsonEnd < jsonStart) {
      throw new Error('No JSON object found in Gemini response.');
    }

    return JSON.parse(candidate.slice(jsonStart, jsonEnd + 1)) as T;
  }
}
