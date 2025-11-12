# Firebase Security Rules - Deployment Guide

## Overview

This project includes comprehensive Firebase security rules for:
- **Firestore** - Database security rules
- **Firebase Storage** - File upload/download security rules

## Files Created

1. **`firestore.rules`** - Firestore security rules
2. **`storage.rules`** - Firebase Storage security rules
3. **`firebase.json`** - Updated to include rules configuration

## Security Rules Summary

### Firestore Rules

#### Users Collection (`/users/{userId}`)
- ✅ Read: Own document or admin
- ✅ Create: Own document only
- ✅ Update: Own document or admin
- ✅ Delete: Admin only

#### Deliveries Collection (`/deliveries/{deliveryId}`)
- ✅ Read: Admin, assigned driver, or pending deliveries
- ✅ Create: Admin or pharmacy users
- ✅ Update: Admin or assigned driver (for status updates, photos, signatures)
- ✅ Delete: Admin only

#### Notifications (`/notifications/{userId}/messages/{messageId}`)
- ✅ Read: Own notifications only
- ✅ Create: Admin or system
- ✅ Update: Own notifications (mark as read)
- ✅ Delete: Own notifications

#### Conversations (`/conversations/{conversationId}`)
- ✅ Read: Participants or admin
- ✅ Create: Authenticated users
- ✅ Update: Participants or admin
- ✅ Delete: Admin only

### Storage Rules

#### Driver Documents (`/drivers/{userId}/documents/{fileName}`)
- ✅ Read: Own documents or admin
- ✅ Write: Own folder, approved/active drivers only
- ✅ File size limit: 10MB
- ✅ Allowed types: PDF, images

#### Delivery Photos (`/deliveries/{deliveryId}/photos/{fileName}`)
- ✅ Read: Admin or assigned driver
- ✅ Write: Assigned driver, approved/active only
- ✅ File size limit: 5MB
- ✅ Allowed types: Images only

#### Signatures (`/signatures/{deliveryId}/{fileName}`)
- ✅ Read: Admin or assigned driver
- ✅ Write: Assigned driver, approved/active only
- ✅ File size limit: 1MB
- ✅ Allowed types: PNG only

#### Profile Images (`/profiles/{userId}/{fileName}`)
- ✅ Read: All authenticated users
- ✅ Write: Own profile only
- ✅ File size limit: 2MB
- ✅ Allowed types: Images only

## Prerequisites

1. **Install Firebase CLI**:
   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**:
   ```bash
   firebase login
   ```

3. **Initialize Firebase in project** (if not already done):
   ```bash
   firebase init
   ```
   Select:
   - Firestore
   - Storage
   - Use existing project: `concept-illustrated-mvp`

## Deployment Steps

### Option 1: Deploy All Rules

```bash
firebase deploy --only firestore:rules,storage
```

### Option 2: Deploy Rules Separately

**Deploy Firestore rules:**
```bash
firebase deploy --only firestore:rules
```

**Deploy Storage rules:**
```bash
firebase deploy --only storage
```

### Option 3: Deploy Everything

```bash
firebase deploy
```

## Testing Rules

### Test Firestore Rules Locally

1. **Start Firestore emulator:**
   ```bash
   firebase emulators:start --only firestore
   ```

2. **Test with Firebase Rules Unit Testing:**
   ```bash
   npm install -g @firebase/rules-unit-testing
   ```

### Test Storage Rules Locally

1. **Start Storage emulator:**
   ```bash
   firebase emulators:start --only storage
   ```

## Important Notes

### Security Considerations

1. **User Approval**: Rules check `isApproved` and `isActive` flags before allowing driver operations
2. **File Size Limits**: Enforced to prevent abuse
3. **File Type Validation**: Only allowed file types can be uploaded
4. **Ownership Validation**: Users can only access their own resources
5. **Role-Based Access**: Admin users have elevated permissions

### Rule Dependencies

- Storage rules depend on Firestore to check user roles and delivery assignments
- Make sure Firestore rules are deployed first if deploying separately

### Common Issues

1. **"Permission denied" errors**: 
   - Check if user is authenticated
   - Verify user role in Firestore
   - Ensure user is approved and active
   - Check if user owns the resource

2. **Storage upload fails**:
   - Verify file size is within limits
   - Check file type is allowed
   - Ensure user is assigned driver for delivery-related uploads

3. **Firestore read fails**:
   - Check if user has permission to read the document
   - Verify user role and approval status

## Verification

After deployment, verify rules are active:

1. **Check Firestore rules:**
   - Go to Firebase Console → Firestore Database → Rules
   - Verify rules match your `firestore.rules` file

2. **Check Storage rules:**
   - Go to Firebase Console → Storage → Rules
   - Verify rules match your `storage.rules` file

## Rollback

If you need to rollback rules:

```bash
# View deployment history
firebase deploy:list

# Rollback to previous version
firebase deploy:rollback
```

## Support

For issues or questions:
1. Check Firebase Console for error logs
2. Review rule syntax in Firebase documentation
3. Test rules locally using emulators

