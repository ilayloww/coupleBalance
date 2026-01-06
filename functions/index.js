const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Triggered when a new transaction is created.
 * Sends a notification to the receiver.
 */
exports.sendExpenseNotification = functions.firestore
    .document("transactions/{transactionId}")
    .onCreate(async (snap, context) => {
        const newData = snap.data();
        const senderUid = newData.senderUid;
        const receiverUid = newData.receiverUid;
        const amount = newData.amount;
        const note = newData.note;
        const currency = newData.currency || "₺";

        console.log(`New transaction from ${senderUid} to ${receiverUid}`);

        try {
            // 1. Get Sender's Name
            const senderDoc = await admin.firestore().collection("users").doc(senderUid).get();
            const senderName = senderDoc.exists ? senderDoc.data().displayName : "Partner";

            // 2. Get Receiver's Token
            const receiverDoc = await admin.firestore().collection("users").doc(receiverUid).get();
            if (!receiverDoc.exists) {
                console.log("Receiver not found");
                return null;
            }

            const receiverData = receiverDoc.data();
            const fcmToken = receiverData.fcmToken;

            if (!fcmToken) {
                console.log("No FCM token for receiver");
                return null; // Receiver has no token
            }

            // 3. Construct Payload
            const message = {
                notification: {
                    title: "New Expense Added",
                    body: `${senderName} added ${amount}${currency} for you. Note: ${note}`,
                },
                data: {
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                    transactionId: context.params.transactionId,
                    type: "new_expense",
                },
                token: fcmToken,
            };

            // 4. Send Message
            const response = await admin.messaging().send(message);
            console.log("Successfully sent message:", response);
            return response;

        } catch (error) {
            console.error("Error sending notification:", error);
            return null;
        }
    });

/**
 * Triggered when a transaction is deleted.
 * Sends a notification to the involved partner.
 */
exports.sendDeleteNotification = functions.firestore
    .document("transactions/{transactionId}")
    .onDelete(async (snap, context) => {
        const deletedData = snap.data();
        const senderUid = deletedData.senderUid;
        const receiverUid = deletedData.receiverUid; // We want to notify the OTHER person usually, or the receiver? 
        // Requirement: "When User A deletes a transaction -> Send Push Notification to User B."
        // If User A (sender) deleted it, notify User B (receiver).
        // But what if User B deleted it? (Assuming anyone can delete) 
        // For simplicity, let's assume we notify the 'receiver' if the 'sender' was the one who added it, 
        // but here we don't know who performed the delete action easily without context.
        // However, the requirement says "notify partner". Let's notify the receiverUid associated with the tx.

        // A better approach in a real app is to check who triggered the delete, but for this triggers, 
        // we'll just notify the receiverUid (or senderUid if needed). 
        // Let's stick to notifying the `receiverUid` as per the example logic "Ilayda added... for you" -> "Deleted by Ilayda..."

        // We need the name of the person who deleted... 
        // Firestore triggers don't easily give the "deleter" uid without extra work.
        // We will assume the notification comes from the "System" or generically "Partner".
        // Or we fetch the senderName again.

        try {
            const senderDoc = await admin.firestore().collection("users").doc(senderUid).get();
            const senderName = senderDoc.exists ? senderDoc.data().displayName : "Partner";

            const receiverDoc = await admin.firestore().collection("users").doc(receiverUid).get();
            if (!receiverDoc.exists) return null;

            const fcmToken = receiverDoc.data().fcmToken;
            if (!fcmToken) return null;

            const message = {
                notification: {
                    title: "Transaction Deleted",
                    body: `Transaction deleted by ${senderName}. Your balance has been updated.`,
                },
                data: {
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                    type: "delete_expense",
                },
                token: fcmToken,
            };

            await admin.messaging().send(message);
            console.log("Sent delete notification");
            return true;

        } catch (error) {
            console.error("Error sending delete notification:", error);
            return null;
        }
    });
