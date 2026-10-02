import axios from 'axios';

const TSDB_BASE_URL = 'https://www.thesportsdb.com/api/v1/json/3';

export class TheSportsDbService {
  static async getTeamBadge(teamName) {
    if (!teamName) return null;
    try {
      const response = await axios.get(`${TSDB_BASE_URL}/searchteams.php`, {
        params: { t: teamName },
        timeout: 4000,
      });
      const teams = response.data?.teams;
      if (Array.isArray(teams) && teams.length > 0) {
        return teams[0].strBadge || teams[0].strLogo || null;
      }
      return null;
    } catch (error) {
      return null;
    }
  }
}
