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
 * Triggered when a new settlement request is created.
 * Sends a notification to the receiver.
 */
exports.sendSettlementRequestNotification = functions.firestore
    .document("settlement_requests/{requestId}")
    .onCreate(async (snap, context) => {
        const data = snap.data();
        const senderUid = data.senderUid;
        const receiverUid = data.receiverUid;
        const amount = data.amount;
        const currency = data.currency || "₺";

        console.log(`[SettlementRequest] Id: ${context.params.requestId} From: ${senderUid} To: ${receiverUid}`);

        if (!receiverUid) return null;

        try {
            // 1. Get Sender Info (Name)
            let senderName = "Partner";
            if (senderUid) {
                const senderDoc = await admin.firestore().collection("users").doc(senderUid).get();
                if (senderDoc.exists) {
                    const userData = senderDoc.data();
                    if (userData.displayName) {
                        senderName = userData.displayName;
                    }
                }
            }

            // 2. Get Receiver Token
            const targetDoc = await admin.firestore().collection("users").doc(receiverUid).get();
            if (!targetDoc.exists) {
                console.log(`[SettlementRequest] Target user not found: ${receiverUid}`);
                return null;
            }

            const fcmToken = targetDoc.data().fcmToken;
            if (!fcmToken) {
                console.log(`[SettlementRequest] No FCM token for target: ${receiverUid}`);
                return null;
            }

            const message = {
                notification: {
                    title: "Settle Up Request",
                    body: `${senderName} wants to settle ${amount}${currency}. Tap to respond.`,
                },
                data: {
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                    type: "settlement_request",
                    requestId: context.params.requestId,
                    senderName: senderName,
                },
                token: fcmToken,
            };

            const response = await admin.messaging().send(message);
            console.log("[SettlementRequest] Notification sent:", response);
            return response;

        } catch (error) {
            console.error("[SettlementRequest] Error sending notification:", error);
            return null;
        }
    });

/**
 * Triggered when a settlement request is updated (e.g. Rejected).
 * Sends a notification to the sender.
 */
exports.sendSettlementUpdateNotification = functions.firestore
    .document("settlement_requests/{requestId}")
    .onUpdate(async (change, context) => {
        const newData = change.after.data();
        const oldData = change.before.data();
        const status = newData.status;

        // Only flow: status changed to REJECTED
        // Note: COMPLETED is handled by 'sendSettlementNotification' via the new settlement doc.
        if (status !== "REJECTED" || oldData.status === "REJECTED") {
            return null;
        }

        const senderUid = newData.senderUid;
        const receiverUid = newData.receiverUid;

        console.log(`[SettlementUpdate] Id: ${context.params.requestId} Status: ${status}`);

        // Notify the SENDER (the person who made the request)
        const targetUid = senderUid;
        const deciderUid = receiverUid;

        if (!targetUid) return null;

        try {
            // 1. Get Decider Info (Name)
            let deciderName = "Partner";
            if (deciderUid) {
                const userDoc = await admin.firestore().collection("users").doc(deciderUid).get();
                if (userDoc.exists) {
                    const userData = userDoc.data();
                    if (userData.displayName) {
                        deciderName = userData.displayName;
                    }
                }
            }

            // 2. Get Target Token (Sender)
            const targetDoc = await admin.firestore().collection("users").doc(targetUid).get();
            if (!targetDoc.exists) {
                console.log(`[SettlementUpdate] Target user not found: ${targetUid}`);
                return null;
            }

            const fcmToken = targetDoc.data().fcmToken;
            if (!fcmToken) {
                console.log(`[SettlementUpdate] No FCM token for target: ${targetUid}`);
                return null;
            }

            const message = {
                notification: {
                    title: "Settlement Declined",
                    body: `${deciderName} declined your settlement request.`,
                },
                data: {
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                    type: "settlement_update",
                    requestId: context.params.requestId,
                    status: status,
                },
                token: fcmToken,
            };

            const response = await admin.messaging().send(message);
            console.log("[SettlementUpdate] Notification sent:", response);
            return response;

        } catch (error) {
            console.error("[SettlementUpdate] Error sending notification:", error);
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
        const bulkWriter = db.bulkWriter();

        // 0. Remove user from partners' lists
        const userDocRef = db.collection("users").doc(uid);
        const userDoc = await userDocRef.get();

        if (userDoc.exists) {
            const userData = userDoc.data();
            const partnerUids = userData.partnerUids || [];

            partnerUids.forEach((partnerUid) => {
                const partnerRef = db.collection("users").doc(partnerUid);
                bulkWriter.update(partnerRef, {
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

        // 4. Settlement Requests
        const settReqSenderRefs = await collectRefs(db.collection("settlement_requests").where("senderUid", "==", uid));
        const settReqReceiverRefs = await collectRefs(db.collection("settlement_requests").where("receiverUid", "==", uid));

        // Deduplicate refs and queue deletions
        const allRefs = [
            ...txSenderRefs, ...txReceiverRefs,
            ...settlementPayerRefs, ...settlementReceiverRefs,
            ...reqFromRefs, ...reqToRefs,
            ...settReqSenderRefs, ...settReqReceiverRefs
        ];

        const uniqueRefPaths = new Set();

        allRefs.forEach((ref) => {
            if (!uniqueRefPaths.has(ref.path)) {
                uniqueRefPaths.add(ref.path);
                bulkWriter.delete(ref);
            }
        });

        // 5. Delete User Document
        bulkWriter.delete(db.collection("users").doc(uid));

        console.log(`[DeleteAccount] Deleting ${uniqueRefPaths.size + 1} documents for user ${uid}`);

        await bulkWriter.close();

        // 6. Delete Auth Account
        await admin.auth().deleteUser(uid);

        console.log(`[DeleteAccount] Successfully deleted account for ${uid}`);
        return { success: true };

    } catch (error) {
        console.error("[DeleteAccount] Error deleting account:", error);
        // Return the error message to the client for better debugging
        throw new functions.https.HttpsError("internal", `Unable to delete account: ${error.message}`);
    }
});

/**
 * Callable function to confirm (or reject) a settlement request.
 * Moves the entire settlement logic server-side to prevent TOCTOU attacks
 * and ensure atomicity.
 *
 * data.requestId — the settlement request document ID
 * data.response  — true to confirm, false to reject
 */
exports.confirmSettlement = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Must be authenticated."
        );
    }

    const callerUid = context.auth.uid;
    const requestId = data.requestId;
    const response = data.response; // true = confirm, false = reject

    if (!requestId || typeof requestId !== "string") {
        throw new functions.https.HttpsError("invalid-argument", "requestId is required.");
    }
    if (typeof response !== "boolean") {
        throw new functions.https.HttpsError("invalid-argument", "response must be a boolean.");
    }

    const db = admin.firestore();
    const requestRef = db.collection("settlement_requests").doc(requestId);

    // --- Rejection: simple status update, no transaction needed ---
    if (!response) {
        const reqDoc = await requestRef.get();
        if (!reqDoc.exists) {
            throw new functions.https.HttpsError("not-found", "Settlement request not found.");
        }
        const reqData = reqDoc.data();

        // Only the receiver can reject
        if (reqData.receiverUid !== callerUid) {
            throw new functions.https.HttpsError("permission-denied", "Only the receiver can respond.");
        }
        if (reqData.status !== "PENDING") {
            throw new functions.https.HttpsError("failed-precondition", "Request is not PENDING.");
        }

        await requestRef.update({ status: "REJECTED" });
        console.log(`[ConfirmSettlement] Request ${requestId} rejected by ${callerUid}`);
        return { success: true, status: "REJECTED" };
    }

    // --- Confirmation: atomic server-side transaction ---
    try {
        await db.runTransaction(async (transaction) => {
            // 1. Read and validate the settlement request
            const requestSnapshot = await transaction.get(requestRef);
            if (!requestSnapshot.exists) {
                throw new functions.https.HttpsError("not-found", "Settlement request not found.");
            }

            const requestData = requestSnapshot.data();

            // Only the receiver can confirm
            if (requestData.receiverUid !== callerUid) {
                throw new functions.https.HttpsError("permission-denied", "Only the receiver can confirm.");
            }
            if (requestData.status !== "PENDING") {
                throw new functions.https.HttpsError("failed-precondition", "Request is not PENDING.");
            }

            const senderUid = requestData.senderUid;
            const receiverUid = requestData.receiverUid;

            let relevantDocs = [];

            if (requestData.transactionId) {
                // --- Single Transaction Settlement ---
                const txRef = db.collection("transactions").doc(requestData.transactionId);
                const txDoc = await transaction.get(txRef);

                if (!txDoc.exists) {
                    throw new functions.https.HttpsError("not-found", "Transaction does not exist.");
                }
                if (txDoc.data().isSettled === true) {
                    throw new functions.https.HttpsError("failed-precondition", "Transaction is already settled.");
                }

                relevantDocs = [{ ref: txRef, data: txDoc.data(), id: txDoc.id }];
            } else {
                // --- All Unsettled Transactions Settlement ---
                // Server-side: we can query freely with admin privileges
                const query1 = await db.collection("transactions")
                    .where("senderUid", "==", senderUid)
                    .where("receiverUid", "==", receiverUid)
                    .get();

                const query2 = await db.collection("transactions")
                    .where("senderUid", "==", receiverUid)
                    .where("receiverUid", "==", senderUid)
                    .get();

                const allDocs = [...query1.docs, ...query2.docs];

                // Deduplicate and filter unsettled
                const seenIds = new Set();
                for (const doc of allDocs) {
                    if (!seenIds.has(doc.id) && doc.data().isSettled !== true) {
                        seenIds.add(doc.id);
                        relevantDocs.push({ ref: doc.ref, data: doc.data(), id: doc.id });
                    }
                }
            }

            // 2. Create Settlement Document
            const settlementRef = db.collection("settlements").doc();

            // Find the earliest timestamp for startDate
            let startDate = admin.firestore.Timestamp.now();
            if (relevantDocs.length > 0) {
                const timestamps = relevantDocs
                    .map(d => d.data.timestamp)
                    .filter(t => t != null);
                if (timestamps.length > 0) {
                    timestamps.sort((a, b) => a.toMillis() - b.toMillis());
                    startDate = timestamps[0];
                }
            }

            const now = admin.firestore.Timestamp.now();
            const settlementData = {
                startDate: startDate,
                endDate: now,
                totalAmount: requestData.amount,
                payerUid: senderUid,
                receiverUid: receiverUid,
                transactionIds: relevantDocs.map(d => d.id),
                timestamp: now,
                settledByUid: receiverUid, // receiver confirmed it
            };

            // 3. Writes — all within the transaction
            transaction.set(settlementRef, settlementData);

            transaction.update(requestRef, { status: "COMPLETED" });

            for (const doc of relevantDocs) {
                transaction.update(doc.ref, {
                    isSettled: true,
                    settlementId: settlementRef.id,
                });
            }

            console.log(`[ConfirmSettlement] Settled ${relevantDocs.length} transactions. Settlement: ${settlementRef.id}`);
        });

        return { success: true, status: "COMPLETED" };

    } catch (error) {
        if (error instanceof functions.https.HttpsError) throw error;
        console.error("[ConfirmSettlement] Error:", error);
        throw new functions.https.HttpsError("internal", `Settlement failed: ${error.message}`);
    }
});

/**
 * Looks up a user by their partner ID.
 * Returns only minimal info (uid, displayName, email) — never FCM tokens or partnerUids.
 * This allows partner linking without the client needing read access to arbitrary user docs.
 */
exports.lookupPartnerByCode = functions.https.onCall(async (data, context) => {
    // Auth check
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Must be logged in.");
    }

    const partnerId = data.partnerId;
    if (!partnerId || typeof partnerId !== "string" || partnerId.trim().length === 0) {
        throw new functions.https.HttpsError("invalid-argument", "partnerId is required.");
    }

    const trimmed = partnerId.trim().toUpperCase();
    const db = admin.firestore();

    try {
        const snapshot = await db.collection("users")
            .where("partnerId", "==", trimmed)
            .limit(1)
            .get();

        if (snapshot.empty) {
            throw new functions.https.HttpsError("not-found", "No user found with that partner ID.");
        }

        const doc = snapshot.docs[0];
        return {
            uid: doc.id,
            displayName: doc.data().displayName || "",
            email: doc.data().email || "",
        };
    } catch (error) {
        if (error instanceof functions.https.HttpsError) throw error;
        console.error("[lookupPartnerByCode] Error:", error);
        throw new functions.https.HttpsError("internal", "Failed to look up partner.");
    }
});

/**
 * Generates a cryptographically random partner ID, ensures it's unique,
 * saves it to the caller's user document, and returns it.
 * If the user already has a partner ID, returns the existing one.
 */
exports.generateUniquePartnerId = functions.https.onCall(async (data, context) => {
    // Auth check
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Must be logged in.");
    }

    const uid = context.auth.uid;
    const crypto = require("crypto");
    const db = admin.firestore();

    try {
        // Check if user already has a partner ID
        const userDoc = await db.collection("users").doc(uid).get();
        if (!userDoc.exists) {
            throw new functions.https.HttpsError("not-found", "User document not found.");
        }

        const existing = userDoc.data().partnerId;
        if (existing) {
            return { partnerId: existing };
        }

        // Generate a unique partner ID using crypto-safe random bytes
        const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        let generatedId = null;
        let isUnique = false;
        let attempts = 0;
        const maxAttempts = 10;

        while (!isUnique && attempts < maxAttempts) {
            attempts++;
            // Generate 8 random characters, insert hyphen at position 4 → XXXX-XXXX
            const bytes = crypto.randomBytes(8);
            let id = "";
            for (let i = 0; i < 8; i++) {
                if (i === 4) id += "-";
                id += chars[bytes[i] % chars.length];
            }

            const existing = await db.collection("users")
                .where("partnerId", "==", id)
                .limit(1)
                .get();

            if (existing.empty) {
                generatedId = id;
                isUnique = true;
            }
        }

        if (!generatedId) {
            throw new functions.https.HttpsError("internal", "Failed to generate unique ID after max attempts.");
        }

        // Save to user document
        await db.collection("users").doc(uid).update({ partnerId: generatedId });

        return { partnerId: generatedId };
    } catch (error) {
        if (error instanceof functions.https.HttpsError) throw error;
        console.error("[generateUniquePartnerId] Error:", error);
        throw new functions.https.HttpsError("internal", "Failed to generate partner ID.");
    }
});
