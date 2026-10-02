import { EspnService, SUPPORTED_LEAGUES, normalizeLeague } from '../services/espn.service.js';
import { ApiSportsService } from '../services/api-sports.service.js';
import { cacheService } from '../services/cache.service.js';
import { config } from '../config/env.js';

export class ScoresController {
  static async getScoreboard(league, date) {
    try {
      return await ApiSportsService.getScoreboard(league, date);
    } catch (error) {
      if (ApiSportsService.enabled) {
        console.warn(`API-Sports unavailable for ${league}; using ESPN fallback:`, error.message);
      }
      return EspnService.getScoreboard(league, date);
    }
  }

  static async getScores(req, res, next) {
    try {
      const rawLeague = req.query.league || 'all';
      const date = req.query.date || null;
      const ttl = date ? config.cacheTtl.schedule : config.cacheTtl.scores;

      let data, fromCache, league;
      if (rawLeague.toLowerCase() === 'all') {
        league = 'all';
        const cacheKey = `scores:all:${date || 'today'}`;
        const result = await cacheService.getOrSet(
          cacheKey,
          async () => {
            const allEvents = [];
            const seenIds = new Set();
            await Promise.allSettled(
              SUPPORTED_LEAGUES.map(async (l) => {
                try {
                  const sb = await ScoresController.getScoreboard(l.league, date);
                  for (const ev of sb.events || []) {
                    const id = String(ev.id);
                    if (id && !seenIds.has(id)) {
                      seenIds.add(id);
                      allEvents.push({ ...ev, league: l.league });
                    }
                  }
                } catch (_) {}
              })
            );
            return { events: allEvents };
          },
          ttl
        );
        data = result.data;
        fromCache = result.fromCache;
      } else {
        league = normalizeLeague(rawLeague);
        const cacheKey = `scores:${league}:${date || 'today'}`;
        const result = await cacheService.getOrSet(
          cacheKey,
          () => ScoresController.getScoreboard(league, date),
          ttl
        );
        data = result.data;
        fromCache = result.fromCache;
      }

      res.setHeader('X-Cache-Status', fromCache ? 'HIT' : 'MISS');
      res.json({
        success: true,
        league,
        fromCache,
        data,
      });
    } catch (error) {
      next(error);
    }
  }

  static async getLiveScores(req, res, next) {
    try {
      const cacheKey = 'scores:live_all';
      const { data, fromCache } = await cacheService.getOrSet(
        cacheKey,
        async () => {
          const liveEvents = [];
          await Promise.allSettled(
            SUPPORTED_LEAGUES.map(async (l) => {
              try {
                const scoreboard = await ScoresController.getScoreboard(l.league);
                const events = scoreboard.events || [];
                for (const event of events) {
                  const status = event.status?.type?.state;
                  if (status === 'in') {
                    liveEvents.push({ ...event, league: l.league });
                  }
                }
              } catch (_) {}
            })
          );
          return liveEvents;
        },
        config.cacheTtl.liveScores
      );

      res.setHeader('X-Cache-Status', fromCache ? 'HIT' : 'MISS');
      res.json({
        success: true,
        count: data.length,
        fromCache,
        data,
      });
    } catch (error) {
      next(error);
    }
  }
}
