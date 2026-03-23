// Firebase Cloud Functions for GeoGuard Multi-Tenant
// 
// SETUP:
// 1. Install Firebase CLI: npm install -g firebase-tools
// 2. Run: firebase init functions
// 3. Copy this code to functions/index.js
// 4. Run: firebase deploy --only functions

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// ========== SET CUSTOM CLAIMS ON USER CREATION ==========
// This function runs automatically when a user document is created
// It sets custom claims on the Firebase Auth token for use in security rules

exports.setUserClaims = functions.firestore
  .document('users/{userId}')
  .onCreate(async (snap, context) => {
    const userId = context.params.userId;
    const userData = snap.data();
    
    try {
      // Set custom claims
      await admin.auth().setCustomUserClaims(userId, {
        tenantId: userData.tenantId,
        role: userData.role
      });
      
      console.log(`Custom claims set for user ${userId}: tenantId=${userData.tenantId}, role=${userData.role}`);
      
      // Update user document to indicate claims have been set
      await snap.ref.update({
        claimsSet: true,
        claimsSetAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      return null;
    } catch (error) {
      console.error('Error setting custom claims:', error);
      throw error;
    }
  });

// ========== UPDATE CUSTOM CLAIMS ON USER ROLE CHANGE ==========
// This function runs when a user's role or tenant changes

exports.updateUserClaims = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const userId = context.params.userId;
    const beforeData = change.before.data();
    const afterData = change.after.data();
    
    // Check if role or tenantId changed
    if (beforeData.role !== afterData.role || beforeData.tenantId !== afterData.tenantId) {
      try {
        await admin.auth().setCustomUserClaims(userId, {
          tenantId: afterData.tenantId,
          role: afterData.role
        });
        
        console.log(`Custom claims updated for user ${userId}`);
        
        // Update user document
        await change.after.ref.update({
          claimsSet: true,
          claimsSetAt: admin.firestore.FieldValue.serverTimestamp()
        });
        
        return null;
      } catch (error) {
        console.error('Error updating custom claims:', error);
        throw error;
      }
    }
    
    return null;
  });

// ========== CLEAN UP EXPIRED INVITATIONS ==========
// Scheduled function to run daily at 2 AM UTC

exports.cleanupExpiredInvitations = functions.pubsub
  .schedule('0 2 * * *')  // Cron: 2 AM every day
  .timeZone('UTC')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const db = admin.firestore();
    
    try {
      // Find expired invitations
      const expiredInvitations = await db.collection('invitations')
        .where('expiresAt', '<', now)
        .where('isUsed', '==', false)
        .get();
      
      // Delete them
      const batch = db.batch();
      expiredInvitations.forEach(doc => {
        batch.delete(doc.ref);
      });
      
      await batch.commit();
      
      console.log(`Deleted ${expiredInvitations.size} expired invitations`);
      return null;
    } catch (error) {
      console.error('Error cleaning up invitations:', error);
      throw error;
    }
  });

// ========== VALIDATE TENANT USER LIMIT ==========
// Called before adding a new user to ensure tenant hasn't exceeded limit

exports.checkTenantUserLimit = functions.https.onCall(async (data, context) => {
  // Ensure user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  
  const { tenantId } = data;
  const db = admin.firestore();
  
  try {
    // Get tenant
    const tenantDoc = await db.collection('tenants').doc(tenantId).get();
    if (!tenantDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Tenant not found');
    }
    
    const tenant = tenantDoc.data();
    
    // Count active users
    const usersSnapshot = await db.collection('users')
      .where('tenantId', '==', tenantId)
      .where('isActive', '==', true)
      .get();
    
    const currentUserCount = usersSnapshot.size;
    const canAddUser = currentUserCount < tenant.maxUsers;
    
    return {
      canAddUser,
      currentUserCount,
      maxUsers: tenant.maxUsers,
      subscription: tenant.subscription
    };
  } catch (error) {
    console.error('Error checking tenant user limit:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// ========== SEND INVITATION EMAIL ==========
// Called when an invitation is created

exports.sendInvitationEmail = functions.firestore
  .document('invitations/{invitationId}')
  .onCreate(async (snap, context) => {
    const invitation = snap.data();
    const db = admin.firestore();
    
    // Skip if no email specified
    if (!invitation.email) {
      return null;
    }
    
    try {
      // Get tenant info
      const tenantDoc = await db.collection('tenants').doc(invitation.tenantId).get();
      const tenant = tenantDoc.data();
      
      // Get inviter info
      const inviterDoc = await db.collection('users').doc(invitation.invitedBy).get();
      const inviter = inviterDoc.data();
      
      // TODO: Integrate with email service (SendGrid, Mailgun, etc.)
      // For now, just log
      console.log('Send invitation email:');
      console.log(`To: ${invitation.email}`);
      console.log(`From: ${tenant.name}`);
      console.log(`Inviter: ${inviter.fullName}`);
      console.log(`Code: ${invitation.invitationCode}`);
      console.log(`Role: ${invitation.role}`);
      
      // Example email content:
      const emailContent = {
        to: invitation.email,
        subject: `You're invited to join ${tenant.name} on GeoGuard`,
        text: `
Hello!

${inviter.fullName} has invited you to join ${tenant.name} on GeoGuard.

Your invitation code: ${invitation.invitationCode}

This code expires on ${invitation.expiresAt.toDate().toLocaleDateString()}.

To accept this invitation:
1. Download the GeoGuard app
2. Go to Sign Up
3. Enter your invitation code
4. Complete your profile

You'll be joining as a ${invitation.role}.

Welcome to the team!
        `,
        html: `
<!DOCTYPE html>
<html>
<body>
  <h2>You're invited to join ${tenant.name}!</h2>
  <p>${inviter.fullName} has invited you to join their team on GeoGuard.</p>
  <div style="background: #f0f0f0; padding: 20px; margin: 20px 0; border-radius: 5px;">
    <h3 style="margin: 0;">Your Invitation Code:</h3>
    <p style="font-size: 24px; font-weight: bold; color: #0066cc; margin: 10px 0;">
      ${invitation.invitationCode}
    </p>
  </div>
  <p>This code expires on <strong>${invitation.expiresAt.toDate().toLocaleDateString()}</strong>.</p>
  <h4>To accept this invitation:</h4>
  <ol>
    <li>Download the GeoGuard app</li>
    <li>Go to Sign Up</li>
    <li>Enter your invitation code</li>
    <li>Complete your profile</li>
  </ol>
  <p>You'll be joining as a <strong>${invitation.role}</strong>.</p>
  <p>Welcome to the team!</p>
</body>
</html>
        `
      };
      
      // TODO: Actually send email using your chosen service
      // await sendEmailService.send(emailContent);
      
      return null;
    } catch (error) {
      console.error('Error sending invitation email:', error);
      // Don't throw - this is not critical
      return null;
    }
  });

// ========== LOG TENANT ACTIVITY ==========
// Logs important tenant events for analytics

exports.logTenantActivity = functions.firestore
  .document('users/{userId}')
  .onCreate(async (snap, context) => {
    const userData = snap.data();
    const db = admin.firestore();
    
    try {
      // Log user signup event
      await db.collection('tenant_activity_logs').add({
        tenantId: userData.tenantId,
        eventType: 'user_signup',
        userId: context.params.userId,
        userEmail: userData.email,
        userRole: userData.role,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        metadata: {
          invitationCode: userData.invitationCode || null,
          invitedBy: userData.invitedBy || null
        }
      });
      
      console.log(`Logged signup event for tenant ${userData.tenantId}`);
      return null;
    } catch (error) {
      console.error('Error logging activity:', error);
      return null;
    }
  });

// ========== GET TENANT ANALYTICS ==========
// Callable function to get tenant statistics

exports.getTenantAnalytics = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  
  const db = admin.firestore();
  const userId = context.auth.uid;
  
  try {
    // Get user's tenant
    const userDoc = await db.collection('users').doc(userId).get();
    const user = userDoc.data();
    
    // Verify user is admin or super_admin
    if (user.role !== 'admin' && user.role !== 'super_admin') {
      throw new functions.https.HttpsError('permission-denied', 'Only admins can view analytics');
    }
    
    const tenantId = user.tenantId;
    
    // Get counts
    const [usersSnapshot, geofencesSnapshot, activeInvitations] = await Promise.all([
      db.collection('users').where('tenantId', '==', tenantId).get(),
      db.collection('geofences').where('tenantId', '==', tenantId).get(),
      db.collection('invitations')
        .where('tenantId', '==', tenantId)
        .where('isUsed', '==', false)
        .get()
    ]);
    
    // Count by role
    const roleCount = {};
    usersSnapshot.forEach(doc => {
      const role = doc.data().role;
      roleCount[role] = (roleCount[role] || 0) + 1;
    });
    
    return {
      totalUsers: usersSnapshot.size,
      totalGeofences: geofencesSnapshot.size,
      activeInvitations: activeInvitations.size,
      usersByRole: roleCount
    };
  } catch (error) {
    console.error('Error getting tenant analytics:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});
