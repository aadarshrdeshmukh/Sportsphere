import { EspnService, normalizeLeague } from '../services/espn.service.js';
import { cacheService } from '../services/cache.service.js';
import { config } from '../config/env.js';

export class NewsController {
  static async getNews(req, res, next) {
    try {
      const rawLeague = req.query.league || 'all';
      const category = req.query.category || null;

      let data, fromCache, league;
      if (rawLeague.toLowerCase() === 'all') {
        league = 'all';
        const cacheKey = 'news:all';
        const result = await cacheService.getOrSet(
          cacheKey,
          () => EspnService.getAllNews(),
          config.cacheTtl.news
        );
        data = result.data;
        fromCache = result.fromCache;
      } else {
        league = normalizeLeague(rawLeague);
        const cacheKey = `news:${league}`;
        const result = await cacheService.getOrSet(
          cacheKey,
          () => EspnService.getNews(league),
          config.cacheTtl.news
        );
        data = result.data;
        fromCache = result.fromCache;
      }

      let articles = Array.isArray(data) ? data : (data.articles || []);

      if (category && category !== 'All') {
        articles = articles.filter((art) => {
          const desc = art.categories?.[0]?.description || art.category;
          return desc && desc.toLowerCase().includes(category.toLowerCase());
        });
      }

      res.setHeader('X-Cache-Status', fromCache ? 'HIT' : 'MISS');
      res.json({
        success: true,
        league,
        count: articles.length,
        fromCache,
        articles,
      });
    } catch (error) {
      next(error);
    }
  }
}
