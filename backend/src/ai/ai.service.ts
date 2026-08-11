import {
  Injectable,
  BadGatewayException,
  ServiceUnavailableException,
} from '@nestjs/common';

@Injectable()
export class AiService {
  private readonly aiBaseUrl =
    process.env.AI_BASE_URL ?? 'http://localhost:8000';

  async predict(text: string): Promise<{ label: string; score: number }> {
    let response: Response;

    try {
      response = await fetch(`${this.aiBaseUrl}/predict`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text }),
      });
    } catch {
      throw new ServiceUnavailableException('AI server is unreachable');
    }

    if (!response.ok) {
      throw new BadGatewayException('AI server returned an error');
    }

    return (await response.json()) as { label: string; score: number };
  }
}
