import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  getHello(): string {
    return 'Cync backend';
  }

  getHealth() {
    return {
      success: true,
      data: {
        status: 'ok',
        service: 'cync-backend',
      },
    };
  }
}
