# SportSphere Backend API (Express.js)

A high-performance Node.js / Express.js REST API with intelligent caching, multi-tier sports aggregators, and Firebase Admin SDK.

## Features
- **Scoreboard & Live Scores API**: Aggregated live match tracking across EPL, Champions League, NBA, and NFL with 20s-30s in-memory TTL caching.
- **News Aggregator**: ESPN news feed with automatic fallback to BBC Sport RSS.
- **Match Summaries & Timelines**: Real-time match details and key timeline events.
- **Team Catalogs & Logo Fallbacks**: Integration with TheSportsDB for team badges.
- **Firebase Admin Security**: Protected `/api/v1/favorites` routes verifying Bearer ID tokens to sync favorites in Cloud Firestore.

## Quick Start

### 1. Install Dependencies
```bash
npm install
```

### 2. Run Development Server
```bash
npm run dev
```

Server will start on `http://localhost:3000`.

### API-Sports (optional)

Add your API-Sports key to `server/.env` to use API-Sports for football, basketball, and NFL scores:

```env
API_SPORTS_KEY=your_api_sports_key
```

The backend normalizes API-Sports responses to the existing app format and falls back to ESPN when the key is missing or a request fails. Keep the key on the backend and never commit it.

### 3. API Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| `GET` | `/api/v1/health` | Service health status | No |
| `GET` | `/api/v1/scores?league=soccer/eng.1` | League scoreboard | No |
| `GET` | `/api/v1/scores/live` | Active live matches across leagues | No |
| `GET` | `/api/v1/news?league=soccer/eng.1` | Sports news feed with BBC fallback | No |
| `GET` | `/api/v1/matches/:league/:eventId/summary` | Match summary & key events | No |
| `GET` | `/api/v1/teams/popular` | Popular teams catalog | No |
| `GET` | `/api/v1/teams/:teamId/matches` | Team fixtures & results | No |
| `GET` | `/api/v1/favorites` | Get user's cloud favorites | Yes (Bearer Token) |
| `POST` | `/api/v1/favorites` | Save/update favorite team | Yes (Bearer Token) |
| `DELETE` | `/api/v1/favorites/:teamId` | Remove favorite team | Yes (Bearer Token) |
