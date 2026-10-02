import { EspnService, SUPPORTED_LEAGUES } from '../services/espn.service.js';
import { cacheService } from '../services/cache.service.js';
import { config } from '../config/env.js';

export class TeamController {
  static async getPopularTeams(req, res, next) {
    try {
      const cacheKey = 'teams:popular';
      const { data, fromCache } = await cacheService.getOrSet(
        cacheKey,
        () => EspnService.getPopularTeams(),
        config.cacheTtl.popularTeams
      );

      res.setHeader('X-Cache-Status', fromCache ? 'HIT' : 'MISS');
      res.json({
        success: true,
        count: data.length,
        fromCache,
        teams: data,
      });
    } catch (error) {
      next(error);
    }
  }

  static async getTeamMatches(req, res, next) {
    try {
      const { teamId } = req.params;
      const teamName = req.query.teamName?.toLowerCase() || '';
      const cacheKey = `team:${teamId}:${teamName}:matches`;

      const { data, fromCache } = await cacheService.getOrSet(
        cacheKey,
        async () => {
          const allMatches = [];
          await Promise.allSettled(
            SUPPORTED_LEAGUES.map(async (l) => {
              try {
                const scoreboard = await EspnService.getScoreboard(l.league);
                const events = scoreboard.events || [];
                for (const event of events) {
                  const comp = event.competitions?.[0];
                  if (!comp) continue;
                  const competitors = comp.competitors || [];
                  const matchesTeam = competitors.some((c) => {
                    const cId = String(c.team?.id || '');
                    const cName = (c.team?.displayName || c.team?.name || '').toLowerCase();
                    return cId === teamId || (teamName && cName.includes(teamName));
                  });
                  if (matchesTeam) {
                    allMatches.push({ ...event, league: l.league });
                  }
                }
              } catch (_) {}
            })
          );
          return allMatches;
        },
        config.cacheTtl.teamMatches
      );

      res.setHeader('X-Cache-Status', fromCache ? 'HIT' : 'MISS');
      res.json({
        success: true,
        teamId,
        count: data.length,
        fromCache,
        matches: data,
      });
    } catch (error) {
      next(error);
    }
  }
}
