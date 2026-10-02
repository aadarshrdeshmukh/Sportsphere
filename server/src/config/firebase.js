import admin from 'firebase-admin';
import { config } from './env.js';

let app;

try {
  if (!admin.apps.length) {
    app = admin.initializeApp({
      projectId: config.firebaseProjectId,
    });
  } else {
    app = admin.app();
  }
} catch (error) {
  console.warn('Firebase Admin initialized without service account credential (running in project-id mode):', error.message);
}

export const auth = admin.auth();
export const db = admin.firestore();
export default admin;
