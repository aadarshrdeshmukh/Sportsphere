import NodeCache from 'node-cache';

class CacheService {
  constructor() {
    this.cache = new NodeCache({
      stdTTL: 60,
      checkperiod: 120,
      useClones: false,
    });
  }

  get(key) {
    return this.cache.get(key);
  }

  set(key, value, ttlSeconds) {
    if (ttlSeconds !== undefined) {
      return this.cache.set(key, value, ttlSeconds);
    }
    return this.cache.set(key, value);
  }

  has(key) {
    return this.cache.has(key);
  }

  del(key) {
    return this.cache.del(key);
  }

  flush() {
    return this.cache.flushAll();
  }

  async getOrSet(key, fetchFn, ttlSeconds) {
    const cached = this.get(key);
    if (cached !== undefined) {
      return { data: cached, fromCache: true };
    }
    const freshData = await fetchFn();
    if (freshData !== undefined && freshData !== null) {
      this.set(key, freshData, ttlSeconds);
    }
    return { data: freshData, fromCache: false };
  }
}

export const cacheService = new CacheService();
