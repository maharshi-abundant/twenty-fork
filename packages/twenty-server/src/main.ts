import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';

import fs from 'fs';

import bytes from 'bytes';
import { useContainer } from 'class-validator';
import session from 'express-session';
import { graphqlUploadExpress } from 'graphql-upload';

import { NodeEnvironment } from 'src/engine/core-modules/twenty-config/interfaces/node-environment.interface';

import { LoggerService } from 'src/engine/core-modules/logger/logger.service';
import { getSessionStorageOptions } from 'src/engine/core-modules/session-storage/session-storage.module-factory';
import { TwentyConfigService } from 'src/engine/core-modules/twenty-config/twenty-config.service';
import { UnhandledExceptionFilter } from 'src/filters/unhandled-exception.filter';

import { AppModule } from './app.module';
import './instrument';

import { settings } from './engine/constants/settings';
import { generateFrontConfig } from './utils/generate-front-config';

const bootstrap = async () => {
  console.log('🚀 Starting Twenty application...');
  console.log('📊 Environment variables:');
  console.log('  - PORT:', process.env.PORT);
  console.log('  - NODE_PORT:', process.env.NODE_PORT);
  console.log('  - DATABASE_URL:', process.env.DATABASE_URL ? 'SET' : 'NOT SET');
  console.log('  - REDIS_URL:', process.env.REDIS_URL ? 'SET' : 'NOT SET');
  
  const app = await NestFactory.create<NestExpressApplication>(AppModule, {
    cors: true,
    bufferLogs: process.env.LOGGER_IS_BUFFER_ENABLED === 'true',
    rawBody: true,
    snapshot: process.env.NODE_ENV === NodeEnvironment.DEVELOPMENT,
    ...(process.env.SSL_KEY_PATH && process.env.SSL_CERT_PATH
      ? {
          httpsOptions: {
            key: fs.readFileSync(process.env.SSL_KEY_PATH),
            cert: fs.readFileSync(process.env.SSL_CERT_PATH),
          },
        }
      : {}),
  });
  const logger = app.get(LoggerService);
  const twentyConfigService = app.get(TwentyConfigService);

  app.use(session(getSessionStorageOptions(twentyConfigService)));

  // Apply class-validator container so that we can use injection in validators
  useContainer(app.select(AppModule), { fallbackOnErrors: true });

  // Use our logger
  app.useLogger(logger);

  app.useGlobalFilters(new UnhandledExceptionFilter());

  app.useBodyParser('json', { limit: settings.storage.maxFileSize });
  app.useBodyParser('urlencoded', {
    limit: settings.storage.maxFileSize,
    extended: true,
  });

  // Graphql file upload
  app.use(
    '/graphql',
    graphqlUploadExpress({
      maxFieldSize: bytes(settings.storage.maxFileSize),
      maxFiles: 10,
    }),
  );

  app.use(
    '/metadata',
    graphqlUploadExpress({
      maxFieldSize: bytes(settings.storage.maxFileSize),
      maxFiles: 10,
    }),
  );

  // Inject the server url in the frontend page
  generateFrontConfig();

  // Use PORT environment variable (Railway) or fall back to NODE_PORT (local development)
  const port = process.env.PORT || twentyConfigService.get('NODE_PORT');
  console.log(`🌐 Starting server on port ${port}...`);
  
  await app.listen(port);
  console.log(`✅ Server started successfully on port ${port}`);
  console.log(`🏥 Healthcheck available at: http://localhost:${port}/healthz`);
};

bootstrap().catch((error) => {
  console.error('❌ Failed to start application:', error);
  process.exit(1);
});
