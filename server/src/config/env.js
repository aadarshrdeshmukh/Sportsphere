import dotenv from 'dotenv';

dotenv.config();

export const config = {
  port: process.env.PORT || 3000,
  nodeEnv: process.env.NODE_ENV || 'development',
  firebaseProjectId: process.env.FIREBASE_PROJECT_ID || 'sportsphere-45964',
  corsOrigin: process.env.CORS_ORIGIN || '*',
  apiSportsKey: process.env.API_SPORTS_KEY || '',
  cacheTtl: {
    liveScores: 20,       // 20 seconds for active live scores
    scores: 60,           // 1 minute for today's scoreboards
    schedule: 600,        // 10 minutes for past/future schedules
    news: 900,            // 15 minutes for sports news
    matchSummary: 30,     // 30 seconds for live match key events
    popularTeams: 3600,   // 1 hour for popular team catalogs
    teamMatches: 120,     // 2 minutes for team fixtures
  },
};
