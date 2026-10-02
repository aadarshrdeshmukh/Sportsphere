import { Router } from 'express';
import { FavoritesController } from '../controllers/favorites.controller.js';
import { requireAuth } from '../middleware/auth.middleware.js';

const router = Router();

// All favorite routes require valid Firebase ID token authentication
router.use(requireAuth);

router.get('/', FavoritesController.getFavorites);
router.post('/', FavoritesController.saveFavorite);
router.delete('/:teamId', FavoritesController.removeFavorite);

export default router;
