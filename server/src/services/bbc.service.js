import axios from 'axios';

const BBC_FEED_URL = 'https://feeds.bbci.co.uk/sport/rss.xml';

export class BbcService {
  static async fetchNews(category = 'Sports') {
    try {
      const response = await axios.get(BBC_FEED_URL, {
        timeout: 5000,
        headers: { 'User-Agent': 'SportSphere/1.0' },
      });
      const xml = response.data;
      return this._parseRss(xml, category);
    } catch (error) {
      console.warn('BBC RSS fetch failed:', error.message);
      return [];
    }
  }

  static _parseRss(xml, category) {
    const items = [];
    const itemRegex = /<item>([\s\S]*?)<\/item>/g;
    let match;

    while ((match = itemRegex.exec(xml)) !== null && items.length < 20) {
      const chunk = match[1];
      const title = this._extractTag(chunk, 'title') || 'Untitled';
      const description = this._extractTag(chunk, 'description') || '';
      const link = this._extractTag(chunk, 'link');
      const pubDateStr = this._extractTag(chunk, 'pubDate');
      const published = pubDateStr ? new Date(pubDateStr).toISOString() : new Date().toISOString();

      items.push({
        id: link || title,
        headline: title,
        description: description,
        published: published,
        images: [],
        categories: [{ description: category }],
        category,
        source: { name: 'BBC Sport' },
        links: link ? { web: { href: link } } : undefined,
      });
    }

    return items;
  }

  static _extractTag(xmlChunk, tag) {
    const match = new RegExp(`<${tag}[^>]*><!\\[CDATA\\[([\\s\\S]*?)\\]\\]><\\/${tag}>`, 'i').exec(xmlChunk) ||
                  new RegExp(`<${tag}[^>]*>([\\s\\S]*?)<\\/${tag}>`, 'i').exec(xmlChunk);
    return match ? match[1].trim() : null;
  }
}
