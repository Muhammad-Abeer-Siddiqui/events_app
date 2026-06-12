import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

const adminEmail = 'abeersiddiki2k18@gmail.com';

const karachiUniversities = [
  'University of Karachi',
  'NED University',
  'IBA Karachi',
  'Habib University',
  'FAST NUCES Karachi',
  'SZABIST Karachi',
  'Iqra University',
  'Bahria University Karachi',
  'DHA Suffa University',
  'Sir Syed University',
  'Dow University',
  'Jinnah Sindh Medical University',
  'Ziauddin University',
  'Hamdard University Karachi',
  'MAJU Karachi',
  'Indus University',
  'Greenwich University',
  'Usman Institute of Technology',
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const CampusLoopApp());
  } catch (error) {
    runApp(FirebaseSetupApp(error: error.toString()));
  }
}

class AppFirebaseOptions {
  static const databaseUrl =
      'https://events-app-48a05-default-rtdb.firebaseio.com';
}

class CampusLoopApp extends StatelessWidget {
  const CampusLoopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CampusLoop',
      theme: campusTheme(),
      home: const AuthGate(),
    );
  }
}

ThemeData campusTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1F7A8C),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF7F8F3),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF7F8F3),
      foregroundColor: Color(0xFF17252A),
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

class FirebaseSetupApp extends StatelessWidget {
  const FirebaseSetupApp({super.key, this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CampusLoop setup',
      theme: campusTheme(),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Firebase setup needed',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'CampusLoop now uses Firebase Auth and Realtime Database. Run with your Firebase app values so signup, users, events, and chats can sync.',
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 12),
                          _ErrorPanel(message: error!),
                        ],
                        const SizedBox(height: 14),
                        const _SetupLine(label: 'FIREBASE_WEB_API_KEY'),
                        const _SetupLine(label: 'FIREBASE_PROJECT_ID'),
                        const _SetupLine(label: 'FIREBASE_APP_ID'),
                        const _SetupLine(label: 'FIREBASE_MESSAGING_SENDER_ID'),
                        const _SetupLine(label: 'FIREBASE_DATABASE_URL'),
                        const SizedBox(height: 14),
                        const Text(
                          'Example',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          'flutter run -d windows '
                          '--dart-define=FIREBASE_WEB_API_KEY=AIza... '
                          '--dart-define=FIREBASE_PROJECT_ID=your-project-id '
                          '--dart-define=FIREBASE_APP_ID=1:123:web:abc '
                          '--dart-define=FIREBASE_MESSAGING_SENDER_ID=123 '
                          '--dart-define=FIREBASE_DATABASE_URL=https://your-project-default-rtdb.firebaseio.com',
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupLine extends StatelessWidget {
  const _SetupLine({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class RealtimeDatabaseService {
  RealtimeDatabaseService._();

  static final instance = RealtimeDatabaseService._();

  final FirebaseAuth auth = FirebaseAuth.instance;

  FirebaseDatabase get database {
    final url = AppFirebaseOptions.databaseUrl.trim();
    if (url.isEmpty) {
      return FirebaseDatabase.instance;
    }
    return FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: url);
  }

  DatabaseReference get db => database.ref();

  bool isAdminEmail(String email) => email.trim().toLowerCase() == adminEmail;

  Future<void> signUp({
    required String name,
    required String university,
    required String email,
    required String password,
  }) async {
    final credential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(name);
    await upsertUserProfile(
      uid: credential.user!.uid,
      name: name,
      university: university,
      email: email,
    );
    if (isAdminEmail(email)) {
      await ensureSeedEvents();
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    final credential = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await ensureUserDocument(credential.user!);
    if (isAdminEmail(email)) {
      await ensureSeedEvents();
    }
  }

  Future<void> signOut() => auth.signOut();

  Future<void> ensureUserDocument(User user) async {
    final snapshot = await db.child('users/${user.uid}').get();
    if (snapshot.exists) {
      await snapshot.ref.update({'lastSeenAt': ServerValue.timestamp});
      return;
    }

    await upsertUserProfile(
      uid: user.uid,
      name: user.displayName ?? user.email?.split('@').first ?? 'Student',
      university: 'Campus student',
      email: user.email ?? '',
    );
  }

  Future<void> upsertUserProfile({
    required String uid,
    required String name,
    required String university,
    required String email,
  }) {
    final normalized =
        '${name.toLowerCase()} ${university.toLowerCase()} '
        '${email.toLowerCase()}';
    return db.child('users/$uid').update({
      'uid': uid,
      'name': name,
      'university': university,
      'email': email.toLowerCase(),
      'avatarSeed': uid,
      'searchText': normalized,
      'createdAt': ServerValue.timestamp,
      'lastSeenAt': ServerValue.timestamp,
    });
  }

  Future<void> ensureSeedEvents() async {
    for (final event in seedEvents) {
      await db.child('events/${event.id}').update(event.toSeedMap());
    }
  }

  Stream<List<CampusEvent>> eventsStream() {
    return db
        .child('events')
        .orderByChild('status')
        .equalTo('approved')
        .onValue
        .map((event) {
          final events = event.snapshot.children
              .map(
                (child) => CampusEvent.fromSnapshot(
                  child.key ?? '',
                  _asMap(child.value),
                ),
              )
              .toList();
          events.sort((a, b) => a.startAt.compareTo(b.startAt));
          return events;
        });
  }

  Stream<EventReaction?> eventReactionStream(String uid, String eventId) {
    return db.child('userEvents/$uid/$eventId').onValue.map((event) {
      if (!event.snapshot.exists) {
        return null;
      }
      return EventReaction.fromSnapshot(
        event.snapshot.key ?? eventId,
        _asMap(event.snapshot.value),
      );
    });
  }

  Stream<List<EventReaction>> userEventsStream(String uid) {
    return db.child('userEvents/$uid').onValue.map((event) {
      final reactions = event.snapshot.children
          .map(
            (child) => EventReaction.fromSnapshot(
              child.key ?? '',
              _asMap(child.value),
            ),
          )
          .toList();
      reactions.sort((a, b) => b.eventStartAt.compareTo(a.eventStartAt));
      return reactions;
    });
  }

  Stream<List<EventReaction>> publicUserEventsStream(String uid) {
    return db.child('userEvents/$uid').onValue.map((event) {
      final reactions = event.snapshot.children
          .map(
            (child) => EventReaction.fromSnapshot(
              child.key ?? '',
              _asMap(child.value),
            ),
          )
          .where((reaction) => reaction.isPublic)
          .toList();
      reactions.sort((a, b) => b.eventStartAt.compareTo(a.eventStartAt));
      return reactions;
    });
  }

  Future<void> setEventReaction({
    required UserProfile user,
    required CampusEvent event,
    required EventReactionType type,
  }) async {
    final eventRef = db.child('events/${event.id}');
    final reactionRef = db.child('userEvents/${user.uid}/${event.id}');
    final currentReaction = await reactionRef.get();
    final oldData = _asMap(currentReaction.value);
    final oldType = oldData['type']?.toString();
    final oldPublic = oldData['public'] == true;
    final newType = oldType == type.key ? null : type.key;

    final eventSnapshot = await eventRef.get();
    final eventData = _asMap(eventSnapshot.value);
    var goingCount = _asInt(eventData['goingCount']);
    var interestedCount = _asInt(eventData['interestedCount']);

    if (oldType == EventReactionType.going.key) {
      goingCount = max(0, goingCount - 1);
    }
    if (oldType == EventReactionType.interested.key) {
      interestedCount = max(0, interestedCount - 1);
    }

    if (newType == EventReactionType.going.key) {
      goingCount += 1;
    }
    if (newType == EventReactionType.interested.key) {
      interestedCount += 1;
    }

    await eventRef.update({
      'goingCount': goingCount,
      'interestedCount': interestedCount,
    });

    if (newType == null) {
      await reactionRef.remove();
      return;
    }

    await reactionRef.update({
      'eventId': event.id,
      'eventTitle': event.title,
      'eventUniversity': event.university,
      'eventStartAt': event.startAt.millisecondsSinceEpoch,
      'type': newType,
      'public': oldPublic,
      'updatedAt': ServerValue.timestamp,
    });
  }

  Future<void> setEventReactionPublic({
    required String uid,
    required String eventId,
    required bool isPublic,
  }) {
    return db.child('userEvents/$uid/$eventId').update({'public': isPublic});
  }

  Future<void> requestEvent({
    required UserProfile user,
    required String title,
    required String university,
    required String category,
    required String location,
    required String description,
    required DateTime startAt,
    required DateTime endAt,
  }) {
    return db.child('eventRequests').push().set({
      'title': title,
      'university': university,
      'category': category,
      'location': location,
      'description': description,
      'startAt': startAt.millisecondsSinceEpoch,
      'endAt': endAt.millisecondsSinceEpoch,
      'requesterUid': user.uid,
      'requesterName': user.name,
      'requesterEmail': user.email,
      'status': 'pending',
      'createdAt': ServerValue.timestamp,
    });
  }

  Stream<List<EventRequest>> pendingRequestsStream() {
    return db
        .child('eventRequests')
        .orderByChild('status')
        .equalTo('pending')
        .onValue
        .map((event) {
          final requests = event.snapshot.children
              .map(
                (child) => EventRequest.fromSnapshot(
                  child.key ?? '',
                  _asMap(child.value),
                ),
              )
              .toList();
          requests.sort((a, b) => b.startAt.compareTo(a.startAt));
          return requests;
        });
  }

  Future<void> approveRequest(EventRequest request) async {
    await db.update({
      'events/${request.id}': {
        'title': request.title,
        'university': request.university,
        'category': request.category,
        'location': request.location,
        'description': request.description,
        'startAt': request.startAt.millisecondsSinceEpoch,
        'endAt': request.endAt.millisecondsSinceEpoch,
        'status': 'approved',
        'featured': false,
        'goingCount': 0,
        'interestedCount': 0,
        'createdAt': ServerValue.timestamp,
        'approvedAt': ServerValue.timestamp,
      },
      'eventRequests/${request.id}/status': 'approved',
      'eventRequests/${request.id}/reviewedAt': ServerValue.timestamp,
    });
  }

  Future<void> rejectRequest(EventRequest request) {
    return db.child('eventRequests/${request.id}').update({
      'status': 'rejected',
      'reviewedAt': ServerValue.timestamp,
    });
  }

  Stream<List<ChatMessage>> globalMessagesStream() {
    return db
        .child('globalMessages')
        .orderByChild('createdAt')
        .limitToLast(80)
        .onValue
        .map((event) => _messagesFromSnapshot(event.snapshot));
  }

  Future<void> sendGlobalMessage(UserProfile user, String text) {
    return _sendMessage(db.child('globalMessages'), user: user, text: text);
  }

  Stream<List<ChatMessage>> eventMessagesStream(String eventId) {
    return db
        .child('eventChats/$eventId/messages')
        .orderByChild('createdAt')
        .limitToLast(80)
        .onValue
        .map((event) => _messagesFromSnapshot(event.snapshot));
  }

  Future<void> sendEventMessage({
    required UserProfile user,
    required CampusEvent event,
    required String text,
  }) async {
    if (event.chatClosed) {
      throw Exception('This event chat is closed.');
    }
    final chatRef = db.child('eventChats/${event.id}');
    await chatRef.update({
      'eventId': event.id,
      'eventTitle': event.title,
      'expiresAt': event.endAt
          .add(const Duration(days: 3))
          .millisecondsSinceEpoch,
      'updatedAt': ServerValue.timestamp,
    });
    await _sendMessage(chatRef.child('messages'), user: user, text: text);
  }

  Stream<List<UserProfile>> usersStream() {
    return db.child('users').orderByChild('name').onValue.map((event) {
      final users = event.snapshot.children
          .map(
            (child) =>
                UserProfile.fromSnapshot(child.key ?? '', _asMap(child.value)),
          )
          .toList();
      users.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return users;
    });
  }

  Stream<Set<String>> followingIdsStream(String uid) {
    return db
        .child('following/$uid')
        .onValue
        .map(
          (event) =>
              event.snapshot.children.map((child) => child.key ?? '').toSet(),
        );
  }

  Future<void> toggleFollow({
    required String currentUid,
    required String otherUid,
    required bool currentlyFollowing,
  }) {
    final ref = db.child('following/$currentUid/$otherUid');
    if (currentlyFollowing) {
      return ref.remove();
    }
    return ref.set({'createdAt': ServerValue.timestamp});
  }

  Stream<bool> followsStream(String fromUid, String toUid) {
    return db
        .child('following/$fromUid/$toUid')
        .onValue
        .map((event) => event.snapshot.exists);
  }

  Future<bool> mutualFollow(String uid, String otherUid) async {
    final mine = await db.child('following/$uid/$otherUid').get();
    final theirs = await db.child('following/$otherUid/$uid').get();
    return mine.exists && theirs.exists;
  }

  String privateChatId(String a, String b) {
    final ids = [a, b]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Stream<List<ChatMessage>> privateMessagesStream(
    String currentUid,
    String otherUid,
  ) {
    final chatId = privateChatId(currentUid, otherUid);
    return db
        .child('privateChats/$chatId/messages')
        .orderByChild('createdAt')
        .limitToLast(80)
        .onValue
        .map((event) => _messagesFromSnapshot(event.snapshot));
  }

  Future<void> sendPrivateMessage({
    required UserProfile sender,
    required UserProfile recipient,
    required String text,
  }) async {
    final chatId = privateChatId(sender.uid, recipient.uid);
    final chatRef = db.child('privateChats/$chatId');
    final mutual = await mutualFollow(sender.uid, recipient.uid);

    if (!mutual) {
      final existingIntro = await chatRef
          .child('messages')
          .orderByChild('senderId')
          .equalTo(sender.uid)
          .limitToFirst(1)
          .get();
      if (existingIntro.exists) {
        throw Exception(
          'You can send one intro message. Full chat unlocks after you both follow each other.',
        );
      }
    }

    await chatRef.update({
      'participants': [sender.uid, recipient.uid],
      'participantNames': {
        sender.uid: sender.name,
        recipient.uid: recipient.name,
      },
      'updatedAt': ServerValue.timestamp,
    });
    await _sendMessage(chatRef.child('messages'), user: sender, text: text);
  }

  Future<void> _sendMessage(
    DatabaseReference collection, {
    required UserProfile user,
    required String text,
  }) {
    return collection.push().set({
      'senderId': user.uid,
      'senderName': user.name,
      'senderUniversity': user.university,
      'text': text,
      'createdAt': ServerValue.timestamp,
    });
  }

  Stream<UserProfile?> userProfileStream(String uid) {
    return db.child('users/$uid').onValue.map((event) {
      if (!event.snapshot.exists) {
        return null;
      }
      return UserProfile.fromSnapshot(uid, _asMap(event.snapshot.value));
    });
  }

  List<ChatMessage> _messagesFromSnapshot(DataSnapshot snapshot) {
    final messages = snapshot.children
        .map(
          (child) =>
              ChatMessage.fromSnapshot(child.key ?? '', _asMap(child.value)),
        )
        .toList();
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return messages;
  }
}

enum EventReactionType {
  going('going', 'Going', Icons.check_circle_outline_rounded),
  interested('interested', 'Interested', Icons.star_border_rounded);

  const EventReactionType(this.key, this.label, this.icon);

  final String key;
  final String label;
  final IconData icon;
}

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.name,
    required this.university,
    required this.email,
    required this.avatarSeed,
  });

  final String uid;
  final String name;
  final String university;
  final String email;
  final String avatarSeed;

  bool get isAdmin => email.trim().toLowerCase() == adminEmail;

  factory UserProfile.fromSnapshot(String id, Map<String, dynamic> data) {
    final email = data['email']?.toString() ?? '';
    return UserProfile(
      uid: data['uid']?.toString() ?? id,
      name: data['name']?.toString().trim().isNotEmpty == true
          ? data['name'].toString()
          : email.split('@').first,
      university: data['university']?.toString() ?? 'Campus student',
      email: email,
      avatarSeed: data['avatarSeed']?.toString() ?? id,
    );
  }
}

class CampusEvent {
  const CampusEvent({
    required this.id,
    required this.title,
    required this.university,
    required this.startAt,
    required this.endAt,
    required this.location,
    required this.category,
    required this.description,
    required this.goingCount,
    required this.interestedCount,
    required this.featured,
  });

  final String id;
  final String title;
  final String university;
  final DateTime startAt;
  final DateTime endAt;
  final String location;
  final String category;
  final String description;
  final int goingCount;
  final int interestedCount;
  final bool featured;

  bool get chatClosed =>
      DateTime.now().isAfter(endAt.add(const Duration(days: 3)));

  String get dateLabel => '${_formatDate(startAt)} - ${_formatDate(endAt)}';

  factory CampusEvent.fromSnapshot(String id, Map<String, dynamic> data) {
    final now = DateTime.now();
    return CampusEvent(
      id: id,
      title: data['title']?.toString() ?? 'Untitled event',
      university: data['university']?.toString() ?? 'Campus',
      startAt: _asDate(data['startAt'], now),
      endAt: _asDate(data['endAt'], now.add(const Duration(hours: 2))),
      location: data['location']?.toString() ?? 'TBA',
      category: data['category']?.toString() ?? 'Event',
      description: data['description']?.toString() ?? '',
      goingCount: _asInt(data['goingCount']),
      interestedCount: _asInt(data['interestedCount']),
      featured: data['featured'] == true,
    );
  }

  Map<String, dynamic> toSeedMap() {
    return {
      'title': title,
      'university': university,
      'startAt': startAt.millisecondsSinceEpoch,
      'endAt': endAt.millisecondsSinceEpoch,
      'location': location,
      'category': category,
      'description': description,
      'goingCount': goingCount,
      'interestedCount': interestedCount,
      'featured': featured,
      'status': 'approved',
      'createdAt': ServerValue.timestamp,
    };
  }
}

class EventRequest {
  const EventRequest({
    required this.id,
    required this.title,
    required this.university,
    required this.category,
    required this.location,
    required this.description,
    required this.startAt,
    required this.endAt,
    required this.requesterName,
    required this.requesterEmail,
  });

  final String id;
  final String title;
  final String university;
  final String category;
  final String location;
  final String description;
  final DateTime startAt;
  final DateTime endAt;
  final String requesterName;
  final String requesterEmail;

  factory EventRequest.fromSnapshot(String id, Map<String, dynamic> data) {
    final now = DateTime.now();
    return EventRequest(
      id: id,
      title: data['title']?.toString() ?? 'Untitled request',
      university: data['university']?.toString() ?? 'Campus',
      category: data['category']?.toString() ?? 'Event',
      location: data['location']?.toString() ?? 'TBA',
      description: data['description']?.toString() ?? '',
      startAt: _asDate(data['startAt'], now),
      endAt: _asDate(data['endAt'], now.add(const Duration(hours: 2))),
      requesterName: data['requesterName']?.toString() ?? 'Student',
      requesterEmail: data['requesterEmail']?.toString() ?? '',
    );
  }
}

class EventReaction {
  const EventReaction({
    required this.eventId,
    required this.eventTitle,
    required this.eventUniversity,
    required this.eventStartAt,
    required this.type,
    required this.isPublic,
  });

  final String eventId;
  final String eventTitle;
  final String eventUniversity;
  final DateTime eventStartAt;
  final EventReactionType type;
  final bool isPublic;

  factory EventReaction.fromSnapshot(String id, Map<String, dynamic> data) {
    final typeKey =
        data['type']?.toString() ?? EventReactionType.interested.key;
    return EventReaction(
      eventId: data['eventId']?.toString() ?? id,
      eventTitle: data['eventTitle']?.toString() ?? 'Event',
      eventUniversity: data['eventUniversity']?.toString() ?? 'Campus',
      eventStartAt: _asDate(data['eventStartAt'], DateTime.now()),
      type: EventReactionType.values.firstWhere(
        (type) => type.key == typeKey,
        orElse: () => EventReactionType.interested,
      ),
      isPublic: data['public'] == true,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderUniversity,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String senderUniversity;
  final String text;
  final DateTime createdAt;

  factory ChatMessage.fromSnapshot(String id, Map<String, dynamic> data) {
    return ChatMessage(
      id: id,
      senderId: data['senderId']?.toString() ?? '',
      senderName: data['senderName']?.toString() ?? 'Student',
      senderUniversity: data['senderUniversity']?.toString() ?? 'Campus',
      text: data['text']?.toString() ?? '',
      createdAt: _asDate(data['createdAt'], DateTime.now()),
    );
  }
}

final seedEvents = [
  CampusEvent(
    id: 'ai-startup-weekend',
    title: 'AI Startup Weekend',
    university: 'FAST NUCES Karachi',
    startAt: DateTime(2026, 5, 23, 16),
    endAt: DateTime(2026, 5, 23, 20),
    location: 'Auditorium A',
    category: 'Entrepreneurship',
    description:
        'Build a small AI idea, pitch it to mentors, and meet students from nearby universities.',
    goingCount: 34,
    interestedCount: 184,
    featured: true,
  ),
  CampusEvent(
    id: 'inter-uni-music-night',
    title: 'Inter-Uni Music Night',
    university: 'LUMS',
    startAt: DateTime(2026, 5, 24, 19, 30),
    endAt: DateTime(2026, 5, 24, 23),
    location: 'Main Ground',
    category: 'Social',
    description:
        'Open mic, student bands, food stalls, and a relaxed place to meet new people.',
    goingCount: 112,
    interestedCount: 420,
    featured: true,
  ),
  CampusEvent(
    id: 'women-in-tech-panel',
    title: 'Women in Tech Panel',
    university: 'Habib University',
    startAt: DateTime(2026, 5, 27, 14),
    endAt: DateTime(2026, 5, 27, 16),
    location: 'Seminar Hall',
    category: 'Career',
    description:
        'Founders and engineers discuss internships, portfolios, and first jobs.',
    goingCount: 41,
    interestedCount: 96,
    featured: false,
  ),
  CampusEvent(
    id: 'case-study-championship',
    title: 'Case Study Championship',
    university: 'IBA Karachi',
    startAt: DateTime(2026, 5, 30, 10),
    endAt: DateTime(2026, 5, 30, 15),
    location: 'Business Block',
    category: 'Competition',
    description:
        'Solve a real company problem in teams and pitch your solution to judges.',
    goingCount: 58,
    interestedCount: 132,
    featured: false,
  ),
];

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScaffold(label: 'Checking account...');
        }

        final user = snapshot.data;
        if (user == null) {
          return const AuthScreen();
        }

        return UserProfileGate(user: user);
      },
    );
  }
}

class UserProfileGate extends StatefulWidget {
  const UserProfileGate({super.key, required this.user});

  final User user;

  @override
  State<UserProfileGate> createState() => _UserProfileGateState();
}

class _UserProfileGateState extends State<UserProfileGate> {
  late final Future<void> _bootstrap;

  @override
  void initState() {
    super.initState();
    _bootstrap = RealtimeDatabaseService.instance
        .ensureUserDocument(widget.user)
        .then((_) => RealtimeDatabaseService.instance.ensureSeedEvents());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrap,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingScaffold(label: 'Preparing CampusLoop...');
        }
        if (snapshot.hasError) {
          return SetupErrorScreen(error: snapshot.error.toString());
        }

        return StreamBuilder<UserProfile?>(
          stream: RealtimeDatabaseService.instance.userProfileStream(
            widget.user.uid,
          ),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const LoadingScaffold(label: 'Loading profile...');
            }
            return HomeScreen(profile: userSnapshot.data!);
          },
        );
      },
    );
  }
}

class LoadingScaffold extends StatelessWidget {
  const LoadingScaffold({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class SetupErrorScreen extends StatelessWidget {
  const SetupErrorScreen({super.key, required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _ErrorPanel(message: error),
          ),
        ),
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = true;
  bool _hidePassword = true;
  bool _submitting = false;
  String _selectedUniversity = karachiUniversities.first;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      if (_isSignUp) {
        await RealtimeDatabaseService.instance.signUp(
          name: _nameController.text.trim(),
          university: _selectedUniversity,
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await RealtimeDatabaseService.instance.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } on FirebaseAuthException catch (error) {
      setState(() => _error = _friendlyAuthError(error));
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _setMode(bool isSignUp) {
    setState(() {
      _isSignUp = isSignUp;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final buttonLabel = _isSignUp ? 'Create account' : 'Log in';
    final icon = _isSignUp
        ? Icons.person_add_alt_1_rounded
        : Icons.login_rounded;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _AuthHeader(),
                  const SizedBox(height: 18),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SegmentedButton<bool>(
                                segments: const [
                                  ButtonSegment<bool>(
                                    value: true,
                                    label: Text('Sign up'),
                                    icon: Icon(Icons.person_add_alt_1_rounded),
                                  ),
                                  ButtonSegment<bool>(
                                    value: false,
                                    label: Text('Log in'),
                                    icon: Icon(Icons.login_rounded),
                                  ),
                                ],
                                selected: {_isSignUp},
                                onSelectionChanged: (selection) {
                                  _setMode(selection.first);
                                },
                              ),
                              const SizedBox(height: 16),
                              if (_isSignUp) ...[
                                TextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Full name',
                                    prefixIcon: Icon(Icons.badge_outlined),
                                  ),
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.name],
                                  validator: (value) =>
                                      _validateRequired(value, 'Name'),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedUniversity,
                                  decoration: const InputDecoration(
                                    labelText: 'University',
                                    prefixIcon: Icon(Icons.school_outlined),
                                  ),
                                  items: [
                                    for (final university
                                        in karachiUniversities)
                                      DropdownMenuItem(
                                        value: university,
                                        child: Text(university),
                                      ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedUniversity = value;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 12),
                              ],
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                validator: _validateEmail,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    tooltip: _hidePassword
                                        ? 'Show password'
                                        : 'Hide password',
                                    onPressed: () {
                                      setState(() {
                                        _hidePassword = !_hidePassword;
                                      });
                                    },
                                    icon: Icon(
                                      _hidePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                                obscureText: _hidePassword,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                validator: _validatePassword,
                                onFieldSubmitted: (_) => _submit(),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 12),
                                _ErrorPanel(message: _error!),
                              ],
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: _submitting ? null : _submit,
                                icon: _submitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(icon),
                                label: Text(
                                  _submitting ? 'Please wait...' : buttonLabel,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF17252A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CampusLoop',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Discover university events and meet students across campus circles.',
            style: TextStyle(
              color: Color(0xFFDDF5F4),
              fontSize: 16,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _openEventRequest() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => EventRequestSheet(profile: widget.profile),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      EventsTab(profile: widget.profile),
      GlobalChatTab(profile: widget.profile),
      PeopleTab(profile: widget.profile),
      ProfileTab(profile: widget.profile),
      if (widget.profile.isAdmin) const AdminTab(),
    ];
    final destinations = [
      const NavigationDestination(
        icon: Icon(Icons.event_outlined),
        selectedIcon: Icon(Icons.event),
        label: 'Events',
      ),
      const NavigationDestination(
        icon: Icon(Icons.forum_outlined),
        selectedIcon: Icon(Icons.forum),
        label: 'Global',
      ),
      const NavigationDestination(
        icon: Icon(Icons.people_alt_outlined),
        selectedIcon: Icon(Icons.people_alt),
        label: 'People',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Profile',
      ),
      if (widget.profile.isAdmin)
        const NavigationDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
    ];

    final safeIndex = min(_selectedIndex, pages.length - 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CampusLoop',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Request event listing',
            onPressed: _openEventRequest,
            icon: const Icon(Icons.post_add_rounded),
          ),
        ],
      ),
      body: pages[safeIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: destinations,
      ),
    );
  }
}

class EventsTab extends StatelessWidget {
  const EventsTab({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CampusEvent>>(
      stream: RealtimeDatabaseService.instance.eventsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorList(message: snapshot.error.toString());
        }
        if (!snapshot.hasData) {
          return const LoadingList();
        }

        final events = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const _WelcomePanel(),
            const SizedBox(height: 16),
            Text(
              'Featured now',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            if (events.isEmpty)
              const EmptyState(
                icon: Icons.event_busy_rounded,
                title: 'No approved events yet',
                text: 'Use the top-right button to request the first listing.',
              ),
            for (final event in events)
              StreamBuilder<EventReaction?>(
                stream: RealtimeDatabaseService.instance.eventReactionStream(
                  profile.uid,
                  event.id,
                ),
                builder: (context, reactionSnapshot) {
                  return EventCard(
                    event: event,
                    reaction: reactionSnapshot.data,
                    onReact: (type) async {
                      try {
                        await RealtimeDatabaseService.instance.setEventReaction(
                          user: profile,
                          event: event,
                          type: type,
                        );
                      } catch (error) {
                        if (context.mounted) {
                          _showSnack(context, error.toString());
                        }
                      }
                    },
                    onOpenChat: () {
                      if (reactionSnapshot.data == null) {
                        _showSnack(
                          context,
                          'Mark Going or Interested to unlock this event chat.',
                        );
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              EventChatScreen(profile: profile, event: event),
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF17252A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Find campus events before they disappear in WhatsApp groups.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _MetricChip(
                icon: Icons.school_rounded,
                label: 'Karachi campuses',
              ),
              _MetricChip(icon: Icons.forum_rounded, label: 'Event chats'),
              _MetricChip(
                icon: Icons.verified_rounded,
                label: 'Admin reviewed',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFBEE9E8), size: 17),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.reaction,
    required this.onReact,
    required this.onOpenChat,
  });

  final CampusEvent event;
  final EventReaction? reaction;
  final ValueChanged<EventReactionType> onReact;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    final selectedType = reaction?.type;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.category.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF1F7A8C),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                if (event.featured)
                  const Chip(
                    label: Text('Featured'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(event.description),
            const SizedBox(height: 12),
            _InfoRow(icon: Icons.school_outlined, text: event.university),
            _InfoRow(icon: Icons.schedule_rounded, text: event.dateLabel),
            _InfoRow(icon: Icons.location_on_outlined, text: event.location),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ReactionButton(
                  type: EventReactionType.going,
                  selected: selectedType == EventReactionType.going,
                  count: event.goingCount,
                  onTap: () => onReact(EventReactionType.going),
                ),
                _ReactionButton(
                  type: EventReactionType.interested,
                  selected: selectedType == EventReactionType.interested,
                  count: event.interestedCount,
                  onTap: () => onReact(EventReactionType.interested),
                ),
                OutlinedButton.icon(
                  onPressed: onOpenChat,
                  icon: Icon(
                    event.chatClosed
                        ? Icons.lock_clock_outlined
                        : Icons.groups_2_outlined,
                  ),
                  label: Text(event.chatClosed ? 'Chat closed' : 'Event chat'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({
    required this.type,
    required this.selected,
    required this.count,
    required this.onTap,
  });

  final EventReactionType type;
  final bool selected;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = '${type.label} $count';
    if (selected) {
      return FilledButton.icon(
        onPressed: onTap,
        icon: Icon(type.icon),
        label: Text(label),
      );
    }
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(type.icon),
      label: Text(label),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF526166)),
          const SizedBox(width: 7),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class GlobalChatTab extends StatefulWidget {
  const GlobalChatTab({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<GlobalChatTab> createState() => _GlobalChatTabState();
}

class _GlobalChatTabState extends State<GlobalChatTab> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }
    _controller.clear();
    try {
      await RealtimeDatabaseService.instance.sendGlobalMessage(
        widget.profile,
        text,
      );
    } catch (error) {
      if (mounted) {
        _showSnack(context, error.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChatScaffold(
      title: 'Global campus chat',
      stream: RealtimeDatabaseService.instance.globalMessagesStream(),
      currentUid: widget.profile.uid,
      controller: _controller,
      onSend: _send,
      inputHint: 'Ask about events...',
    );
  }
}

class PeopleTab extends StatefulWidget {
  const PeopleTab({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<PeopleTab> createState() => _PeopleTabState();
}

class _PeopleTabState extends State<PeopleTab> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserProfile>>(
      stream: RealtimeDatabaseService.instance.usersStream(),
      builder: (context, usersSnapshot) {
        if (usersSnapshot.hasError) {
          return _ErrorList(message: usersSnapshot.error.toString());
        }
        if (!usersSnapshot.hasData) {
          return const LoadingList();
        }

        final users = usersSnapshot.data!
            .where((user) => user.uid != widget.profile.uid)
            .where((user) {
              if (_query.isEmpty) {
                return true;
              }
              final haystack = '${user.name} ${user.university} ${user.email}'
                  .toLowerCase();
              return haystack.contains(_query);
            })
            .toList();

        return StreamBuilder<Set<String>>(
          stream: RealtimeDatabaseService.instance.followingIdsStream(
            widget.profile.uid,
          ),
          builder: (context, followingSnapshot) {
            final following = followingSnapshot.data ?? {};
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search people or universities',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'People on CampusLoop',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                if (users.isEmpty)
                  const EmptyState(
                    icon: Icons.people_outline_rounded,
                    title: 'No people found',
                    text: 'Try another name or university.',
                  ),
                for (final user in users)
                  UserCard(
                    currentUser: widget.profile,
                    user: user,
                    following: following.contains(user.uid),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class UserCard extends StatelessWidget {
  const UserCard({
    super.key,
    required this.currentUser,
    required this.user,
    required this.following,
  });

  final UserProfile currentUser;
  final UserProfile user;
  final bool following;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: GeneratedAvatar(profile: user),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text('${user.university}\n${user.email}'),
        isThreeLine: true,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PublicProfileScreen(profile: user),
            ),
          );
        },
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton.filledTonal(
              tooltip: following ? 'Unfollow' : 'Follow',
              onPressed: () => RealtimeDatabaseService.instance.toggleFollow(
                currentUid: currentUser.uid,
                otherUid: user.uid,
                currentlyFollowing: following,
              ),
              icon: Icon(
                following
                    ? Icons.person_remove_alt_1_outlined
                    : Icons.person_add_alt_1_outlined,
              ),
            ),
            IconButton.filled(
              tooltip: 'Start chat',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PrivateChatScreen(
                      currentUser: currentUser,
                      otherUser: user,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GeneratedAvatar(profile: profile, radius: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${profile.university} - ${profile.email}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => RealtimeDatabaseService.instance.signOut(),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign out'),
        ),
        const SizedBox(height: 18),
        Text(
          'Your events',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<EventReaction>>(
          stream: RealtimeDatabaseService.instance.userEventsStream(
            profile.uid,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const LoadingList(compact: true);
            }
            final reactions = snapshot.data!;
            if (reactions.isEmpty) {
              return const EmptyState(
                icon: Icons.event_available_outlined,
                title: 'No saved events yet',
                text: 'Mark events as Going or Interested to see them here.',
              );
            }
            return Column(
              children: [
                for (final reaction in reactions)
                  EventPrivacyTile(profile: profile, reaction: reaction),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        const _BusinessTile(
          icon: Icons.workspace_premium_outlined,
          title: 'Featured event listings',
          text: 'Societies and brands can pay to promote events to students.',
        ),
        const _BusinessTile(
          icon: Icons.confirmation_number_outlined,
          title: 'Ticketing commission',
          text: 'Later, charge a small fee per paid event ticket sold.',
        ),
        const _BusinessTile(
          icon: Icons.verified_user_outlined,
          title: 'Organizer dashboard',
          text: 'Universities can manage posts, analytics, and registrations.',
        ),
      ],
    );
  }
}

class EventPrivacyTile extends StatelessWidget {
  const EventPrivacyTile({
    super.key,
    required this.profile,
    required this.reaction,
  });

  final UserProfile profile;
  final EventReaction reaction;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: SwitchListTile(
        value: reaction.isPublic,
        onChanged: (value) =>
            RealtimeDatabaseService.instance.setEventReactionPublic(
              uid: profile.uid,
              eventId: reaction.eventId,
              isPublic: value,
            ),
        secondary: Icon(reaction.type.icon, color: const Color(0xFF1F7A8C)),
        title: Text(
          reaction.eventTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${reaction.type.label} - ${reaction.eventUniversity}\n'
          '${reaction.isPublic ? 'Visible on public profile' : 'Private to you'}',
        ),
      ),
    );
  }
}

class PublicProfileScreen extends StatelessWidget {
  const PublicProfileScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(profile.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GeneratedAvatar(profile: profile, radius: 30),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(profile.university),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Public events',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<EventReaction>>(
            stream: RealtimeDatabaseService.instance.publicUserEventsStream(
              profile.uid,
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const LoadingList(compact: true);
              }
              final reactions = snapshot.data!;
              if (reactions.isEmpty) {
                return const EmptyState(
                  icon: Icons.visibility_off_outlined,
                  title: 'No public events',
                  text: 'This student has not shared event activity yet.',
                );
              }
              return Column(
                children: [
                  for (final reaction in reactions)
                    Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: Icon(reaction.type.icon),
                        title: Text(reaction.eventTitle),
                        subtitle: Text(
                          '${reaction.type.label} - ${reaction.eventUniversity}',
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class AdminTab extends StatelessWidget {
  const AdminTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EventRequest>>(
      stream: RealtimeDatabaseService.instance.pendingRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorList(message: snapshot.error.toString());
        }
        if (!snapshot.hasData) {
          return const LoadingList();
        }
        final requests = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(
              'Event review',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (requests.isEmpty)
              const EmptyState(
                icon: Icons.fact_check_outlined,
                title: 'No pending requests',
                text: 'Event requests will appear here for admin approval.',
              ),
            for (final request in requests) AdminRequestCard(request: request),
          ],
        );
      },
    );
  }
}

class AdminRequestCard extends StatelessWidget {
  const AdminRequestCard({super.key, required this.request});

  final EventRequest request;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              request.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(request.description),
            const SizedBox(height: 10),
            _InfoRow(icon: Icons.school_outlined, text: request.university),
            _InfoRow(
              icon: Icons.schedule_rounded,
              text: _formatDate(request.startAt),
            ),
            _InfoRow(icon: Icons.location_on_outlined, text: request.location),
            _InfoRow(
              icon: Icons.person_outline_rounded,
              text: '${request.requesterName} - ${request.requesterEmail}',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await RealtimeDatabaseService.instance.rejectRequest(
                          request,
                        );
                        if (context.mounted) {
                          _showSnack(context, 'Request rejected.');
                        }
                      } catch (error) {
                        if (context.mounted) {
                          _showSnack(context, error.toString());
                        }
                      }
                    },
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      try {
                        await RealtimeDatabaseService.instance.approveRequest(
                          request,
                        );
                        if (context.mounted) {
                          _showSnack(context, 'Event approved.');
                        }
                      } catch (error) {
                        if (context.mounted) {
                          _showSnack(context, error.toString());
                        }
                      }
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EventRequestSheet extends StatefulWidget {
  const EventRequestSheet({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<EventRequestSheet> createState() => _EventRequestSheetState();
}

class _EventRequestSheetState extends State<EventRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController(text: 'Social');
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startController = TextEditingController(text: '2026-05-30 14:00');
  final _endController = TextEditingController(text: '2026-05-30 16:00');
  String _university = karachiUniversities.first;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final startAt = _parseDateInput(_startController.text);
    final endAt = _parseDateInput(_endController.text);
    if (startAt == null || endAt == null || !endAt.isAfter(startAt)) {
      _showSnack(
        context,
        'Use valid start/end times. End must be after start.',
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await RealtimeDatabaseService.instance.requestEvent(
        user: widget.profile,
        title: _titleController.text.trim(),
        university: _university,
        category: _categoryController.text.trim(),
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
        startAt: startAt,
        endAt: endAt,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      _showSnack(context, 'Event request sent for admin review.');
    } catch (error) {
      if (mounted) {
        _showSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Request event listing',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Event title'),
                validator: (value) => _validateRequired(value, 'Title'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _university,
                decoration: const InputDecoration(labelText: 'University'),
                items: [
                  for (final university in karachiUniversities)
                    DropdownMenuItem(
                      value: university,
                      child: Text(university),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _university = value);
                  }
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (value) => _validateRequired(value, 'Category'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (value) => _validateRequired(value, 'Location'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _startController,
                decoration: const InputDecoration(
                  labelText: 'Start time',
                  hintText: '2026-05-30 14:00',
                ),
                validator: (value) => _validateRequired(value, 'Start time'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _endController,
                decoration: const InputDecoration(
                  labelText: 'End time',
                  hintText: '2026-05-30 16:00',
                ),
                validator: (value) => _validateRequired(value, 'End time'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) => _validateRequired(value, 'Description'),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(_saving ? 'Submitting...' : 'Submit for review'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EventChatScreen extends StatefulWidget {
  const EventChatScreen({
    super.key,
    required this.profile,
    required this.event,
  });

  final UserProfile profile;
  final CampusEvent event;

  @override
  State<EventChatScreen> createState() => _EventChatScreenState();
}

class _EventChatScreenState extends State<EventChatScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.event.chatClosed) {
      return;
    }
    _controller.clear();
    try {
      await RealtimeDatabaseService.instance.sendEventMessage(
        user: widget.profile,
        event: widget.event,
        text: text,
      );
    } catch (error) {
      if (mounted) {
        _showSnack(context, error.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChatPage(
      title: widget.event.title,
      subtitle: widget.event.chatClosed
          ? 'Closed 3 days after event end'
          : 'Group chat for people going/interested',
      stream: RealtimeDatabaseService.instance.eventMessagesStream(
        widget.event.id,
      ),
      currentUid: widget.profile.uid,
      controller: _controller,
      onSend: _send,
      inputHint: widget.event.chatClosed ? 'Chat closed' : 'Message event chat',
      inputEnabled: !widget.event.chatClosed,
    );
  }
}

class PrivateChatScreen extends StatefulWidget {
  const PrivateChatScreen({
    super.key,
    required this.currentUser,
    required this.otherUser,
  });

  final UserProfile currentUser;
  final UserProfile otherUser;

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }
    _controller.clear();
    try {
      await RealtimeDatabaseService.instance.sendPrivateMessage(
        sender: widget.currentUser,
        recipient: widget.otherUser,
        text: text,
      );
    } catch (error) {
      if (mounted) {
        _showSnack(context, error.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: RealtimeDatabaseService.instance.followsStream(
        widget.currentUser.uid,
        widget.otherUser.uid,
      ),
      builder: (context, mineSnapshot) {
        return StreamBuilder<bool>(
          stream: RealtimeDatabaseService.instance.followsStream(
            widget.otherUser.uid,
            widget.currentUser.uid,
          ),
          builder: (context, theirsSnapshot) {
            final mutual =
                (mineSnapshot.data ?? false) && (theirsSnapshot.data ?? false);
            return ChatPage(
              title: widget.otherUser.name,
              subtitle: mutual
                  ? 'You both follow each other'
                  : 'One intro message allowed before mutual follow',
              stream: RealtimeDatabaseService.instance.privateMessagesStream(
                widget.currentUser.uid,
                widget.otherUser.uid,
              ),
              currentUid: widget.currentUser.uid,
              controller: _controller,
              onSend: _send,
              inputHint: mutual
                  ? 'Message ${widget.otherUser.name}'
                  : 'Send intro',
            );
          },
        );
      },
    );
  }
}

class ChatPage extends StatelessWidget {
  const ChatPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.stream,
    required this.currentUid,
    required this.controller,
    required this.onSend,
    required this.inputHint,
    this.inputEnabled = true,
  });

  final String title;
  final String subtitle;
  final Stream<List<ChatMessage>> stream;
  final String currentUid;
  final TextEditingController controller;
  final VoidCallback onSend;
  final String inputHint;
  final bool inputEnabled;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: ChatScaffold(
        title: null,
        stream: stream,
        currentUid: currentUid,
        controller: controller,
        onSend: onSend,
        inputHint: inputHint,
        inputEnabled: inputEnabled,
      ),
    );
  }
}

class ChatScaffold extends StatelessWidget {
  const ChatScaffold({
    super.key,
    required this.title,
    required this.stream,
    required this.currentUid,
    required this.controller,
    required this.onSend,
    required this.inputHint,
    this.inputEnabled = true,
  });

  final String? title;
  final Stream<List<ChatMessage>> stream;
  final String currentUid;
  final TextEditingController controller;
  final VoidCallback onSend;
  final String inputHint;
  final bool inputEnabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (title != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              title!,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
        Expanded(
          child: StreamBuilder<List<ChatMessage>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _ErrorList(message: snapshot.error.toString());
              }
              if (!snapshot.hasData) {
                return const LoadingList();
              }
              final messages = snapshot.data!;
              if (messages.isEmpty) {
                return const EmptyState(
                  icon: Icons.forum_outlined,
                  title: 'No messages yet',
                  text: 'Start the conversation.',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: messages.length,
                itemBuilder: (context, index) => MessageBubble(
                  message: messages[index],
                  isMe: messages[index].senderId == currentUid,
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: inputEnabled,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(hintText: inputHint),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Send',
                  onPressed: inputEnabled ? onSend : null,
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message, required this.isMe});

  final ChatMessage message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isMe ? const Color(0xFF1F7A8C) : Colors.white;
    final textColor = isMe ? Colors.white : const Color(0xFF17252A);

    return Align(
      alignment: alignment,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 310),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              '${message.senderName} - ${message.senderUniversity}',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.72),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              message.text,
              style: TextStyle(color: textColor, fontSize: 15),
            ),
            const SizedBox(height: 5),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                color: textColor.withValues(alpha: 0.64),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GeneratedAvatar extends StatelessWidget {
  const GeneratedAvatar({super.key, required this.profile, this.radius = 24});

  final UserProfile profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final color = _avatarColor(profile.avatarSeed);
    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        _initials(profile.name),
        style: TextStyle(
          color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BusinessTile extends StatelessWidget {
  const _BusinessTile({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1F7A8C)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(text),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(icon, size: 44, color: const Color(0xFF526166)),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class LoadingList extends StatelessWidget {
  const LoadingList({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 48),
        child: const CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorList extends StatelessWidget {
  const _ErrorList({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [_ErrorPanel(message: message)],
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4E1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFB3261E)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF6B1D18),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String? _validateRequired(String? value, String label) {
  if (value == null || value.trim().isEmpty) {
    return '$label is required.';
  }
  return null;
}

String? _validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) {
    return 'Email is required.';
  }
  if (!email.contains('@') || !email.contains('.')) {
    return 'Enter a valid email address.';
  }
  return null;
}

String? _validatePassword(String? value) {
  final password = value ?? '';
  if (password.length < 6) {
    return 'Use at least 6 characters.';
  }
  return null;
}

String _friendlyAuthError(FirebaseAuthException error) {
  return switch (error.code) {
    'email-already-in-use' => 'An account already exists for that email.',
    'invalid-email' => 'Enter a valid email address.',
    'weak-password' => 'Use a password with at least 6 characters.',
    'user-not-found' => 'No account was found for that email.',
    'wrong-password' => 'Email or password is incorrect.',
    'invalid-credential' => 'Email or password is incorrect.',
    'operation-not-allowed' =>
      'Enable Email/Password sign-in in Firebase Authentication.',
    _ => error.message ?? error.code,
  };
}

DateTime? _parseDateInput(String value) {
  final normalized = value.trim().replaceFirst(' ', 'T');
  return DateTime.tryParse(normalized);
}

DateTime _asDate(Object? value, DateTime fallback) {
  if (value is DateTime) {
    return value;
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  if (value is String) {
    return DateTime.tryParse(value) ?? fallback;
  }
  return fallback;
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return {};
}

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return 0;
}

String _formatDate(DateTime value) {
  final months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return '${months[value.month - 1]} ${value.day}, $hour:$minute $period';
}

String _formatTime(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return 'CL';
  }
  if (parts.length == 1) {
    return parts.first.substring(0, min(2, parts.first.length)).toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

Color _avatarColor(String seed) {
  final colors = [
    const Color(0xFF1F7A8C),
    const Color(0xFF8A4FFF),
    const Color(0xFFE56B6F),
    const Color(0xFF2D6A4F),
    const Color(0xFFB56576),
    const Color(0xFF5E60CE),
    const Color(0xFF006D77),
    const Color(0xFF9A6324),
  ];
  final index = seed.codeUnits.fold<int>(0, (total, unit) => total + unit);
  return colors[index % colors.length];
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
