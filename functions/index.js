const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');
admin.initializeApp();

const onesignalAppId = '7f9abadb-2c15-4019-80c6-a6d2393dc282';

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
      console.log('No pushToken for recipient', recipientUid);
      return;
    }

    const apiKey = process.env.ONESIGNAL_REST_KEY;
    if (!apiKey) {
      console.log('ONESIGNAL_REST_KEY not set');
      return;
    }

    const payload = {
      app_id: onesignalAppId,
      target_channel: 'push',
      include_subscription_ids: [pushToken],
      headings: { en: senderName },
      contents: { en: text },
      data: { chatId, senderId },
    };

    try {
      const response = await fetch('https://api.onesignal.com/notifications', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          Authorization: `Key ${apiKey}`,
        },
        body: JSON.stringify(payload),
      });
      const result = await response.json();
      console.log('OneSignal send result:', JSON.stringify(result));
    } catch (e) {
      console.error('OneSignal send failed', e);
    }
  }
);
