import { Router } from 'express';
import scoresRoutes from './scores.routes.js';
import newsRoutes from './news.routes.js';
import matchRoutes from './match.routes.js';
import teamRoutes from './team.routes.js';
import favoritesRoutes from './favorites.routes.js';

const apiRouter = Router();

apiRouter.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'SportSphere API',
    timestamp: new Date().toISOString(),
  });
});

apiRouter.use('/scores', scoresRoutes);
apiRouter.use('/news', newsRoutes);
apiRouter.use('/matches', matchRoutes);
apiRouter.use('/teams', teamRoutes);
apiRouter.use('/favorites', favoritesRoutes);

export default apiRouter;
