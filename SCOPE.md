# CampusLoop Project Scope

## 1. Project Summary

CampusLoop is a Flutter mobile app MVP for university students in Karachi. The
main problem it solves is that university events are scattered across WhatsApp
groups, Instagram pages, society posts, and word of mouth, so many students miss
events they would have attended.

The app centralizes:

- Event discovery across universities.
- A global student chat.
- Event-specific group chats.
- Private one-to-one messaging.
- Student profiles and basic social/follow behavior.
- Event listing requests with admin approval.

The project is being built as a course MVP, so the priority is a working,
demo-ready app with a clear entrepreneurship story and no paid backend
requirements.

## 2. Technology Scope

Current stack:

- Flutter for the app UI and Android/Windows preview builds.
- Firebase Authentication for email/password signup and login.
- Firebase Realtime Database for events, users, chats, event requests, reactions,
  follows, and admin review data.
- Generated profile avatars based on user data.

Current package dependencies:

- `firebase_core`
- `firebase_auth`
- `firebase_database`
- `cupertino_icons`

Cost guardrails:

- Do not use Firebase Storage for uploaded profile photos.
- Do not use Cloud Functions.
- Do not use phone OTP authentication.
- Do not use Firestore for this project, because the Firebase project required
  billing when creating Cloud Firestore.
- Share APKs directly for free instead of publishing to Play Store.

Official Firebase references:

- Firebase Auth email/password: https://firebase.google.com/docs/auth/flutter/password-auth
- Realtime Database read/write: https://firebase.google.com/docs/database/flutter/read-and-write
- Realtime Database lists: https://firebase.google.com/docs/database/flutter/lists-of-data
- Realtime Database security rules: https://firebase.google.com/docs/database/security
- Firebase pricing plans: https://firebase.google.com/docs/projects/billing/firebase-pricing-plans

## 3. User Roles

### Student User

A normal authenticated student can:

- Sign up and log in with email/password.
- Select a Karachi university during signup.
- View approved events.
- Mark an event as `Going` or `Interested`.
- Request a new event listing.
- Use the global chat.
- Join an event chat after marking the event as Going or Interested.
- Search other students.
- Follow other students.
- Start private chats.
- Send one intro message before mutual follow.
- Manage profile event visibility.

### Admin User

The current admin account is:

```text
abeersiddiki2k18@gmail.com
```

Only this email sees the Admin tab in the app UI.

The admin can:

- View pending event listing requests.
- See who submitted the request.
- See event details.
- Approve requests with a tick-style action.
- Reject requests with a cross-style action.
- Make approved events appear publicly in the Events tab.

No extra admin features are in scope for this MVP.

## 4. Completed Features

### Authentication

Status: Completed in app code.

Implemented behavior:

- Email/password signup.
- Email/password login.
- Firebase Auth session listener.
- User profile creation in Realtime Database after signup/login.
- Setup guard screen if Firebase app values are missing.

Signup captures:

- Full name.
- Email.
- Password.
- University from a Karachi university dropdown.

### User Profiles

Status: Completed in app code.

Implemented behavior:

- User profile stored under `users/{uid}`.
- Generated avatar using the user's name/UID.
- Profile screen shows name, university, and email.
- User can sign out.
- User profile shows their Going/Interested events.
- Each saved event can be toggled public/private.
- Other users can view only public event activity.

### Events Tab

Status: Completed in app code.

Implemented behavior:

- Approved events appear in the Events tab.
- Seed/demo events are created in Realtime Database when a user logs in.
- Each event shows title, university, category, date/time, location,
  description, Going count, and Interested count.
- Separate `Going` and `Interested` buttons.
- Tapping a reaction updates the user event state and event counts.
- Event chat button is available on the event card.

### Event Listing Requests

Status: Completed in app code.

Implemented behavior:

- Top-right app bar button opens an in-app event request form.
- Users can submit:
  - Event title.
  - University.
  - Category.
  - Location.
  - Start time.
  - End time.
  - Description.
- Requests are saved as pending under `eventRequests`.
- Requests include requester UID, name, and email.

### Admin Panel

Status: Completed in app code.

Implemented behavior:

- Admin tab appears only for `abeersiddiki2k18@gmail.com`.
- Admin sees pending event requests.
- Admin can approve a request.
- Admin can reject a request.
- Approved requests are copied into the public `events` path with status
  `approved`.
- Rejected requests are marked `rejected`.

Important note:

- The app UI hides admin actions from non-admin users.
- Realtime Database security rules still need to be configured before public
  use so non-admin users cannot directly write admin-only data.

### Global Chat

Status: Completed in app code.

Implemented behavior:

- Global/public chat exists for all authenticated users.
- Messages are stored under `globalMessages`.
- Messages update in real time using Realtime Database listeners.
- Each message stores sender UID, sender name, sender university, text, and
  created time.

### Private One-to-One Chat

Status: Completed in app code.

Implemented behavior:

- Users can search people in the People tab.
- Users can tap Start Chat to open a private chat screen.
- Private chat ID is generated from the two user IDs in sorted order, so both
  users open the same conversation.
- Messages are stored under `privateChats/{chatId}/messages`.
- Messages update in real time.
- A user can send one intro message before mutual follow.
- Full chat is intended to unlock after both users follow each other.

### People Search And Follow System

Status: Completed in app code.

Implemented behavior:

- People tab loads signed-up users from Realtime Database.
- Current user is excluded from search results.
- Search filters by name, university, or email.
- Users can follow or unfollow another student.
- Follow data is stored under `following/{uid}/{otherUid}`.

### Event Group Chats

Status: Completed in app code.

Implemented behavior:

- Every event can have its own group chat.
- Event chat messages are stored under `eventChats/{eventId}/messages`.
- User must mark the event as Going or Interested before opening the event chat.
- Event chat becomes closed in the app 3 days after the event end time.
- No server cleanup is used, keeping the MVP free-tier friendly.

## 5. Realtime Database Structure

Recommended current structure:

```text
users/{uid}
  uid
  name
  university
  email
  avatarSeed
  searchText
  createdAt
  lastSeenAt

events/{eventId}
  title
  university
  category
  location
  description
  startAt
  endAt
  status
  featured
  goingCount
  interestedCount
  createdAt
  approvedAt

eventRequests/{requestId}
  title
  university
  category
  location
  description
  startAt
  endAt
  requesterUid
  requesterName
  requesterEmail
  status
  createdAt
  reviewedAt

userEvents/{uid}/{eventId}
  eventId
  eventTitle
  eventUniversity
  eventStartAt
  type
  public
  updatedAt

globalMessages/{messageId}
  senderId
  senderName
  senderUniversity
  text
  createdAt

eventChats/{eventId}
  eventId
  eventTitle
  expiresAt
  updatedAt
  messages/{messageId}

privateChats/{chatId}
  participants
  participantNames
  updatedAt
  messages/{messageId}

following/{uid}/{otherUid}
  createdAt
```

## 6. Admin Panel Implementation Approach

The admin panel is implemented inside the same Flutter app.

How it works:

1. User signs in with Firebase Auth.
2. App loads the user's profile from `users/{uid}`.
3. If the profile email equals `abeersiddiki2k18@gmail.com`, the app shows the
   Admin tab.
4. Admin tab listens to `eventRequests` where `status = pending`.
5. Each pending request is displayed with event details and submitter details.
6. Approve action:
   - Writes the event into `events/{requestId}`.
   - Sets `status = approved`.
   - Updates the original request status to `approved`.
7. Reject action:
   - Updates the original request status to `rejected`.
8. Since the Events tab only shows approved events, approved requests become
   visible publicly.

This satisfies the required basic admin functionality:

- View pending requests.
- See event details and submitter.
- Approve or reject.
- Approved events appear publicly.

## 7. Chat Implementation Approach

Yes, both global chat and private one-to-one messaging are possible with
Firebase Realtime Database.

Recommended approach used by the app:

- Use Firebase Auth UID to identify the sender.
- Store public/global messages in one shared path.
- Store private messages in deterministic chat rooms.
- Use Realtime Database listeners so messages update without refresh.

Global chat:

```text
globalMessages/{messageId}
```

Each message contains:

```text
senderId
senderName
senderUniversity
text
createdAt
```

Private chat:

```text
privateChats/{sortedUidA_sortedUidB}/messages/{messageId}
```

The private chat ID is created by sorting the two user IDs. This prevents two
separate chat rooms from being created for the same pair of users.

Event chat:

```text
eventChats/{eventId}/messages/{messageId}
```

Only users who mark the event as Going or Interested can open the event chat in
the app UI.

## 8. What Is Left

### Firebase Console Setup

Status: Not completed outside the app.

Remaining steps:

- Enable Firebase Authentication email/password.
- Enable Firebase Realtime Database.
- Copy Firebase config values:
  - `apiKey`
  - `projectId`
  - `appId`
  - `messagingSenderId`
  - `databaseURL`
- Run the app with all required `--dart-define` values.

Run command:

```powershell
flutter run -d windows --dart-define=FIREBASE_WEB_API_KEY=YOUR_API_KEY --dart-define=FIREBASE_PROJECT_ID=YOUR_PROJECT_ID --dart-define=FIREBASE_APP_ID=YOUR_APP_ID --dart-define=FIREBASE_MESSAGING_SENDER_ID=YOUR_MESSAGING_SENDER_ID --dart-define=FIREBASE_DATABASE_URL=YOUR_DATABASE_URL
```

### Database Security Rules

Status: Still needed before real/public use.

For a classroom demo, Firebase test mode can be used briefly. For any real
users, rules must be tightened.

Starter direction:

- Only authenticated users should read app data.
- Users should write only their own profile and follow data.
- Users can create event requests.
- Only the admin email should approve/reject requests.
- Only the admin email should create approved event records directly.
- Chat messages should only be written by authenticated users.

Important limitation:

- Current event Going/Interested counts are updated by the client. This is okay
  for an MVP demo, but a production app should protect counts more strictly,
  usually by moving count updates into trusted backend logic. That is out of
  scope because Cloud Functions may require billing.

### Manual Workflow Testing

Status: Still needed.

Test with at least two normal accounts plus the admin account:

- Student signup.
- Admin signup/login using `abeersiddiki2k18@gmail.com`.
- Event request submission by a normal student.
- Admin approval.
- Approved event appears in Events tab.
- Admin rejection.
- Global chat message appears for another user.
- Private intro message works.
- Full private chat behavior after mutual follow.
- Event chat opens only after Going/Interested.
- Event profile visibility toggle works.

### Project Folder Cleanup

Status: Still needed.

There have been two folders:

```text
C:\Users\Acer\Documents\Events app
C:\dev\events_app
```

The GitHub-connected folder is currently:

```text
C:\Users\Acer\Documents\Events app
```

Recommended next cleanup:

1. Keep the GitHub repo as the source of truth.
2. Replace `C:\dev\events_app` with a clean clone from GitHub.
3. Use only `C:\dev\events_app` going forward because it is better for Flutter
   builds than the Documents folder.

### APK Build

Status: Not completed after Realtime Database switch.

After Firebase setup and manual testing:

```powershell
flutter build apk --debug --dart-define=FIREBASE_WEB_API_KEY=YOUR_API_KEY --dart-define=FIREBASE_PROJECT_ID=YOUR_PROJECT_ID --dart-define=FIREBASE_APP_ID=YOUR_APP_ID --dart-define=FIREBASE_MESSAGING_SENDER_ID=YOUR_MESSAGING_SENDER_ID --dart-define=FIREBASE_DATABASE_URL=YOUR_DATABASE_URL
```

## 9. Out Of Scope For This MVP

These are intentionally excluded for now:

- Uploaded profile pictures.
- Firebase Storage.
- Phone number login.
- Push notifications.
- Payment/ticket checkout.
- Separate web admin dashboard.
- Advanced moderation/reporting tools.
- Automatic server cleanup of expired event chats.
- Play Store publishing.
- Recommendation algorithm.

## 10. Current Verification Status

Last known verification after the Realtime Database switch:

```text
flutter analyze: No issues found
flutter test: All tests passed
```

Latest pushed backend switch commit:

```text
51994fa Switch backend to Realtime Database
```

## 11. Success Criteria For Course Demo

The MVP is ready for presentation when:

- A user can sign up and log in.
- A user can submit an event request.
- The admin account can approve the request.
- The approved event appears in the Events tab.
- Users can mark Going or Interested.
- Users can use global chat.
- Users can search people.
- Users can open private chat.
- Users can open event chat after reacting to an event.
- The app runs as an installable Android APK or a stable Windows preview.
