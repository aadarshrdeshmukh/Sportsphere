import { Router } from 'express';
import { TeamController } from '../controllers/team.controller.js';

const router = Router();

router.get('/popular', TeamController.getPopularTeams);
router.get('/:teamId/matches', TeamController.getTeamMatches);

export default router;
