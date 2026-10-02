import { Router } from 'express';
import { MatchController } from '../controllers/match.controller.js';

const router = Router();

router.get('/:league/:eventId/summary', MatchController.getMatchSummary);

export default router;
