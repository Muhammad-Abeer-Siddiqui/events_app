import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const firebaseWebApiKey = String.fromEnvironment('FIREBASE_WEB_API_KEY');

void main() {
  runApp(const CampusLoopApp());
}

class CampusLoopApp extends StatelessWidget {
  const CampusLoopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CampusLoop',
      theme: ThemeData(
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
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  AuthSession? _session;

  void _setSession(AuthSession session) {
    setState(() {
      _session = session;
    });
  }

  void _signOut() {
    setState(() {
      _session = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    if (session == null) {
      return AuthScreen(onAuthenticated: _setSession);
    }

    return HomeScreen(session: session, onSignOut: _signOut);
  }
}

class AuthSession {
  const AuthSession({
    required this.name,
    required this.university,
    required this.email,
    this.idToken,
    this.isPreview = false,
  });

  final String name;
  final String university;
  final String email;
  final String? idToken;
  final bool isPreview;

  String get displayName {
    final trimmedName = name.trim();
    if (trimmedName.isNotEmpty) {
      return trimmedName;
    }
    return email.split('@').first;
  }

  String get campusLabel {
    final trimmedUniversity = university.trim();
    if (trimmedUniversity.isNotEmpty) {
      return trimmedUniversity;
    }
    return 'Campus student';
  }
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class FirebaseAuthApi {
  const FirebaseAuthApi({this.apiKey = firebaseWebApiKey});

  static const _baseUrl = 'https://identitytoolkit.googleapis.com/v1/accounts';

  final String apiKey;

  bool get isConfigured => apiKey.trim().isNotEmpty;

  Future<AuthSession> signUp({
    required String name,
    required String university,
    required String email,
    required String password,
  }) {
    return _authenticate(
      endpoint: 'signUp',
      name: name,
      university: university,
      email: email,
      password: password,
    );
  }

  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) {
    return _authenticate(
      endpoint: 'signInWithPassword',
      name: '',
      university: '',
      email: email,
      password: password,
    );
  }

  Future<AuthSession> _authenticate({
    required String endpoint,
    required String name,
    required String university,
    required String email,
    required String password,
  }) async {
    if (!isConfigured) {
      throw const AuthFailure('Firebase is not configured yet.');
    }

    final uri = Uri.parse('$_baseUrl:$endpoint?key=$apiKey');
    late final http.Response response;

    try {
      response = await http.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );
    } catch (_) {
      throw const AuthFailure('Could not reach Firebase. Check your internet.');
    }

    final decoded = jsonDecode(response.body);
    final data = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};

    if (response.statusCode >= 400) {
      throw AuthFailure(_friendlyFirebaseError(data));
    }

    final firebaseEmail = data['email']?.toString() ?? email;
    return AuthSession(
      name: name.trim().isEmpty ? firebaseEmail.split('@').first : name.trim(),
      university: university.trim(),
      email: firebaseEmail,
      idToken: data['idToken']?.toString(),
    );
  }

  String _friendlyFirebaseError(Map<String, dynamic> data) {
    final error = data['error'];
    final rawMessage = error is Map
        ? error['message']?.toString() ?? 'Authentication failed.'
        : 'Authentication failed.';

    if (rawMessage.startsWith('WEAK_PASSWORD')) {
      return 'Use a password with at least 6 characters.';
    }

    return switch (rawMessage) {
      'EMAIL_EXISTS' => 'An account already exists for that email.',
      'EMAIL_NOT_FOUND' => 'No account was found for that email.',
      'INVALID_LOGIN_CREDENTIALS' => 'Email or password is incorrect.',
      'INVALID_PASSWORD' => 'Email or password is incorrect.',
      'OPERATION_NOT_ALLOWED' =>
        'Enable Email/Password sign-in in Firebase Authentication.',
      'TOO_MANY_ATTEMPTS_TRY_LATER' =>
        'Too many attempts. Please wait and try again.',
      _ => rawMessage.replaceAll('_', ' ').toLowerCase(),
    };
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.onAuthenticated});

  final ValueChanged<AuthSession> onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _authApi = const FirebaseAuthApi();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _universityController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = true;
  bool _hidePassword = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _universityController.dispose();
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

    final name = _nameController.text.trim();
    final university = _universityController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final session = _authApi.isConfigured
          ? await _firebaseSession(
              name: name,
              university: university,
              email: email,
              password: password,
            )
          : await _previewSession(
              name: name,
              university: university,
              email: email,
            );

      if (!mounted) {
        return;
      }
      widget.onAuthenticated(session);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<AuthSession> _firebaseSession({
    required String name,
    required String university,
    required String email,
    required String password,
  }) {
    if (_isSignUp) {
      return _authApi.signUp(
        name: name,
        university: university,
        email: email,
        password: password,
      );
    }

    return _authApi.signIn(email: email, password: password);
  }

  Future<AuthSession> _previewSession({
    required String name,
    required String university,
    required String email,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return AuthSession(
      name: name.trim().isEmpty ? email.split('@').first : name.trim(),
      university: university.trim().isEmpty ? 'Campus student' : university.trim(),
      email: email,
      isPreview: true,
    );
  }

  void _setMode(bool isSignUp) {
    setState(() {
      _isSignUp = isSignUp;
      _error = null;
    });
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
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
                                TextFormField(
                                  controller: _universityController,
                                  decoration: const InputDecoration(
                                    labelText: 'University',
                                    prefixIcon: Icon(Icons.school_outlined),
                                  ),
                                  textInputAction: TextInputAction.next,
                                  validator: (value) =>
                                      _validateRequired(value, 'University'),
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
                                    tooltip:
                                        _hidePassword ? 'Show password' : 'Hide password',
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
                                label: Text(_submitting ? 'Please wait...' : buttonLabel),
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
            style: TextStyle(color: Color(0xFFDDF5F4), fontSize: 16, height: 1.35),
          ),
        ],
      ),
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

class CampusEvent {
  const CampusEvent({
    required this.title,
    required this.university,
    required this.date,
    required this.location,
    required this.category,
    required this.description,
    required this.attendees,
    required this.isFeatured,
  });

  final String title;
  final String university;
  final String date;
  final String location;
  final String category;
  final String description;
  final int attendees;
  final bool isFeatured;
}

class ChatMessage {
  const ChatMessage({
    required this.sender,
    required this.university,
    required this.text,
    required this.time,
    required this.isMe,
  });

  final String sender;
  final String university;
  final String text;
  final String time;
  final bool isMe;
}

class StudentContact {
  const StudentContact({
    required this.name,
    required this.university,
    required this.about,
    required this.lastMessage,
    required this.online,
  });

  final String name;
  final String university;
  final String about;
  final String lastMessage;
  final bool online;
}

const sampleEvents = [
  CampusEvent(
    title: 'AI Startup Weekend',
    university: 'FAST NUCES',
    date: 'Today, 4:00 PM',
    location: 'Auditorium A',
    category: 'Entrepreneurship',
    description:
        'Build a small AI idea, pitch it to mentors, and meet students from nearby universities.',
    attendees: 184,
    isFeatured: true,
  ),
  CampusEvent(
    title: 'Inter-Uni Music Night',
    university: 'LUMS',
    date: 'Tomorrow, 7:30 PM',
    location: 'Main Ground',
    category: 'Social',
    description:
        'Open mic, student bands, food stalls, and a relaxed place to meet new people.',
    attendees: 420,
    isFeatured: true,
  ),
  CampusEvent(
    title: 'Women in Tech Panel',
    university: 'ITU',
    date: 'May 27, 2:00 PM',
    location: 'Seminar Hall',
    category: 'Career',
    description:
        'Founders and engineers discuss internships, portfolios, and first jobs.',
    attendees: 96,
    isFeatured: false,
  ),
  CampusEvent(
    title: 'Case Study Championship',
    university: 'IBA',
    date: 'May 30, 10:00 AM',
    location: 'Business Block',
    category: 'Competition',
    description:
        'Solve a real company problem in teams and pitch your solution to judges.',
    attendees: 132,
    isFeatured: false,
  ),
];

const initialMessages = [
  ChatMessage(
    sender: 'Ayesha',
    university: 'FAST NUCES',
    text: 'Anyone going to AI Startup Weekend today?',
    time: '3:12 PM',
    isMe: false,
  ),
  ChatMessage(
    sender: 'Hamza',
    university: 'ITU',
    text: 'Yes. I heard teams can be formed at the venue too.',
    time: '3:14 PM',
    isMe: false,
  ),
  ChatMessage(
    sender: 'You',
    university: 'UCP',
    text: 'I am going after class. We can meet near registration.',
    time: '3:16 PM',
    isMe: true,
  ),
];

const contacts = [
  StudentContact(
    name: 'Ayesha Khan',
    university: 'FAST NUCES',
    about: 'CS student, likes hackathons and startup events.',
    lastMessage: 'See you at the entrance.',
    online: true,
  ),
  StudentContact(
    name: 'Hamza Ali',
    university: 'ITU',
    about: 'Design club volunteer and event photographer.',
    lastMessage: 'I can share the schedule.',
    online: true,
  ),
  StudentContact(
    name: 'Mina Tariq',
    university: 'LUMS',
    about: 'Looking for debate, music, and career events.',
    lastMessage: 'Music night sounds fun.',
    online: false,
  ),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.session,
    required this.onSignOut,
  });

  final AuthSession session;
  final VoidCallback onSignOut;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<ChatMessage> _messages = List.of(initialMessages);
  final TextEditingController _messageController = TextEditingController();
  final Set<String> _interestedEvents = {'AI Startup Weekend'};

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() {
      _messages.add(
        ChatMessage(
          sender: widget.session.displayName,
          university: widget.session.campusLabel,
          text: text,
          time: 'Now',
          isMe: true,
        ),
      );
      _messageController.clear();
    });
  }

  void _toggleInterest(CampusEvent event) {
    setState(() {
      if (_interestedEvents.contains(event.title)) {
        _interestedEvents.remove(event.title);
      } else {
        _interestedEvents.add(event.title);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      EventsTab(
        interestedEvents: _interestedEvents,
        onToggleInterest: _toggleInterest,
      ),
      GlobalChatTab(
        messages: _messages,
        controller: _messageController,
        onSend: _sendMessage,
      ),
      const PeopleTab(),
      ProfileTab(session: widget.session, onSignOut: widget.onSignOut),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CampusLoop',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: 'Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: 'Global',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_alt_outlined),
            selectedIcon: Icon(Icons.people_alt),
            label: 'People',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class EventsTab extends StatelessWidget {
  const EventsTab({
    super.key,
    required this.interestedEvents,
    required this.onToggleInterest,
  });

  final Set<String> interestedEvents;
  final ValueChanged<CampusEvent> onToggleInterest;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const _WelcomePanel(),
        const SizedBox(height: 16),
        Text(
          'Featured now',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        for (final event in sampleEvents)
          EventCard(
            event: event,
            isInterested: interestedEvents.contains(event.title),
            onToggleInterest: () => onToggleInterest(event),
          ),
      ],
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
              _MetricChip(icon: Icons.school_rounded, label: '8 universities'),
              _MetricChip(icon: Icons.campaign_rounded, label: '14 events'),
              _MetricChip(
                icon: Icons.trending_up_rounded,
                label: 'Sponsored slots ready',
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
    required this.isInterested,
    required this.onToggleInterest,
  });

  final CampusEvent event;
  final bool isInterested;
  final VoidCallback onToggleInterest;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
                if (event.isFeatured)
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
            _InfoRow(icon: Icons.schedule_rounded, text: event.date),
            _InfoRow(icon: Icons.location_on_outlined, text: event.location),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${event.attendees} interested',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                FilledButton.icon(
                  onPressed: onToggleInterest,
                  icon: Icon(
                    isInterested ? Icons.check_rounded : Icons.add_rounded,
                  ),
                  label: Text(isInterested ? 'Interested' : 'Join'),
                ),
              ],
            ),
          ],
        ),
      ),
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

class GlobalChatTab extends StatelessWidget {
  const GlobalChatTab({
    super.key,
    required this.messages,
    required this.controller,
    required this.onSend,
  });

  final List<ChatMessage> messages;
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: const Text(
            'Global campus chat',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: messages.length,
            itemBuilder: (context, index) => MessageBubble(
              message: messages[index],
            ),
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
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Ask about events...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Send',
                  onPressed: onSend,
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
  const MessageBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final alignment = message.isMe ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = message.isMe ? const Color(0xFF1F7A8C) : Colors.white;
    final textColor = message.isMe ? Colors.white : const Color(0xFF17252A);

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
          crossAxisAlignment:
              message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              '${message.sender} - ${message.university}',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.72),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(message.text, style: TextStyle(color: textColor, fontSize: 15)),
            const SizedBox(height: 5),
            Text(
              message.time,
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

class PeopleTab extends StatelessWidget {
  const PeopleTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'People open to chat',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        for (final contact in contacts) ContactCard(contact: contact),
      ],
    );
  }
}

class ContactCard extends StatelessWidget {
  const ContactCard({super.key, required this.contact});

  final StudentContact contact;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor:
              contact.online ? const Color(0xFFBEE9E8) : const Color(0xFFE2E6E5),
          child: Text(contact.name.characters.first),
        ),
        title: Text(
          contact.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('${contact.university}\n${contact.about}'),
        ),
        isThreeLine: true,
        trailing: IconButton.filledTonal(
          tooltip: 'Start private chat',
          onPressed: () {},
          icon: const Icon(Icons.chat_bubble_outline_rounded),
        ),
      ),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({
    super.key,
    required this.session,
    required this.onSignOut,
  });

  final AuthSession session;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: Color(0xFFBEE9E8),
                  child: Icon(Icons.person, size: 34, color: Color(0xFF17252A)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.displayName,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${session.campusLabel} - ${session.email}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onSignOut,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign out'),
        ),
        const SizedBox(height: 14),
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
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1F7A8C)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(text),
      ),
    );
  }
}
