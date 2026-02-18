/**
 * Cloud Functions (v2) for Flutter Forager Push Notifications
 *
 * Tier 1 Notifications:
 * 1. Friend Request Received - when someone sends a friend request
 * 2. Friend Request Accepted - when your friend request is accepted
 * 3. Post Liked - when someone likes your post
 * 4. Post Comment - when someone comments on your post
 */

import {
  onDocumentCreated,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import {initializeApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

interface NotificationInfo {
  token: string | null;
  socialEnabled: boolean;
  enabled: boolean;
}

/**
 * Get user's FCM token and notification preferences.
 */
async function getUserNotificationInfo(
  userEmail: string
): Promise<NotificationInfo> {
  try {
    const userDoc = await db.collection("Users").doc(userEmail).get();
    if (!userDoc.exists) {
      return {token: null, socialEnabled: false, enabled: false};
    }

    const prefs = userDoc.data()?.notificationPreferences;
    return {
      token: prefs?.fcmToken || null,
      socialEnabled: prefs?.socialNotifications !== false,
      enabled: prefs?.enabled !== false,
    };
  } catch (error) {
    console.error(`Error getting notification info for ${userEmail}:`, error);
    return {token: null, socialEnabled: false, enabled: false};
  }
}

/**
 * Send a push notification to a user.
 */
async function sendNotification(
  token: string,
  title: string,
  body: string,
  data: Record<string, string>,
  priority: "high" | "normal" = "high"
): Promise<boolean> {
  try {
    await messaging.send({
      token,
      notification: {
        title,
        body,
      },
      data: {
        ...data,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority,
        notification: {
          channelId: "forager_notifications",
          icon: "ic_notification",
          color: "#4CAF50",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    });
    console.log(`Notification sent successfully to token: ${token.slice(0, 20)}...`);
    return true;
  } catch (error) {
    console.error("Error sending notification:", error);
    return false;
  }
}

/**
 * Store a notification in the recipient's Notifications subcollection.
 */
async function storeNotification(
  recipientEmail: string,
  title: string,
  body: string,
  type: string,
  data: Record<string, string>
): Promise<void> {
  try {
    await db
      .collection("Users")
      .doc(recipientEmail)
      .collection("Notifications")
      .add({
        type,
        title,
        body,
        fromEmail: data.fromEmail || data.likerEmail || data.commenterEmail || null,
        fromDisplayName: data.fromDisplayName || null,
        postId: data.postId || null,
        requestId: data.requestId || null,
        isRead: false,
        createdAt: new Date(),
      });
    console.log(`Notification stored for ${recipientEmail}`);
  } catch (error) {
    console.error(`Error storing notification for ${recipientEmail}:`, error);
  }
}

// ============================================================================
// 1. FRIEND REQUEST RECEIVED
// ============================================================================

export const onFriendRequestCreated = onDocumentCreated(
  "Users/{userId}/FriendRequests/{requestId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const request = snap.data();
    const recipientEmail = event.params.userId;

    // Only notify for pending requests sent TO this user (not outgoing copies)
    if (request.status !== "pending") {
      console.log("Skipping non-pending request");
      return;
    }
    if (request.fromEmail === recipientEmail) {
      console.log("Skipping sender's own copy of request");
      return;
    }

    // Build notification content
    const senderName = request.fromDisplayName || "Someone";
    const hasMessage = request.message && request.message.trim().length > 0;
    const notifTitle = "New Friend Request";
    const notifBody = hasMessage
      ? `${senderName}: "${request.message.slice(0, 50)}${request.message.length > 50 ? "..." : ""}"`
      : `${senderName} wants to connect with you!`;
    const notifData = {
      type: "friend_request",
      requestId: event.params.requestId,
      fromEmail: request.fromEmail || "",
      fromDisplayName: senderName,
    };

    // Always store in Firestore for in-app notification list
    await storeNotification(recipientEmail, notifTitle, notifBody, "friend_request", notifData);

    // Send push notification if enabled
    const {token, socialEnabled, enabled} = await getUserNotificationInfo(
      recipientEmail
    );
    if (!token || !enabled || !socialEnabled) {
      console.log(`Push skipped for ${recipientEmail} (no token or disabled)`);
      return;
    }

    await sendNotification(token, notifTitle, notifBody, notifData);
  }
);

// ============================================================================
// 2. FRIEND REQUEST ACCEPTED
// ============================================================================

export const onFriendRequestUpdated = onDocumentUpdated(
  "Users/{userId}/FriendRequests/{requestId}",
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();
    if (!beforeData || !afterData) return;

    // Only trigger when status changes to "accepted"
    if (beforeData.status === "accepted" || afterData.status !== "accepted") {
      return;
    }

    const senderEmail = afterData.fromEmail;
    if (!senderEmail) {
      console.log("No sender email found");
      return;
    }

    // Get acceptor's name
    const acceptorEmail = event.params.userId;
    const acceptorDoc = await db.collection("Users").doc(acceptorEmail).get();
    const acceptorName = acceptorDoc.data()?.displayName ||
                         acceptorDoc.data()?.username ||
                         "Someone";

    // Build notification content
    const notifTitle = "Friend Request Accepted";
    const notifBody = `${acceptorName} accepted your friend request!`;
    const notifData = {
      type: "friend_accepted",
      friendEmail: acceptorEmail,
      fromEmail: acceptorEmail,
      fromDisplayName: acceptorName,
    };

    // Always store in Firestore
    await storeNotification(senderEmail, notifTitle, notifBody, "friend_accepted", notifData);

    // Send push if enabled
    const {token, socialEnabled, enabled} = await getUserNotificationInfo(
      senderEmail
    );
    if (!token || !enabled || !socialEnabled) {
      console.log(`Push skipped for ${senderEmail}`);
      return;
    }

    await sendNotification(token, notifTitle, notifBody, notifData);
  }
);

// ============================================================================
// 3. POST LIKED
// ============================================================================

export const onPostLiked = onDocumentUpdated(
  "Posts/{postId}",
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();
    if (!beforeData || !afterData) return;

    const beforeLikes: string[] = beforeData.likes || [];
    const afterLikes: string[] = afterData.likes || [];

    // Check if likes increased (new like, not unlike)
    if (afterLikes.length <= beforeLikes.length) {
      return;
    }

    // Find the new liker
    const newLiker = afterLikes.find((email) => !beforeLikes.includes(email));
    if (!newLiker) {
      return;
    }

    const postOwnerEmail = afterData.userEmail;

    // Don't notify for self-likes
    if (newLiker === postOwnerEmail) {
      console.log("Skipping self-like notification");
      return;
    }

    // Get liker's name
    const likerDoc = await db.collection("Users").doc(newLiker).get();
    const likerName = likerDoc.data()?.displayName ||
                      likerDoc.data()?.username ||
                      "Someone";

    const postName = afterData.name || "your post";

    // Build notification content
    const notifTitle = "Someone liked your post";
    const notifBody = `${likerName} liked "${postName}"`;
    const notifData = {
      type: "post_like",
      postId: event.params.postId,
      likerEmail: newLiker,
      fromEmail: newLiker,
      fromDisplayName: likerName,
    };

    // Always store in Firestore
    await storeNotification(postOwnerEmail, notifTitle, notifBody, "post_like", notifData);

    // Send push if enabled
    const {token, socialEnabled, enabled} = await getUserNotificationInfo(
      postOwnerEmail
    );
    if (!token || !enabled || !socialEnabled) {
      console.log(`Push skipped for ${postOwnerEmail}`);
      return;
    }

    await sendNotification(token, notifTitle, notifBody, notifData, "normal");
  }
);

// ============================================================================
// 4. POST COMMENT ADDED
// ============================================================================

export const onPostComment = onDocumentCreated(
  "Posts/{postId}/Comments/{commentId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const comment = snap.data();
    const postId = event.params.postId;

    // Get the post to find the owner
    const postDoc = await db.collection("Posts").doc(postId).get();
    if (!postDoc.exists) {
      console.log(`Post ${postId} not found`);
      return;
    }

    const post = postDoc.data();
    const postOwnerEmail = post?.userEmail;
    const commenterEmail = comment.userEmail;

    if (!postOwnerEmail) {
      console.log("No post owner email found");
      return;
    }

    // Don't notify for self-comments
    if (commenterEmail === postOwnerEmail) {
      console.log("Skipping self-comment notification");
      return;
    }

    // Get commenter's name
    const commenterName = comment.username ||
                          commenterEmail?.split("@")[0] ||
                          "Someone";

    // Truncate comment text for preview
    const commentText = comment.text || "";
    const preview = commentText.length > 50
      ? `${commentText.slice(0, 50)}...`
      : commentText;

    // Build notification content
    const notifTitle = "New comment on your post";
    const notifBody = `${commenterName}: ${preview}`;
    const notifData = {
      type: "post_comment",
      postId: postId,
      commentId: event.params.commentId,
      commenterEmail: commenterEmail || "",
      fromEmail: commenterEmail || "",
      fromDisplayName: commenterName,
    };

    // Always store in Firestore
    await storeNotification(postOwnerEmail, notifTitle, notifBody, "post_comment", notifData);

    // Send push if enabled
    const {token, socialEnabled, enabled} = await getUserNotificationInfo(
      postOwnerEmail
    );
    if (!token || !enabled || !socialEnabled) {
      console.log(`Push skipped for ${postOwnerEmail}`);
      return;
    }

    await sendNotification(token, notifTitle, notifBody, notifData, "normal");
  }
);
