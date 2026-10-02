import { EspnService } from '../services/espn.service.js';
import { cacheService } from '../services/cache.service.js';
import { config } from '../config/env.js';

export class MatchController {
  static async getMatchSummary(req, res, next) {
    try {
      const { league, eventId } = req.params;
      const cleanLeague = league.replace(/-/g, '/');
      const cacheKey = `summary:${cleanLeague}:${eventId}`;

      const { data, fromCache } = await cacheService.getOrSet(
        cacheKey,
        () => EspnService.getSummary(cleanLeague, eventId),
        config.cacheTtl.matchSummary
      );

      res.setHeader('X-Cache-Status', fromCache ? 'HIT' : 'MISS');
      res.json({
        success: true,
        league: cleanLeague,
        eventId,
        fromCache,
        summary: data,
      });
    } catch (error) {
      next(error);
    }
  }
}
