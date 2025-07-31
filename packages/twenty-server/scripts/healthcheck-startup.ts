#!/usr/bin/env tsx

import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';

async function performStartupHealthCheck() {
  console.log('🏥 Performing startup health check...');
  
  try {
    // Create a minimal app instance for health check
    const app = await NestFactory.create(AppModule, {
      logger: false, // Disable logging for health check
    });
    
    // Get the health controller
    const healthController = app.get('HealthController');
    
    // Perform startup check
    const result = await healthController.startupCheck();
    
    console.log('✅ Startup health check passed:', result);
    
    await app.close();
    process.exit(0);
  } catch (error) {
    console.error('❌ Startup health check failed:', error);
    process.exit(1);
  }
}

// Run the health check
performStartupHealthCheck(); 