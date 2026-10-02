import { db } from '../config/firebase.js';

export class FavoritesController {
  static async getFavorites(req, res, next) {
    try {
      const userId = req.user.uid;
      const snapshot = await db.collection('users').doc(userId).collection('favorites').get();
      const favorites = snapshot.docs.map((doc) => doc.data());

      res.json({
        success: true,
        count: favorites.length,
        favorites,
      });
    } catch (error) {
      next(error);
    }
  }

  static async saveFavorite(req, res, next) {
    try {
      const userId = req.user.uid;
      const team = req.body;

      if (!team || !team.id) {
        return res.status(400).json({
          error: true,
          message: 'Missing team data or team.id in request body.',
        });
      }

      await db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(String(team.id))
        .set(team);

      res.json({
        success: true,
        message: 'Favorite saved successfully.',
        team,
      });
    } catch (error) {
      next(error);
    }
  }

  static async removeFavorite(req, res, next) {
    try {
      const userId = req.user.uid;
      const { teamId } = req.params;

      if (!teamId) {
        return res.status(400).json({
          error: true,
          message: 'Missing teamId parameter in URL.',
        });
      }

      await db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(String(teamId))
        .delete();

      res.json({
        success: true,
        message: 'Favorite removed successfully.',
        teamId,
      });
    } catch (error) {
      next(error);
    }
  }
}
