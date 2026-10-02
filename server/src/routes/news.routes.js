import { Router } from 'express';
import { NewsController } from '../controllers/news.controller.js';

const router = Router();

router.get('/', NewsController.getNews);

export default router;
