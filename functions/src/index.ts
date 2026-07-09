/* eslint-disable */
/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {onDocumentCreated, onDocumentWritten} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

// Initialize the Firebase Admin SDK
if (admin.apps.length === 0) {
  admin.initializeApp();
}

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

// Trigger when a schedule is created or updated
export const onScheduleUpdated = onDocumentWritten("schedules/{scheduleId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    logger.log("No data associated with the event");
    return;
  }

  const scheduleId = event.params.scheduleId;
  const beforeData = snapshot.before.data();
  const afterData = snapshot.after.data();

  if (!afterData) {
    logger.info(`Schedule deleted: ${scheduleId}`);
    
    // Save audit log for deletion
    await admin.firestore().collection("system_logs").add({
      action: "DELETE",
      type: "SCHEDULE",
      targetId: scheduleId,
      details: `Lịch học ${scheduleId} đã bị xóa.`,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
    return;
  }

  if (!beforeData) {
    logger.info(`New schedule created: ${scheduleId} (Course: ${afterData.courseName})`);
  } else {
    logger.info(`Schedule updated: ${scheduleId} (Course: ${afterData.courseName})`);
  }

  // Auto-attach a server timestamp
  const updateData = {
    serverUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  // Prevent infinite loops by only updating if serverUpdatedAt is missing or not a timestamp
  if (!afterData.serverUpdatedAt) {
    try {
      await snapshot.after.ref.set(updateData, { merge: true });
      
      // Save an audit log to a separate collection in Firestore
      await admin.firestore().collection("system_logs").add({
        action: !beforeData ? "CREATE" : "UPDATE",
        type: "SCHEDULE",
        targetId: scheduleId,
        details: `Lịch học môn ${afterData.courseName} đã được ${!beforeData ? "tạo mới" : "cập nhật"}.`,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      logger.info(`Successfully added server timestamp and log for schedule ${scheduleId}`);
    } catch (error) {
      logger.error(`Error updating schedule ${scheduleId}:`, error);
    }
  }
});

// Trigger when a notification is created or updated
export const onNotificationUpdated = onDocumentWritten("notifications/{notificationId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    logger.log("No data associated with the event");
    return;
  }

  const notificationId = event.params.notificationId;
  const beforeData = snapshot.before.data();
  const afterData = snapshot.after.data();

  if (!afterData) {
    logger.info(`Notification deleted: ${notificationId}`);
    
    // Save audit log for deletion
    await admin.firestore().collection("system_logs").add({
      action: "DELETE",
      type: "NOTIFICATION",
      targetId: notificationId,
      details: `Thông báo ${notificationId} đã bị xóa.`,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
    return;
  }

  if (!beforeData) {
    logger.info(`New notification created: ${notificationId} (Title: ${afterData.title})`);
  } else {
    logger.info(`Notification updated: ${notificationId} (Title: ${afterData.title})`);
  }

  const updateData = {
    serverUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  // Prevent infinite loops
  if (!afterData.serverUpdatedAt) {
    try {
      await snapshot.after.ref.set(updateData, { merge: true });
      
      // Save an audit log to a separate collection in Firestore
      await admin.firestore().collection("system_logs").add({
        action: !beforeData ? "CREATE" : "UPDATE",
        type: "NOTIFICATION",
        targetId: notificationId,
        details: `Thông báo "${afterData.title}" đã được ${!beforeData ? "tạo mới" : "cập nhật"}.`,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      logger.info(`Successfully added server timestamp and log for notification ${notificationId}`);
    } catch (error) {
      logger.error(`Error updating notification ${notificationId}:`, error);
    }
  }
});

import { onRequest } from 'firebase-functions/v2/https';
export const setCors = onRequest({cors: true}, async (req, res) => {
  try {
    if (req.method === 'POST') {
      const { base64Data, mimeType, fileName } = req.body;
      if (!base64Data || !fileName) {
        res.status(400).send('Missing data');
        return;
      }
      const bucket = admin.storage().bucket('edu---track.firebasestorage.app');
      const file = bucket.file('tuition_proofs/' + fileName);
      const buffer = Buffer.from(base64Data, 'base64');
      await file.save(buffer, {
        metadata: {
          contentType: mimeType || 'image/jpeg'
        }
      });
      
      const downloadUrl = `https://firebasestorage.googleapis.com/v0/b/edu---track.firebasestorage.app/o/tuition_proofs%2F${encodeURIComponent(fileName)}?alt=media`;
      res.status(200).json({ url: downloadUrl });
      return;
    }

    // Default behavior for GET
    const bucket = admin.storage().bucket('edu---track.firebasestorage.app');
    await bucket.setCorsConfiguration([{
      origin: ['*'],
      method: ['GET', 'PUT', 'POST', 'DELETE', 'OPTIONS'],
      maxAgeSeconds: 3600,
      responseHeader: ['*']
    }]);
    res.send('CORS set successfully');
  } catch (e: any) {
    res.status(500).send(e.toString());
  }
});
