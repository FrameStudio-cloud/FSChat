const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');
admin.initializeApp();

function sendFCMMessage(token, title, body, data) {
  return admin.messaging().send({
    token,
    notification: { title, body },
    data,
  });
}

async function getUserPushToken(uid) {
  const snap = await admin.firestore().doc(`users/${uid}`).get();
  return snap.data()?.pushToken;
}

exports.sendMessageNotification = onDocumentCreated(
  'chats/{chatId}/messages/{messageId}',
  async (event) => {
    const message = event.data?.data();
    if (!message) return;

    const { chatId } = event.params;
    const senderId = message.senderId;
    const text = message.text;

    const chatSnap = await admin.firestore().doc(`chats/${chatId}`).get();
    const chat = chatSnap.data();
    if (!chat) return;

    const recipientUid = chat.participants.find(p => p !== senderId);
    if (!recipientUid) return;

    const senderSnap = await admin.firestore().doc(`users/${senderId}`).get();
    const senderName = senderSnap.data()?.name || 'Someone';

    const recipientSnap = await admin.firestore().doc(`users/${recipientUid}`).get();
    const pushToken = recipientSnap.data()?.pushToken;
    if (!pushToken) {
      console.log('No FCM token for recipient', recipientUid);
      return;
    }

    const displayText = text ||
      (message.type === 'image' ? '📷 Photo' :
       message.type === 'sticker' ? '📦 Sticker' :
       message.type === 'audio' ? '🎤 Voice message' : '');

    try {
      await admin.messaging().send({
        token: pushToken,
        notification: {
          title: senderName,
          body: displayText,
        },
        data: {
          chatId,
          senderId,
        },
      });
      console.log('FCM sent to', recipientUid);
    } catch (e) {
      console.error('FCM send failed', e);
    }
  }
);

exports.sendPostNotification = onDocumentCreated(
  'posts/{postId}',
  async (event) => {
    const post = event.data?.data();
    if (!post) return;

    const { postId } = event.params;
    const authorId = post.authorId;
    const authorName = post.authorName || 'Someone';
    const title = post.title || 'New journal entry';
    const body = title;

    try {
      const usersSnap = await admin.firestore().collection('users').get();
      const tokens = [];
      for (const doc of usersSnap.docs) {
        if (doc.id === authorId) continue;
        const token = doc.data().pushToken;
        if (token) tokens.push(token);
      }
      if (tokens.length === 0) return;

      const messages = tokens.map((token) => ({
        token,
        notification: { title: authorName, body },
        data: { type: 'post', postId },
      }));
      const response = await admin.messaging().sendEach(messages);
      console.log(`Post notification sent to ${response.successCount} users`);
    } catch (e) {
      console.error('Post notification failed', e);
    }
  }
);

exports.sendChallengeNotification = onDocumentCreated(
  'challenges/{challengeId}',
  async (event) => {
    const challenge = event.data?.data();
    if (!challenge) return;

    const { challengeId } = event.params;
    const participants = challenge.participants || [];
    const title = challenge.title || 'New challenge';
    const creatorId = challenge.createdBy;

    try {
      for (const uid of participants) {
        if (uid === creatorId) continue;
        const token = await getUserPushToken(uid);
        if (!token) continue;

        await sendFCMMessage(
          token,
          'New Challenge',
          title,
          { type: 'challenge', challengeId }
        );
      }
      console.log('Challenge notifications sent');
    } catch (e) {
      console.error('Challenge notification failed', e);
    }
  }
);

exports.sendCommentNotification = onDocumentCreated(
  'posts/{postId}/comments/{commentId}',
  async (event) => {
    const comment = event.data?.data();
    if (!comment) return;

    const { postId } = event.params;
    const commentAuthorId = comment.authorId;
    const commentAuthorName = comment.authorName || 'Someone';

    try {
      const postSnap = await admin.firestore().doc(`posts/${postId}`).get();
      const post = postSnap.data();
      if (!post) return;

      const postAuthorId = post.authorId;
      if (commentAuthorId === postAuthorId) return;

      const token = await getUserPushToken(postAuthorId);
      if (!token) return;

      await sendFCMMessage(
        token,
        commentAuthorName,
        'commented on your post',
        { type: 'post', postId }
      );
      console.log('Comment notification sent');
    } catch (e) {
      console.error('Comment notification failed', e);
    }
  }
);
