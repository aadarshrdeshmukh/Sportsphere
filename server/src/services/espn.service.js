import axios from 'axios';
import { BbcService } from './bbc.service.js';
import { TheSportsDbService } from './thesportsdb.service.js';

const ESPN_BASE_URL = 'https://site.api.espn.com/apis/site/v2/sports';

export const SUPPORTED_LEAGUES = [
  { key: 'epl', label: 'Premier League', sport: 'Soccer', league: 'soccer/eng.1' },
  { key: 'ucl', label: 'Champions League', sport: 'Soccer', league: 'soccer/uefa.champions' },
  { key: 'nba', label: 'NBA', sport: 'Basketball', league: 'basketball/nba' },
  { key: 'nfl', label: 'NFL', sport: 'Football', league: 'football/nfl' },
];

function sportLabel(league) {
  return SUPPORTED_LEAGUES.find((item) => item.league === league)?.label || 'Sports';
}

function categorize(articles, league) {
  const category = sportLabel(league);
  return articles.map((article) => ({
    ...article,
    categories: [{ description: category }],
    category,
  }));
}

/**
 * Normalizes any league slug or shorthand to a valid ESPN path (e.g., 'soccer/eng.1').
 */
export function normalizeLeague(league) {
  if (!league) return 'soccer/eng.1';
  const clean = String(league).toLowerCase().trim();
  const map = {
    'epl': 'soccer/eng.1',
    'premier-league': 'soccer/eng.1',
    'eng.1': 'soccer/eng.1',
    'soccer/eng.1': 'soccer/eng.1',
    'soccer-eng.1': 'soccer/eng.1',
    'ucl': 'soccer/uefa.champions',
    'champions-league': 'soccer/uefa.champions',
    'uefa.champions': 'soccer/uefa.champions',
    'soccer/uefa.champions': 'soccer/uefa.champions',
    'soccer-uefa.champions': 'soccer/uefa.champions',
    'nba': 'basketball/nba',
    'basketball/nba': 'basketball/nba',
    'basketball-nba': 'basketball/nba',
    'nfl': 'football/nfl',
    'football/nfl': 'football/nfl',
    'football-nfl': 'football/nfl',
  };
  if (map[clean]) return map[clean];
  if (clean.includes('-')) return clean.replace('-', '/');
  return clean;
}

export class EspnService {
  /**
   * Fetches scoreboard events for a given league and optional date string.
   */
  static async getScoreboard(league = 'soccer/eng.1', dateStr = null) {
    const canonical = normalizeLeague(league);
    const params = {};
    if (dateStr) {
      params.dates = dateStr.replace(/-/g, '');
    }
    const response = await axios.get(`${ESPN_BASE_URL}/${canonical}/scoreboard`, {
      params,
      timeout: 8000,
    });
    return response.data;
  }

  /**
   * Fetches news articles for a given league, falling back to BBC RSS if needed.
   */
  static async getNews(league = 'soccer/eng.1') {
    const canonical = normalizeLeague(league);
    try {
      const response = await axios.get(`${ESPN_BASE_URL}/${canonical}/news`, {
        timeout: 6000,
      });
      const articles = response.data?.articles;
      if (Array.isArray(articles) && articles.length > 0) {
        return categorize(articles, canonical);
      }
        return await BbcService.fetchNews(sportLabel(canonical));
    } catch (error) {
      console.warn(`ESPN news failed for ${canonical}, trying BBC RSS fallback:`, error.message);
        return await BbcService.fetchNews(sportLabel(canonical));
    }
  }

  /**
   * Fetches news articles across all supported leagues.
   */
  static async getAllNews() {
    const allArticles = [];
    const seenIds = new Set();
    await Promise.allSettled(
      SUPPORTED_LEAGUES.map(async (l) => {
        try {
          const articles = await this.getNews(l.league);
          for (const art of articles) {
            const id = String(art.id || art.headline);
            if (id && !seenIds.has(id)) {
              seenIds.add(id);
              allArticles.push(art);
            }
          }
        } catch (_) {}
      })
    );
    if (allArticles.length === 0) {
      return await BbcService.fetchNews('Sports');
    }
    allArticles.sort(
      (a, b) =>
        new Date(b.published || b.lastModified || 0) -
        new Date(a.published || a.lastModified || 0)
    );
    return allArticles;
  }

  /**
   * Fetches match summary including competitors, venue, and key timeline events.
   */
  static async getSummary(league = 'soccer/eng.1', eventId) {
    const canonical = normalizeLeague(league);
    try {
      const response = await axios.get(`${ESPN_BASE_URL}/${canonical}/summary`, {
        params: { event: eventId },
        timeout: 8000,
      });
      return response.data;
    } catch (error) {
      // ESPN removes summary records for older or unsupported events while
      // the corresponding scoreboard event can still be available.
      if (error.response?.status === 404) {
        return {};
      }
      throw error;
    }
  }

  /**
   * Fetches popular teams across all 4 supported leagues.
   */
  static async getPopularTeams() {
    const teamsMap = new Map();

    await Promise.allSettled(
      SUPPORTED_LEAGUES.map(async (leagueObj) => {
        try {
          const scoreboard = await this.getScoreboard(leagueObj.league);
          const events = scoreboard.events || [];
          for (const event of events) {
            for (const competition of event.competitions || []) {
              for (const competitor of competition.competitors || []) {
                const team = competitor.team || {};
                const id = String(team.id || '');
                if (id && !teamsMap.has(id)) {
                  let logoUrl = team.logo || (Array.isArray(team.logos) && team.logos[0]?.href);
                  if (!logoUrl) {
                    logoUrl = await TheSportsDbService.getTeamBadge(team.displayName || team.name);
                  }
                  teamsMap.set(id, {
                    id: id,
                    name: team.displayName || team.name || 'Unknown',
                    abbreviation: team.abbreviation || team.shortDisplayName || '',
                    logoUrl: logoUrl || null,
                    league: leagueObj.league,
                  });
                }
              }
            }
          }
        } catch (_) {}
      })
    );

    return Array.from(teamsMap.values());
  }
}
