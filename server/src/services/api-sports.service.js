import axios from 'axios';

const API_SPORTS_HOSTS = {
  football: 'https://v3.football.api-sports.io',
  basketball: 'https://v1.basketball.api-sports.io',
  americanFootball: 'https://v1.american-football.api-sports.io',
};

const LEAGUES = {
  'soccer/eng.1': { sport: 'football', id: 39 },
  'soccer/uefa.champions': { sport: 'football', id: 2 },
  'basketball/nba': { sport: 'basketball', id: 12 },
  'football/nfl': { sport: 'americanFootball', id: 1 },
};

function seasonFor(sport, date) {
  const year = Number(date.slice(0, 4));
  if (sport === 'basketball') {
    const month = Number(date.slice(5, 7));
    return month >= 10 ? `${year}-${year + 1}` : `${year - 1}-${year}`;
  }
  return String(year);
}

function dateValue(value) {
  return value ? new Date(value).toISOString() : new Date().toISOString();
}

function statusValue(status = {}) {
  const short = String(status.short || '').toLowerCase();
  const completed = ['ft', 'aot', 'ap', 'final', 'finished'].includes(short);
  const live = !completed && !['ns', 'tbd', 'pst', 'canc', 'canceled'].includes(short);
  return {
    completed,
    state: live ? 'in' : completed ? 'post' : 'pre',
    description: status.long || status.short || 'Scheduled',
  };
}

function scoreValue(value) {
  return value === null || value === undefined ? '' : String(value);
}

function normalizeEvent(event, league) {
  const fixture = event.fixture || event.game || {};
  const teams = event.teams || {};
  const home = teams.home || {};
  const away = teams.away || {};
  const status = statusValue(fixture.status || event.status);
  const scores = event.scores || event.goals || {};
  const homeScore = scores.home?.points ?? scores.home;
  const awayScore = scores.away?.points ?? scores.away;

  return {
    id: String(fixture.id || event.id),
    date: dateValue(fixture.date || event.date),
    league,
    shortName: `${home.name || 'Home'} vs ${away.name || 'Away'}`,
    competitions: [{
      competitors: [
        {
          homeAway: 'home',
          score: scoreValue(homeScore),
          team: { id: String(home.id || ''), displayName: home.name || 'Home', logo: home.logo || null },
        },
        {
          homeAway: 'away',
          score: scoreValue(awayScore),
          team: { id: String(away.id || ''), displayName: away.name || 'Away', logo: away.logo || null },
        },
      ],
      status: {
        type: {
          state: status.state,
          completed: status.completed,
          description: status.description,
          shortDetail: status.description,
        },
      },
      venue: { fullName: fixture.venue?.name || '' },
    }],
  };
}

export class ApiSportsService {
  static get enabled() {
    return Boolean(process.env.API_SPORTS_KEY);
  }

  static async getScoreboard(league, date) {
    if (!this.enabled) {
      throw new Error('API-Sports is not configured');
    }
    const mapping = LEAGUES[league];
    if (!mapping) {
      throw new Error(`API-Sports does not support league: ${league}`);
    }

    const targetDate = date || new Date().toISOString().slice(0, 10);
    const params = {
      league: mapping.id,
      season: seasonFor(mapping.sport, targetDate),
      date: targetDate,
    };
    const endpoint = mapping.sport === 'football' ? 'fixtures' : 'games';
    const response = await axios.get(`${API_SPORTS_HOSTS[mapping.sport]}/${endpoint}`, {
      params,
      headers: { 'x-apisports-key': process.env.API_SPORTS_KEY },
      timeout: 8000,
    });
    const errors = response.data?.errors;
    if (errors && Object.keys(errors).length > 0) {
      throw new Error(Object.values(errors).join('; '));
    }
    const events = response.data?.response || [];
    return { events: events.map((event) => normalizeEvent(event, league)) };
  }
}
