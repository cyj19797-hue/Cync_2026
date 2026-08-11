import { Body, Controller, Post } from '@nestjs/common';
import { AiService } from './ai.service';
import { PredictDto } from './dto/predict.dto';

@Controller('api/v1/ai')
export class AiController {
  constructor(private readonly aiService: AiService) {}

  @Post('predict')
  async predict(@Body() body: PredictDto) {
    const data = await this.aiService.predict(body.text);
    return { success: true, data };
  }
}
