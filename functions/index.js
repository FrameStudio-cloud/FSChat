const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');
admin.initializeApp();

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
