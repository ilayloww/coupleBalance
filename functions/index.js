const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Triggered when a new transaction is created.
 * Sends a notification to the person who DID NOT add it.
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
        const addedByUid = newData.addedByUid;

        console.log(`[NewExpense] TxId: ${context.params.transactionId}`);
        console.log(`[NewExpense] Sender: ${senderUid}, Receiver: ${receiverUid}, AddedBy: ${addedByUid}`);

        // Logic: Notify the person who is NOT the creator.
        // If addedByUid exists, use it. If not, fallback to legacy assumption.
        // Legacy assumption: Ideally the one who created it IS the sender if not specified? 
        // But let's assume if addedByUid is missing, we notify receiverUid (safest fallback).
        let targetUid = receiverUid;
        if (addedByUid) {
            targetUid = (addedByUid === senderUid) ? receiverUid : senderUid;
        }

        if (!targetUid) {
            console.log("[NewExpense] No target UID found.");
            return null;
        }
        console.log(`[NewExpense] Target for notification: ${targetUid}`);

        try {
            // Get Creator Name
            const creatorUid = addedByUid || senderUid;
            const creatorDoc = await admin.firestore().collection("users").doc(creatorUid).get();
            const creatorName = creatorDoc.exists ? creatorDoc.data().displayName : "Partner";

            // Get Target Token
            const targetDoc = await admin.firestore().collection("users").doc(targetUid).get();
            if (!targetDoc.exists) {
                console.log(`[NewExpense] Target user doc not found: ${targetUid}`);
                return null;
            }

            const fcmToken = targetDoc.data().fcmToken;
            if (!fcmToken) {
                console.log(`[NewExpense] No FCM token for target: ${targetUid}`);
                return null;
            }

            const message = {
                notification: {
                    title: "New Expense Added",
                    body: `${creatorName} added ${amount}${currency} for you. Note: ${note}`,
                },
                data: {
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                    transactionId: context.params.transactionId,
                    type: "new_expense",
                },
                token: fcmToken,
            };

            const response = await admin.messaging().send(message);
            console.log("[NewExpense] Successfully sent messageId:", response);
            return response;

        } catch (error) {
            console.error("[NewExpense] Error sending notification:", error);
            return null;
        }
    });

/**
 * Triggered when a transaction is deleted.
 * Sends a notification to the person who DID NOT delete it.
 */
/**
 * Triggered when a transaction is updated (Soft Delete).
 * Sends notification and then deletes the document.
 */
exports.sendDeleteNotification = functions.firestore
    .document("transactions/{transactionId}")
    .onUpdate(async (change, context) => {
        const newData = change.after.data();
        const oldData = change.before.data();

        // Only flow: isDeleted changed from false/undefined to true
        if (!newData.isDeleted || oldData.isDeleted) {
            return null;
        }

        const senderUid = newData.senderUid;
        const receiverUid = newData.receiverUid;
        const deleterUid = newData.deletedBy; // Now explicit!

        console.log(`[SoftDelete] TxId: ${context.params.transactionId}`);
        console.log(`[SoftDelete] Deleter: ${deleterUid}, Sender: ${senderUid}, Receiver: ${receiverUid}`);

        // Notify the OTHER person
        let targetUid = receiverUid;
        if (deleterUid) {
            targetUid = (deleterUid === senderUid) ? receiverUid : senderUid;
        }

        try {
            // 1. Send Notification
            let deleterName = "Partner";
            if (deleterUid) {
                const userDoc = await admin.firestore().collection("users").doc(deleterUid).get();
                if (userDoc.exists) deleterName = userDoc.data().displayName;
            }

            const targetDoc = await admin.firestore().collection("users").doc(targetUid).get();
            if (targetDoc.exists) {
                const fcmToken = targetDoc.data().fcmToken;
                if (fcmToken) {
                    const message = {
                        notification: {
                            title: "Transaction Deleted",
                            body: `Transaction deleted by ${deleterName}. Your balance has been updated.`,
                        },
                        data: {
                            click_action: "FLUTTER_NOTIFICATION_CLICK",
                            type: "delete_expense",
                        },
                        token: fcmToken,
                    };
                    await admin.messaging().send(message);
                    console.log("[SoftDelete] Notification sent.");
                }
            }

            // 2. Actually Delete the Document
            await change.after.ref.delete();
            console.log("[SoftDelete] Document deleted.");
            return true;

        } catch (error) {
            console.error("[SoftDelete] Error:", error);
            return null;
        }
    });

/**
 * Triggered when a new settlement is created.
 * Sends a notification to the involved partner.
 */
exports.sendSettlementNotification = functions.firestore
    .document("settlements/{settlementId}")
    .onCreate(async (snap, context) => {
        const data = snap.data();
        const payerUid = data.payerUid;
        const receiverUid = data.receiverUid;
        const totalAmount = data.totalAmount;
        // Prefer 'settledByUid' field if available, else fallback to context.auth.uid
        const settlerUid = data.settledByUid || (context.auth ? context.auth.uid : null);

        console.log(`[Settlement] Id: ${context.params.settlementId}`);
        console.log(`[Settlement] Payer: ${payerUid}, Receiver: ${receiverUid}, Settler: ${settlerUid}`);

        // Notify the OTHER person
        let targetUid = receiverUid;
        if (settlerUid) {
            targetUid = (settlerUid === payerUid) ? receiverUid : payerUid;
        }

        console.log(`[Settlement] Target for notification: ${targetUid}`);

        try {
            let settlerName = "Partner";
            if (settlerUid) {
                const userDoc = await admin.firestore().collection("users").doc(settlerUid).get();
                if (userDoc.exists) settlerName = userDoc.data().displayName;
            }

            const targetDoc = await admin.firestore().collection("users").doc(targetUid).get();
            if (!targetDoc.exists) {
                console.log(`[Settlement] Target user doc not found: ${targetUid}`);
                return null;
            }

            const fcmToken = targetDoc.data().fcmToken;
            if (!fcmToken) {
                console.log(`[Settlement] No FCM token for target: ${targetUid}`);
                return null;
            }

            const message = {
                notification: {
                    title: "Settled Up!",
                    body: `${settlerName} marked ${totalAmount}₺ as settled. You are all caught up!`,
                },
                data: {
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                    type: "settlement",
                },
                token: fcmToken,
            };

            const response = await admin.messaging().send(message);
            console.log("[Settlement] Successfully sent messageId:", response);
            return response;

        } catch (error) {
            console.error("[Settlement] Error sending notification:", error);
            return null;
        }
    });

/**
 * Triggered when a new friend request is created.
 * Sends a notification to the recipient.
 */
exports.sendPartnerRequestNotification = functions.firestore
    .document("friend_requests/{requestId}")
    .onCreate(async (snap, context) => {
        const data = snap.data();
        const fromUid = data.fromUid;
        const fromEmail = data.fromEmail || "(No Email)";
        const toUid = data.toUid;

        console.log(`[FriendRequest] Id: ${context.params.requestId} From: ${fromUid} To: ${toUid}`);

        if (!toUid) return null;

        try {
            // 1. Get Sender Info (Name)
            let fromName = "Someone";
            if (fromUid) {
                const senderDoc = await admin.firestore().collection("users").doc(fromUid).get();
                if (senderDoc.exists) {
                    const userData = senderDoc.data();
                    if (userData.displayName) {
                        fromName = userData.displayName;
                    }
                }
            }

            // 2. Get Target Info (Token)
            const targetDoc = await admin.firestore().collection("users").doc(toUid).get();
            if (!targetDoc.exists) {
                console.log(`[FriendRequest] Target user not found: ${toUid}`);
                return null;
            }

            const fcmToken = targetDoc.data().fcmToken;
            if (!fcmToken) {
                console.log(`[FriendRequest] No FCM token for target: ${toUid}`);
                return null;
            }

            const message = {
                notification: {
                    title: "New Partner Request",
                    body: `${fromName} (${fromEmail}) wants to link with you.`,
                },
                data: {
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                    type: "friend_request",
                },
                token: fcmToken,
            };

            const response = await admin.messaging().send(message);
            console.log("[FriendRequest] Notification sent:", response);
            return response;

        } catch (error) {
            console.error("[FriendRequest] Error sending notification:", error);
            return null;
        }
    });

/**
 * Callable function to delete a user account and all associated data.
 * MUST be called from the app after re-authentication.
 */
exports.deleteAccount = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "The function must be called while authenticated."
        );
    }

    const uid = context.auth.uid;
    console.log(`[DeleteAccount] Starting deletion for user: ${uid}`);

    try {
        const db = admin.firestore();
        const batch = db.batch();

        // 0. Remove user from partners' lists
        const userDocRef = db.collection("users").doc(uid);
        const userDoc = await userDocRef.get();

        if (userDoc.exists) {
            const userData = userDoc.data();
            const partnerUids = userData.partnerUids || [];

            partnerUids.forEach((partnerUid) => {
                const partnerRef = db.collection("users").doc(partnerUid);
                batch.update(partnerRef, {
                    partnerUids: admin.firestore.FieldValue.arrayRemove(uid)
                });
            });
            console.log(`[DeleteAccount] Removing user ${uid} from ${partnerUids.length} partners.`);
        }

        // Helper to collect references from a query
        const collectRefs = async (query) => {
            const snapshot = await query.get();
            return snapshot.docs.map((doc) => doc.ref);
        };

        // 1. Transactions
        const txSenderRefs = await collectRefs(db.collection("transactions").where("senderUid", "==", uid));
        const txReceiverRefs = await collectRefs(db.collection("transactions").where("receiverUid", "==", uid));

        // 2. Settlements
        const settlementPayerRefs = await collectRefs(db.collection("settlements").where("payerUid", "==", uid));
        const settlementReceiverRefs = await collectRefs(db.collection("settlements").where("receiverUid", "==", uid));

        // 3. Friend Requests
        const reqFromRefs = await collectRefs(db.collection("friend_requests").where("fromUid", "==", uid));
        const reqToRefs = await collectRefs(db.collection("friend_requests").where("toUid", "==", uid));

        // deduplicate refs just in case (though unlikely to overlap in this schema)
        const allRefs = [
            ...txSenderRefs, ...txReceiverRefs,
            ...settlementPayerRefs, ...settlementReceiverRefs,
            ...reqFromRefs, ...reqToRefs
        ];

        // Use a Set of paths to ensure uniqueness
        const uniqueRefPaths = new Set();

        allRefs.forEach((ref) => {
            if (!uniqueRefPaths.has(ref.path)) {
                uniqueRefPaths.add(ref.path);
                batch.delete(ref);
            }
        });

        // 4. Delete User Data
        const userRef = db.collection("users").doc(uid);
        batch.delete(userRef);

        console.log(`[DeleteAccount] Deleting ${uniqueRefPaths.size} documents for user ${uid}`);

        await batch.commit();

        // 5. Delete Auth Account
        await admin.auth().deleteUser(uid);

        console.log(`[DeleteAccount] Successfully deleted account for ${uid}`);
        return { success: true };

    } catch (error) {
        console.error("[DeleteAccount] Error deleting account:", error);
        // Return the error message to the client for better debugging
        throw new functions.https.HttpsError("internal", `Unable to delete account: ${error.message}`);
    }
});
