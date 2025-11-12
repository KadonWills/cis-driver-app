# Concept Illustrated Services - Driver Mobile App - Complete Development Prompt

## Project Overview

Create a Flutter mobile application (iOS and Android) for delivery drivers in a UK healthcare delivery management platform. The app enables drivers to manage deliveries, navigate routes, track earnings, and communicate with customers in real-time. Design should be as in the 3 screens in the attached image reference.

**Theme**: Black and white color scheme with royal blue (#4169E1 or similar) as the primary accent color.

Icons: USe HugeIcons for all icons where possible.

---

## Design System & Theme

### Color Palette
- **Primary Background**: Pure white (#FFFFFF)
- **Secondary Background**: Light gray (#F5F5F5 or #FAFAFA)
- **Text Primary**: Black (#000000 or #1A1A1A)
- **Text Secondary**: Dark gray (#666666 or #4A4A4A)
- **Accent Color**: Royal Blue (#4169E1 or #1E40AF)
- **Accent Light**: Light royal blue tint for backgrounds (#E6F0FF)
- **Borders**: Light gray (#E5E5E5 or #D3D3D3)
- **Status Colors** (use sparingly, primarily royal blue variants):
  - Success: Royal blue (#4169E1)
  - Warning: Dark gray (#666666)
  - Error: Dark red (#8B0000)

### Typography
- **Primary Font**: System default (SF Pro for iOS, Roboto for Android)
- **Headings**: Bold, 18-24pt
- **Body Text**: Regular, 14-16pt
- **Labels**: Medium weight, 12-14pt
- **Monospace**: For delivery IDs and codes

### UI Components
- **Cards**: White background, subtle shadow, rounded corners (12-16px)
- **Buttons**: 
  - Primary: Royal blue background, white text
  - Secondary: White background, royal blue border and text
  - Swipe actions: Full-width with royal blue accent
- **Icons**: Black with royal blue accents for active states
- **Status Badges**: White background, royal blue border, royal blue text

---

## Screen 1: Delivery Details Screen

### Layout Structure

**Top Information Bar** (White background, below status bar)
- Distance: "0 mile" (or "X miles")
- Estimated time: "1 min" (or "X min")
- Estimated arrival: "10:05 PM"
- Small royal blue right arrow icon
- All text in black, numbers emphasized

**Current Delivery Card** (White card with royal blue accent border)
- Delivery ID: "#F165G258" (monospace font, black)
- Status badge: "Looking for Courier" with small car icon (royal blue)
- Package illustration: Simple line art box icon (royal blue outline)
- Card background: White
- Border: 2px royal blue on left edge or full border

**Delivery Information Section** (White background)
- Service: "Express Parcel" (black text)
- Receiver: "Emily Carter" (black text, bold)
- Address: "2210 Coral Way, Apt 3C" (gray text)
- Package Type: "Retail Merchandise" (gray text)
- Payment Method: "Cash on Delivery" (gray text)
- Each field: Label (gray) + Value (black)

**Special Instructions Box** (Light gray background, rounded corners)
- Text: "Please ensure the package is handled with care — fragile items inside."
- Border: Light gray
- Text color: Black

**Action Button** (Full-width swipeable bar at bottom)
- Background: Light gray (#F5F5F5)
- Royal blue right arrow icon on left
- Text: "Slide to pick up the order" (black text)
- Swipe interaction: Swipe right to confirm
- When swiped: Royal blue background, white text

**Footer** (Black background bar)
- Left: "Contact support" button (white text)
- Right: Two icons (white):
  - Chat bubble icon
  - Phone receiver icon

### Functionality
1. **Real-time Updates**: Delivery status updates from Firestore
2. **Swipe to Confirm**: Swipe right gesture to pick up order
3. **Contact Actions**: Tap phone/chat icons to contact customer or support
4. **Navigation**: Tap address to open in maps app
5. **Status Tracking**: Visual indicator of current delivery stage

### Data Integration
- Fetch delivery details from Firestore `deliveries` collection
- Listen for real-time status changes
- Update delivery status on swipe confirmation
- Calculate distance/time using driver's current location

---

## Screen 2: Map View / Navigation Screen

### Layout Structure

**Top Bar** (White background)
- Left: Back arrow (royal blue), "Distance eg: km or miles", "Next street name" (black text)
- Right: "Pause shift" button (black background, white text, rounded)

**Map Display** (Full screen, light gray map style)
- Map style: Light theme (white/gray streets)
- Route line: Royal blue (#4169E1), 4-6px width
- Driver location: White car icon, facing direction of travel
- Destination pin: Royal blue teardrop pin
- Other delivery points: Black package icons with white dots
- Map controls: Standard zoom/compass controls

**Footer** (Black background bar)
- Distance: "1.5 mile" (white text)
- Time: "10 min" (white text)
- ETA: "10:05 PM" (white text)
- Royal blue right arrow icon

### Functionality
1. **Real-time GPS Tracking**: Update driver location every 5-10 seconds
2. **Route Navigation**: Display optimized route from current location to destination
3. **Turn-by-turn Directions**: Show next turn instruction in top bar
4. **Multiple Stops**: Display all delivery points on map
5. **Pause Shift**: Allow driver to pause accepting new deliveries
6. **Map Interactions**: 
   - Tap markers to see delivery details
   - Long press to get directions
   - Pinch to zoom, pan to navigate

### Data Integration
- Use device GPS for real-time location
- Calculate route using Mapbox Directions API or Google Maps API
- Update driver location in Firestore `users/{driverId}/driverDetails/currentLocation`
- Listen for delivery updates and refresh map markers
- Calculate ETA based on current speed and route

### Navigation Integration
- Deep link to Apple Maps (iOS) or Google Maps (Android)
- Or use in-app navigation with Mapbox Navigation SDK
- Voice turn-by-turn directions
- Re-route on deviation

---

## Screen 3: Driver Dashboard / Home Screen

### Layout Structure

**Header** (White background)
- Left: Circular profile picture (white border, royal blue accent ring when online)
- Center: Name "user name" (black, bold) and address "user address" (gray)
- Right: Bell icon for notifications (black, royal blue badge if unread)

**Search Bar** (Light gray background, rounded)
- Magnifying glass icon (gray)
- Placeholder: "Search deliveries..." (gray text)
- Right: Filter/scan icon (gray)

**Current Deliveries Section**
- Heading: "Current Deliveries" (black, bold)
- Horizontal scrollable cards:
  - Card 1 (White with royal blue accent):
    - Delivery ID: "#CB1AD25" (black, monospace)
    - Status: "In Delivery" with car icon (royal blue)
    - Arrival time: "12:05 PM" (gray)
    - Package icon: Royal blue box illustration
  - Card 2 (Partial, indicating scroll): Similar design
- Cards: White background, royal blue left border, subtle shadow

**Services Section**
- Heading: "Services" (black, bold)
- Three square icons in a row:
  - "Create" (box icon) - White background, black icon, royal blue border
  - "Receipts" (receipt icon) - White background, black icon, royal blue border
  - "Support" (lifebuoy icon) - White background, black icon, royal blue border
- Each icon: Rounded square, tap to navigate

**Delivery History Section**
- Heading: "Delivery History" (black, bold) with "See all" link (royal blue) on right
- Vertical scrollable list:
  - Card 1 (White with royal blue accent):
    - Delivery ID: "#A856K005" (black, monospace)
    - Status: "Delivered" with checkmark (royal blue)
    - Arrival time: "Delivery time" (gray)
    - Package icon: Royal blue box illustration
  - Card 2 (Partial, indicating scroll): Similar design

**Footer Navigation** (Black background bar)
- Five icons (white, royal blue when active):
  - Home icon (house)
  - Map icon
  - Orders icon (list)
  - Profile icon (person)
  - Settings icon (gear)

### Functionality
1. **Dashboard Stats**: Display today's earnings, deliveries count, completion rate
2. **Active Deliveries**: Show current in-progress deliveries
3. **Delivery History**: Scrollable list of past deliveries
4. **Quick Actions**: Tap service icons for common tasks
5. **Search**: Search deliveries by ID, customer name, or address
6. **Notifications**: Badge count on bell icon, tap to view notifications
7. **Profile Access**: Tap profile picture to view/edit profile
8. **Bottom Navigation**: Navigate between main sections

### Data Integration
- Fetch driver stats from Firestore aggregations
- Real-time listener for current deliveries
- Paginated delivery history
- Notification count from `notifications` collection
- User profile data from `users` collection

---

## Core Features & Functionality

### 1. Authentication & Onboarding
- **Login**: Email/password with Firebase Auth
- **Profile Completion**: Multi-step form for driver details
- **Document Upload**: Upload driving license, insurance, MOT
- **Approval Status**: Show pending/approved status
- **Session Management**: Auto-login, token refresh

### 2. Delivery Management
- **Accept Deliveries**: Tap to accept available deliveries
- **Status Updates**: 
  - Assigned → Picked Up → In Transit → Delivered
  - Swipe gestures for quick actions
- **Delivery Details**: Full information view with all fields
- **Special Instructions**: Highlight fragile, controlled substances, etc.
- **Photo Proof**: Capture photos at pickup and delivery
- **Signature Capture**: Digital signature for delivery confirmation

### 3. Navigation & Routing
- **Real-time GPS**: Continuous location tracking
- **Route Optimization**: Calculate best route
- **Turn-by-turn**: Voice and visual directions
- **Multiple Stops**: Optimize route for multiple deliveries
- **Offline Maps**: Cache map tiles for offline use
- **Traffic Updates**: Real-time traffic information

### 4. Communication
- **In-app Chat**: Message customers and support
- **Phone Calls**: Direct dial from app
- **Push Notifications**: Delivery assignments, status updates
- **Support Chat**: 24/7 support access

### 5. Earnings & Statistics
- **Today's Estimated Earnings**: Real-time calculation
- **Delivery Count**: Today's completed deliveries
- **Completion Rate**: Percentage of successful deliveries
- **Average Time**: Average delivery time
- **Weekly/Monthly Stats**: Historical data

### 6. Shift Management
- **Go Online/Offline**: Toggle availability
- **Pause Shift**: Temporarily stop accepting deliveries
- **Shift History**: View past shifts and estimated earnings
- **Break Management**: Log breaks and downtime

### 7. Profile & Settings
- **Profile Management**: Edit personal information
- **Vehicle Details**: Update vehicle information
- **Document Management**: Upload/update documents
- **Notification Preferences**: Customize alerts
- **App Settings**: Theme, language, units

---

## Technical Requirements

### Platform
Flutter recommended

### Backend Integration
- **Firebase Authentication**: User login and session management
- **Cloud Firestore**: Real-time database for deliveries, users, stats
- **Firebase Storage**: Document and photo uploads
- **Firebase Cloud Messaging**: Push notifications
- **Firebase Realtime Database**: Real-time location tracking (optional)

### Third-party Services
- **Maps**: Mapbox GL  SDK
- **Navigation**: Mapbox Navigation SDK
- **Geocoding**: Mapbox Geocoding API 
- **Route Optimization**: Mapbox Directions API
- **Image Processing**: Firebase Storage with image compression

### Permissions Required
- **Location**: Always (for background tracking)
- **Camera**: For photo proof of delivery
- **Storage**: For saving photos and documents
- **Notifications**: For push notifications
- **Phone**: For making calls (optional)

### Performance Requirements
- **Location Updates**: Every 5-10 seconds when active
- **Map Rendering**: 60 FPS, smooth pan/zoom
- **Data Sync**: Real-time updates with <1s latency
- **Offline Support**: Cache critical data for offline access
- **Battery Optimization**: Efficient location tracking

### Security
- **Encryption**: All data encrypted in transit (HTTPS/TLS)
- **Authentication**: Firebase Auth with secure tokens
- **Data Validation**: Client and server-side validation
- **Secure Storage**: Encrypted local storage for sensitive data
- **Document Security**: Secure upload and access controls

---
# Driver Mobile App - Complete Development Prompt

## Project Overview

**Theme**: Black and white color scheme with royal blue (#4169E1 or similar) as the primary accent color.

**Backend**: The mobile app must integrate with the existing Firebase backend used by the web application.

**Platforms**: iOS and Android

---

## Tech Stack & Architecture

### Mobile Framework
- **Flutter**: Version 3.35.7
- **Dart**: Latest stable version compatible with Flutter 3.35.7
- **Platforms**: iOS and Android

### Backend Services (Already Configured)
- **Firebase Authentication** (latest version) - User authentication
- **Cloud Firestore** (latest version) - Primary database for deliveries, users, notifications
- **Firebase Storage** (latest version) - For document and photo uploads
- **Firebase Cloud Messaging** (latest version) - Push notifications
- **Firebase Realtime Database** (latest version) - Optional for real-time location tracking
- **Mapbox SDK** - Maps and navigation (Flutter Mapbox GL plugin)

### Required Flutter Packages
- `firebase_core` - Firebase initialization
- `firebase_auth` - Authentication
- `cloud_firestore` - Firestore database
- `firebase_storage` - File storage
- `firebase_messaging` - Push notifications
- `mapbox_maps_flutter` or `flutter_mapbox_navigation` - Mapbox integration
- `geolocator` - GPS location services
- `geocoding` - Address geocoding
- `image_picker` - Photo capture
- `signature` - Digital signature capture
- `riverpod` - State management
- `flutter_local_notifications` - Local notifications

### Firebase Configuration
The Firebase config uses the same project as the web application. Use `firebase_options.dart` generated by FlutterFire CLI for platform-specific configuration.

---

## Data Structures & Type Definitions

### Core Types (Must match web app structure)

**UserRole**: "admin" | "driver" | "pharmacy"

**BaseUser**:
- uid: String
- email: String
- firstName: String
- lastName: String
- role: UserRole
- isApproved: bool
- isActive: bool
- profileComplete: bool
- profileImage: String? (optional)
- phoneNumber: String? (optional)
- createdAt: Timestamp
- updatedAt: Timestamp
- lastLoginAt: Timestamp? (optional)
- fcmTokens: List<String>
- permissions: List<Permission>? (optional)

**DriverUser** extends BaseUser:
- role: "driver"
- driverDetails: DriverDetails object containing:
  - licenseNumber: String
  - licenseExpiryDate: Timestamp
  - vehicleType: "motorcycle" | "van" | "car" | "truck" | "scooter" | "bicycle" | "other"
  - vehicleRegistration: String
  - vehicleInsuranceExpiry: Timestamp
  - motExpiry: Timestamp? (optional)
  - currentLocation: Location? (optional)
  - isOnline: bool
  - maxDeliveryRadius: double (in kilometers)
  - emergencyContact: EmergencyContact object
  - bankDetails: BankDetails? (optional)
  - nationalInsuranceNumber: String? (optional)
  - documents: DriverDocuments? (optional)

**Location**:
- latitude: double
- longitude: double
- address: String
- postcode: String
- city: String
- county: String? (optional)
- country: String

**DeliveryStatus**: "pending" | "assigned" | "picked_up" | "in_transit" | "delivered" | "failed" | "cancelled" | "returned"

**DeliveryPriority**: "low" | "standard" | "urgent" | "emergency"

**PackageDetails**:
- description: String
- weight: double? (optional, in grams)
- dimensions: Dimensions? (optional)
- temperature: "ambient" | "cool" | "frozen"? (optional)
- isControlled: bool
- value: double? (optional, in GBP)
- specialInstructions: String? (optional)

**Delivery**:
- id: String
- pharmacyId: String
- driverId: String? (optional)
- packages: List<PackageDetails>
- pickupLocation: Location
- pickupInstructions: String? (optional)
- pickupContactName: String
- pickupContactPhone: String
- deliveryLocation: Location
- deliveryInstructions: String? (optional)
- recipientName: String
- recipientPhone: String
- requestedPickupTime: Timestamp
- requestedDeliveryTime: Timestamp
- actualPickupTime: Timestamp? (optional)
- actualDeliveryTime: Timestamp? (optional)
- status: DeliveryStatus
- priority: DeliveryPriority
- estimatedDistance: double? (optional, in meters)
- estimatedDuration: double? (optional, in minutes)
- actualDistance: double? (optional)
- actualDuration: double? (optional)
- route: Route? (optional)
- cost: double (in GBP)
- paymentStatus: "pending" | "paid" | "failed"
- photos: DeliveryPhotos? (optional)
- signature: Signature? (optional)
- createdAt: Timestamp
- updatedAt: Timestamp
- createdBy: String
- notificationsSent: NotificationsSent object
- requiresPhotoProof: bool
- requiresSignature: bool
- ageVerificationRequired: bool

**MapMarker**:
- id: String
- type: "pharmacy" | "driver" | "pickup" | "delivery"
- location: Location
- title: String
- description: String? (optional)
- icon: String? (optional)
- isActive: bool? (optional)

**NotificationType**: "delivery_assigned" | "delivery_picked_up" | "delivery_in_transit" | "delivery_delivered" | "delivery_failed" | "user_approved" | "user_rejected" | "emergency_alert"

**UserNotification**:
- id: String
- userId: String
- type: NotificationType
- title: String
- body: String
- isRead: bool
- createdAt: Timestamp
- data: Map<String, dynamic>? (optional)
- actionUrl: String? (optional)

Message (from messages collection):
id: String
senderId: String
senderName: String
senderRole: String
recipientId: String
recipientName: String
recipientRole: String
subject: String
message: String
type: String
read: bool
parentMessageId: String? (optional, for replies)
createdAt: Timestamp
Conversation (from conversations collection):
id: String
participants: List<String> (user IDs)
createdAt: Timestamp
updatedAt: Timestamp
lastMessage: String? (optional)
lastMessageAt: Timestamp? (optional)
ConversationMessage (from conversations/{conversationId}/messages subcollection):
id: String
conversationId: String
senderId: String
senderName: String
message: String
createdAt: Timestamp
read: bool
readBy: List<String>? (optional)
ContactMessage (from contact_messages collection):
id: String
name: String
email: String
phone: String
company: String
pharmacyType: "independent" | "chain" | "hospital" | "other"
message: String
subject: "demo" | "support" | "sales" | "partnership" | "other"
status: "new" | "read" | "replied" | "archived"
read: bool
createdAt: Timestamp
updatedAt: Timestamp
Pharmacy Types:
PharmacyUser extends BaseUser:
role: "pharmacy"
pharmacyDetails: PharmacyDetails object containing:
pharmacyName: String
registrationNumber: String
gphcNumber: String
location: Location
operatingHours: OperatingHours object (monday through sunday, each with open, close, closed?)
contactPerson: ContactPerson object (name, position, phoneNumber, email)
billingAddress: Location? (optional)
vatNumber: String? (optional)
companyNumber: String? (optional)
website: String? (optional)
isParent: bool? (optional)
parentPharmacyId: String? (optional)
organizationId: String? (optional)
organizationName: String? (optional)
branchCode: String? (optional)
PharmacyBranch:
uid: String
email: String? (optional)
role: "pharmacy"
pharmacyName: String
pharmacyLicense: String
branchCode: String
isParent: bool
parentPharmacyId: String? (optional)
organizationId: String
organizationName: String
address: String
city: String? (optional)
postcode: String? (optional)
coordinates: Coordinates? (optional) with lat and lng
operatingHours: String? (optional)
deliveryRadius: double? (optional)
firstName: String? (optional)
lastName: String? (optional)
branchManager: String? (optional)
phoneNumber: String? (optional)
isApproved: bool
isActive: bool
createdAt: Timestamp
updatedAt: Timestamp
notes: String? (optional)
PharmacyOrganization:
organizationId: String
organizationName: String
parentPharmacyId: String
totalBranches: int
activeBranches: int
pendingBranches: int
isApproved: bool
isActive: bool
branches: List<PharmacyBranch>
---

## Firestore Collections & Query Patterns

### Collection: `users/{userId}`
**Document Structure**: DriverUser type

**Operations**:
- Read: Get current driver user document
- Update: Update driver online status, current location, profile details
- Fields to update frequently: `driverDetails.isOnline`, `driverDetails.currentLocation`, `updatedAt`

### Collection: `deliveries/{deliveryId}`
**Document Structure**: Delivery type

**Query Patterns**:
- Get driver's assigned deliveries: Query where `driverId == currentUserId`
- Get available deliveries: Query where `status == "pending"`
- Real-time listeners: Use Firestore snapshots for live updates
- Update operations: Accept delivery (set driverId and status to "assigned"), update status, add photos, add signature

**Status Flow**:
- pending → assigned (when driver accepts)
- assigned → picked_up (when driver picks up)
- picked_up → in_transit (when driver starts navigation)
- in_transit → delivered (when delivery completed)

### Collection: `notifications/{userId}/messages/{notificationId}`
**Document Structure**: UserNotification type

**Query Patterns**:
- Get user notifications: Query subcollection ordered by createdAt descending
- Filter unread: Query where `isRead == false`
- Mark as read: Update `isRead` field to true

### Collection: `user_locations/{userId}` (Optional)
**Document Structure**: Location tracking document with userId, location, lastUpdated, isOnline

---

## Firebase Storage Structure

### Storage Paths:
- `/drivers/{userId}/documents/` - Driver documents (license, insurance, MOT, DBS, proof of address)
- `/deliveries/{deliveryId}/photos/` - Delivery photos (pickup and delivery)
- `/deliveries/{deliveryId}/signatures/` - Digital signatures

### Upload Requirements:
- Photos: JPEG format, compressed for mobile
- Documents: PDF or JPEG
- Signatures: PNG format
- Use Firebase Storage upload with metadata
- Get download URL after upload
- Update Firestore document with URL

---

## Design System & Theme

### Color Palette
- **Primary Background**: Pure white (#FFFFFF)
- **Secondary Background**: Light gray (#F5F5F5 or #FAFAFA)
- **Text Primary**: Black (#000000 or #1A1A1A)
- **Text Secondary**: Dark gray (#666666 or #4A4A4A)
- **Accent Color**: Royal Blue (#4169E1 or #1E40AF)
- **Accent Light**: Light royal blue tint for backgrounds (#E6F0FF)
- **Borders**: Light gray (#E5E5E5 or #D3D3D3)
- **Status Colors**:
  - Success: Royal blue (#4169E1)
  - Warning: Dark gray (#666666)
  - Error: Dark red (#8B0000)

### Typography
- **Primary Font**: System default (SF Pro for iOS, Roboto for Android)
- **Headings**: Bold, 18-24pt
- **Body Text**: Regular, 14-16pt
- **Labels**: Medium weight, 12-14pt
- **Monospace**: For delivery IDs and codes

### UI Components
- **Cards**: White background, subtle shadow, rounded corners (12-16px)
- **Buttons**: 
  - Primary: Royal blue background, white text
  - Secondary: White background, royal blue border and text
  - Swipe actions: Full-width with royal blue accent
- **Icons**: Black with royal blue accents for active states
- **Status Badges**: White background, royal blue border, royal blue text

### Flutter Theme Configuration
- Use Cupertino design system
- Define color scheme in ThemeData
- Create custom widgets for consistent styling
- Use royal blue as primary color
- Black and white for buttons, text and backgrounds

---

## Screen 1: Delivery Details Screen

### Layout Structure

**Top Information Bar** (White background, below status bar)
- Distance: Display in km/ miles (convert from meters if needed)
- Estimated time: Display in minutes
- Estimated arrival: Format as time (e.g., "10:05 PM")
- Small royal blue right arrow icon
- All text in black, numbers emphasized

**Current Delivery Card** (White card with royal blue accent border)
- Delivery ID: Display delivery.id (monospace font, black)
- Status badge: Display delivery.status with small car icon (royal blue)
- Package illustration: Simple line art box icon (royal blue outline)
- Card background: White
- Border: 2px royal blue on left edge or full border

**Delivery Information Section** (White background)
- Service: Display package type or "Express Parcel" (black text)
- Receiver: Display delivery.recipientName (black text, bold)
- Address: Display delivery.deliveryLocation.address (gray text)
- Package Type: From delivery.packages[0].description (gray text)
- Payment Method: "Cash on Delivery" or from delivery data (gray text)
- Each field: Label (gray) + Value (black)

**Special Instructions Box** (Light gray background, rounded corners)
- Text: Display delivery.deliveryInstructions or delivery.packages[0].specialInstructions
- Border: Light gray
- Text color: Black

**Action Button** (Full-width swipeable bar at bottom)
- Background: Light gray (#F5F5F5)
- Royal blue right arrow icon on left
- Text: "Slide to pick up the order" (black text)
- Swipe interaction: Swipe right to confirm
- When swiped: Royal blue background, white text
- **Action**: Update delivery status to "picked_up" in Firestore

**Footer** (Black background bar)
- Left: "Contact support" button (white text)
- Right: Two icons (white):
  - Chat bubble icon → Open chat with customer
  - Phone receiver icon → Call delivery.recipientPhone

### Functionality
1. **Real-time Updates**: Use Firestore stream listener on delivery document
2. **Swipe to Confirm**: Implement swipe right gesture to pick up order
3. **Contact Actions**: Tap phone/chat icons to contact customer or support
4. **Navigation**: Tap address to open in maps app or calculate route
5. **Status Tracking**: Visual indicator of current delivery stage

### Data Integration
- Listen for delivery updates using Firestore stream
- Update delivery status on swipe confirmation
- Calculate distance/time using driver's current location
- Handle photo capture if required
- Handle signature capture if required

---

## Screen 2: Map View / Navigation Screen

### Layout Structure

**Top Bar** (White background)
- Left: Back arrow (royal blue), distance to next turn, next street name
- Right: "Pause shift" button (black background, white text, rounded)
- **Action**: Update users/{userId}/driverDetails/isOnline to false

**Map Display** (Full screen, light gray map style)
- Map style: Light theme (white/gray streets) using Mapbox
- Route line: Royal blue (#4169E1), 4-6px width
- Driver location: White car icon, facing direction of travel
- Destination pin: Royal blue teardrop pin at delivery.deliveryLocation
- Other delivery points: Black package icons with white dots
- Map controls: Standard zoom/compass controls

**Footer** (Black background bar)
- Distance: Display delivery.estimatedDistance converted to miles (white text)
- Time: Display delivery.estimatedDuration in minutes (white text)
- ETA: Calculated from current time + duration (white text)
- Royal blue right arrow icon

### Functionality
1. **Real-time GPS Tracking**: Update driver location every 5-10 seconds
2. **Route Navigation**: Display optimized route from current location to destination using Mapbox Directions API
3. **Turn-by-turn Directions**: Show next turn instruction in top bar
4. **Multiple Stops**: Display all delivery points on map
5. **Pause Shift**: Allow driver to pause accepting new deliveries
6. **Map Interactions**: 
   - Tap markers to see delivery details
   - Long press to get directions
   - Pinch to zoom, pan to navigate

### Data Integration
- Use Geolocator package for GPS location
- Update users/{userId}/driverDetails/currentLocation continuously
- Calculate route using Mapbox Directions API
- Update delivery with route information
- Handle navigation using Mapbox Navigation SDK
- Deep link to Apple Maps (iOS) or Google Maps (Android) as fallback

---

## Screen 3: Driver Dashboard / Home Screen

### Layout Structure

**Header** (White background)
- Left: Circular profile picture from user.profileImage (white border, royal blue accent ring when user.driverDetails.isOnline)
- Center: Name user.firstName + " " + user.lastName (black, bold) and address from user.driverDetails.currentLocation?.address (gray)
- Right: Bell icon for notifications (black, royal blue badge if unread count > 0)

**Search Bar** (Light gray background, rounded)
- Magnifying glass icon (gray)
- Placeholder: "Track your shipment..." (gray text)
- Right: Filter/scan icon (gray)
- **Action**: Search deliveries by ID, customer name, or address

**Current Deliveries Section**
- Heading: "Current Deliveries" (black, bold)
- Horizontal scrollable cards:
  - Filter: deliveries where status is "assigned", "picked_up", or "in_transit"
  - Each card (White with royal blue accent):
    - Delivery ID: delivery.id first 8 characters (black, monospace)
    - Status: delivery.status with car icon (royal blue)
    - Arrival time: Format delivery.requestedDeliveryTime (gray)
    - Package icon: Royal blue box illustration
  - Cards: White background, royal blue left border, subtle shadow

**Services Section**
- Heading: "Services" (black, bold)
- Four square icons in a row:
  - "Create" (box icon) - White background, black icon, royal blue border
  - "Receipts" (receipt icon) - White background, black icon, royal blue border
  - "Support" (lifebuoy icon) - White background, black icon, royal blue border
- Each icon: Rounded square, tap to navigate

**Delivery History Section**
- Heading: "Delivery History" (black, bold) with "See all" link (royal blue) on right
- Vertical scrollable list:
  - Filter: deliveries where status is "delivered"
  - Each card (White with royal blue accent):
    - Delivery ID: delivery.id first 8 characters (black, monospace)
    - Status: "Received" with checkmark (royal blue)
    - Arrival time: Format delivery.actualDeliveryTime (gray)
    - Package icon: Royal blue box illustration

**Footer Navigation** (Black background bar)
- Five icons (white, royal blue when active):
  - Home icon (house) - Current screen
  - Map icon - Navigate to map view
  - Orders icon (list) - Delivery list view
  - Profile icon (person) - Profile screen
  - Settings icon (gear) - Settings screen

### Functionality
1. **Dashboard Stats**: Calculate from deliveries
   - Today's earnings: Sum of cost from today's delivered deliveries
   - Today's deliveries: Count of today's deliveries
   - Completion rate: (completed deliveries / total deliveries) * 100
   - Average time: Calculate from actualDeliveryTime - actualPickupTime
2. **Active Deliveries**: Show current in-progress deliveries
3. **Delivery History**: Scrollable list of past deliveries
4. **Quick Actions**: Tap service icons for common tasks
5. **Search**: Search deliveries by ID, customer name, or address
6. **Notifications**: Badge count on bell icon, tap to view notifications
7. **Profile Access**: Tap profile picture to view/edit profile
8. **Bottom Navigation**: Navigate between main sections

### Data Integration
- Fetch driver stats using Firestore queries
- Real-time listener for current deliveries
- Paginated delivery history
- Notification count from notifications collection
- User profile data from users collection

---

## Core Features & Functionality

### 1. Authentication & Onboarding
- **Login**: Email/password with Firebase Auth
- **Profile Completion**: Multi-step form for driver details
- **Document Upload**: Upload to Firebase Storage, update users/{userId}/driverDetails/documents
- **Approval Status**: Check user.isApproved and user.isActive
- **Session Management**: Use Firebase Auth state listener

### 2. Delivery Management
- **Accept Deliveries**: Update deliveries/{id} with driverId and status: "assigned"
- **Status Updates**: 
  - Assigned → Picked Up → In Transit → Delivered
  - Use swipe gestures for quick actions
- **Delivery Details**: Full information view with all fields from Delivery type
- **Special Instructions**: Highlight from delivery.deliveryInstructions or packages[].specialInstructions
- **Photo Proof**: Capture photos using image_picker, upload to Storage, update delivery.photos.delivery[]
- **Signature Capture**: Digital signature using signature package, upload to Storage, update delivery.signature
- **Age Verification**: Check delivery.ageVerificationRequired flag

### 3. Navigation & Routing
- **Real-time GPS**: Continuous location tracking using Geolocator, update users/{userId}/driverDetails/currentLocation
- **Route Optimization**: Calculate using Mapbox Directions API
- **Turn-by-turn**: Voice and visual directions using Mapbox Navigation SDK
- **Multiple Stops**: Optimize route for multiple deliveries
- **Offline Maps**: Cache map tiles for offline use
- **Traffic Updates**: Real-time traffic information from Mapbox

### 4. Communication
- **In-app Chat**: Use conversations/{conversationId}/messages/{messageId} collection
- **Phone Calls**: Direct dial from app using delivery.recipientPhone with url_launcher
- **Push Notifications**: Use Firebase Cloud Messaging, listen to notifications/{userId}/messages
- **Support Chat**: 24/7 support access

### 5. Earnings & Statistics
- **Today's Earnings**: Calculate from deliveries where status === "delivered" and createdAt is today
- **Delivery Count**: Count today's completed deliveries
- **Completion Rate**: (completed.length / total.length) * 100
- **Average Time**: Calculate from actualDeliveryTime - actualPickupTime
- **Weekly/Monthly Stats**: Filter deliveries by date range
- **Payment History**: View past payments from delivery.cost and delivery.paymentStatus

### 6. Shift Management
- **Go Online/Offline**: Toggle users/{userId}/driverDetails/isOnline
- **Pause Shift**: Temporarily stop accepting deliveries
- **Shift History**: View past shifts and earnings
- **Break Management**: Log breaks and downtime

### 7. Profile & Settings
- **Profile Management**: Update users/{userId} document
- **Vehicle Details**: Update users/{userId}/driverDetails vehicle fields
- **Document Management**: Upload/update documents in Storage, update users/{userId}/driverDetails/documents
- **Bank Details**: Update users/{userId}/driverDetails/bankDetails
- **Notification Preferences**: Customize alerts
- **App Settings**: Theme, language, units

---

## Firestore Security Rules (Reference)

The app must respect these Firestore security rules:

- Drivers can read their own profile
- Drivers can update their own profile (except role, approval status)
- Drivers can read deliveries assigned to them or pending deliveries
- Drivers can update status of deliveries assigned to them
- Drivers can read their own notifications
- Drivers can update their own notifications (mark as read)
- Drivers can read their own documents
- Drivers can update their own documents
- Drivers can read their own bank details
- Drivers can update their own bank details
- Drivers can read their own notifications
- Drivers can update their own notifications (mark as read)


---

## Flutter-Specific Implementation Notes

### State Management
- Use Riverpod for state management
- Create models for Delivery, DriverUser, Location, etc.
- Use StreamBuilder for real-time Firestore data
- Implement proper error handling and loading states

### Navigation
- Use Flutter go_router for navigation
- Implement bottom navigation bar
- Handle deep linking for notifications
- Proper back button handling

### Permissions
- Request location permissions (always allow for background tracking)
- Request camera permissions for photo capture
- Request storage permissions for file access
- Request notification permissions

### Performance
- Optimize Firestore queries with proper indexing
- Implement pagination for delivery lists
- Cache frequently accessed data
- Optimize image loading and compression
- Efficient GPS tracking to preserve battery

### Platform-Specific
- iOS: Configure Info.plist for location, camera, notifications
- Android: Configure AndroidManifest.xml for permissions
- Handle platform-specific UI differences efficiently and neatly
- Test on both iOS and Android devices

---

## Implementation Checklist

### Phase 1: Core Setup
- [ ] Flutter project initialization (3.35.7)
- [ ] Firebase SDK integration (FlutterFire)
- [ ] Mapbox SDK integration
- [ ] Type definitions/models creation
- [ ] Authentication flow
- [ ] Theme and design system
- [ ] Navigation structure

### Phase 2: Dashboard Screen
- [ ] Header with profile and notifications
- [ ] Stats cards (calculate from Firestore queries)
- [ ] Current deliveries list (real-time stream)
- [ ] Delivery history (filtered query)
- [ ] Services section
- [ ] Bottom navigation

### Phase 3: Delivery Details Screen
- [ ] Delivery information display (from Delivery model)
- [ ] Swipe to confirm action (update Firestore)
- [ ] Contact buttons (phone/chat)
- [ ] Special instructions
- [ ] Real-time status updates (stream listener)

### Phase 4: Map & Navigation
- [ ] Map integration (Mapbox)
- [ ] GPS tracking (update users/{userId}/driverDetails/currentLocation)
- [ ] Route calculation (Mapbox Directions API)
- [ ] Turn-by-turn directions
- [ ] Multiple markers (from deliveries)
- [ ] Navigation integration

### Phase 5: Delivery Management
- [ ] Accept/reject deliveries (update Firestore)
- [ ] Status updates (update delivery.status)
- [ ] Photo capture (upload to Storage, update delivery.photos)
- [ ] Signature capture (upload to Storage, update delivery.signature)
- [ ] Real-time sync (stream listeners)

### Phase 6: Additional Features
- [ ] Push notifications (Firebase Cloud Messaging)
- [ ] In-app chat (collection: messages collection)
- [ ] Earnings tracking (calculate from deliveries)
- [ ] Profile management (update users collection)
- [ ] Settings screen

### Phase 7: Polish & Testing
- [ ] Performance optimization
- [ ] Battery optimization (efficient location tracking)
- [ ] Offline support (cache critical data)
- [ ] Error handling
- [ ] User testing on iOS and Android
- [ ] Bug fixes

---

## Success Criteria

1. **Functionality**: All three screens work as specified with real Firestore data
2. **Performance**: Smooth 60 FPS, <2s load times
3. **Reliability**: 99%+ uptime, proper error handling
4. **User Experience**: Intuitive, easy to use
5. **Design**: Consistent black/white/royal blue theme
6. **Integration**: Seamless Firebase and Mapbox integration
7. **Security**: Secure authentication and data handling per Firestore rules
8. **Data Accuracy**: All data matches web app structure and types
9. **Platform Support**: Works seamlessly on both iOS and Android
10. **Battery Efficiency**: Efficient GPS tracking that doesn't drain battery excessively

---

## Additional Notes

- Ensure all Firestore queries match the web app's data structure
- Use the same Firebase project configuration as the web app
- Maintain consistency with web app's delivery status flow
- Test with real Firestore data from the web app
- Handle offline scenarios gracefully
- Implement proper error messages and user feedback
- Follow Flutter best practices for state management and architecture
- Ensure proper handling of Timestamp conversions between Firestore and Dart
- Test location permissions and GPS accuracy on both platforms
- Implement proper background location tracking for iOS and Android

Find the best way to handle environment variables for the app: