/* eslint-disable */
/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

// Initialize the Firebase Admin SDK
admin.initializeApp();

// Trigger when a new user document is created in the 'users' collection
export const onUserRegistered = onDocumentCreated("users/{userId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    logger.log("No data associated with the event");
    return;
  }

  const userId = event.params.userId;
  const userData = snapshot.data();
  const roleStr = userData.role === 'student' ? 'Sinh viên' : 'Giảng viên';
  
  logger.info(`Processing new user registration for: ${userId} (${roleStr})`);

  // Auto-verify the account and add a system note
  const now = new Date();
  const vnTime = new Date(now.getTime() + (7 * 60 * 60 * 1000)); // UTC+7 basic calculation
  const timeStr = `${vnTime.toISOString().replace('T', ' ').substring(0, 19)}`;

  const updateData = {
    isVerified: true,
    systemNote: `Tài khoản ${roleStr} được hệ thống xác nhận tự động lúc ${timeStr}`,
  };

  try {
    await snapshot.ref.set(updateData, { merge: true });
    logger.info(`Successfully verified user ${userId}`);
  } catch (error) {
    logger.error(`Error verifying user ${userId}:`, error);
  }
});
