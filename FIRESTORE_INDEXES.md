# Firestore Indexes - Setup Guide

## Overview

Firestore requires composite indexes for queries that filter on multiple fields and order by a different field. This project includes the necessary index definitions.

## Indexes Required

### 1. Delivered Deliveries Query
**Query**: Get delivered deliveries for a driver, ordered by delivery time
- Collection: `deliveries`
- Fields: `driverId` (ASC), `status` (ASC), `actualDeliveryTime` (DESC)

### 2. Active Deliveries Query
**Query**: Get active deliveries for a driver, ordered by status and createdAt
- Collection: `deliveries`
- Fields: `driverId` (ASC), `status` (ASC), `createdAt` (DESC)

## Deployment

### Option 1: Deploy Indexes via Firebase CLI

```bash
firebase deploy --only firestore:indexes
```

### Option 2: Deploy All Firestore Config

```bash
firebase deploy --only firestore
```

This will deploy both rules and indexes.

### Option 3: Create Index via Console

If you prefer to create indexes manually:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `concept-illustrated-mvp`
3. Go to **Firestore Database** → **Indexes**
4. Click **Create Index**
5. Use the URL provided in the error message (it's auto-generated)

## Index Creation Time

⚠️ **Important**: Index creation can take several minutes to complete. The app will show an error until the index is ready.

You can check index status in Firebase Console:
- **Firestore Database** → **Indexes** → Check status (Building/Enabled)

## Automatic Index Creation

Firebase will automatically suggest creating indexes when you run queries that need them. The error message includes a direct link to create the required index.

## Files

- `firestore.indexes.json` - Index definitions
- `firebase.json` - Configuration file (includes indexes reference)

## Verification

After deployment, verify indexes are created:

1. Go to Firebase Console → Firestore Database → Indexes
2. Verify all indexes show status: **Enabled** (green checkmark)

## Troubleshooting

### Error: "The query requires an index"

1. Check if index is still building (can take 5-10 minutes)
2. Verify `firestore.indexes.json` is correct
3. Deploy indexes: `firebase deploy --only firestore:indexes`
4. Check Firebase Console for index status

### Index Not Appearing

- Ensure `firebase.json` includes the indexes file reference
- Check that you're logged into the correct Firebase project
- Verify project ID matches: `concept-illustrated-mvp`


