import app from './app.js';
import { config } from './config/env.js';

const PORT = config.port;

app.listen(PORT, () => {
  console.log(`=========================================`);
  console.log(`🚀 SportSphere API Server is running!`);
  console.log(`📍 Port: ${PORT}`);
  console.log(`🌐 Base URL: http://localhost:${PORT}/api/v1`);
  console.log(`⚡ Health check: http://localhost:${PORT}/api/v1/health`);
  console.log(`=========================================`);
});
