import { Router } from 'express';
import { ScoresController } from '../controllers/scores.controller.js';

const router = Router();

router.get('/', ScoresController.getScores);
router.get('/live', ScoresController.getLiveScores);

export default router;
