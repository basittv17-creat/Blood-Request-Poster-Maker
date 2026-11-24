import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

final _invitePattern = RegExp(r'^https://chat\.whatsapp\.com/[A-Za-z0-9]{22}$');

String? canonicalInvite(String input) {
  final uri = Uri.tryParse(input.trim());
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.authority != 'chat.whatsapp.com') {
    return null;
  }
  final invite = 'https://chat.whatsapp.com${uri.path}';
  return _invitePattern.hasMatch(invite) ? invite : null;
}

class DonationGroups {
  DonationGroups._(FirebaseApp app)
    : auth = FirebaseAuth.instanceFor(app: app),
      db = FirebaseFirestore.instanceFor(app: app);

  static final _apps = <String, Future<FirebaseApp>>{};

  static Future<FirebaseApp> _initialize(String name) async {
    final app = await Firebase.initializeApp();
    if (name == 'directory') return app;
    return Firebase.initializeApp(name: name, options: app.options);
  }

  static Future<DonationGroups> connect({required bool admin}) async {
    final name = admin ? 'moderation' : 'directory';
    try {
      final app = await (_apps[name] ??= _initialize(name));
      return DonationGroups._(app);
    } catch (_) {
      _apps.remove(name);
      rethrow;
    }
  }

  final FirebaseAuth auth;
  final FirebaseFirestore db;
  late final approvedStream = approved.snapshots();
  late final pendingStream = pending
      .snapshots(includeMetadataChanges: true)
      .where((snapshot) => !snapshot.metadata.isFromCache);

  CollectionReference<Map<String, dynamic>> get approved =>
      db.collection('donationGroups');
  CollectionReference<Map<String, dynamic>> get pending =>
      db.collection('groupRequests');

  Future<void> submit(Map<String, String> group) async {
    if (auth.currentUser?.isAnonymous == false) await auth.signOut();
    final visitor = auth.currentUser ?? (await auth.signInAnonymously()).user!;
    await pending.doc(visitor.uid).set(group);
  }

  Future<void> login(String email, String password) async {
    final admin = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    try {
      final role = await db
          .collection('admins')
          .doc(admin.user!.uid)
          .get(const GetOptions(source: Source.server));
      if (!role.exists) throw StateError('Admin authorization required');
    } catch (_) {
      await auth.signOut();
      rethrow;
    }
  }

  Future<void> approve(DocumentReference<Map<String, dynamic>> request) async {
    final group = approved.doc();
    await db.runTransaction((transaction) async {
      final snapshot = await transaction.get(request);
      final data = snapshot.data();
      if (data == null) throw StateError('Request already reviewed');
      transaction.set(group, data);
      transaction.delete(request);
    });
  }
}
