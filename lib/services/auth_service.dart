import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<User?> get authState => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    String? inviteCode,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;
    await cred.user!.updateDisplayName(name.trim());

    String householdId;

    if (inviteCode != null && inviteCode.trim().isNotEmpty) {
      householdId = inviteCode.trim();
      await _db.collection('households').doc(householdId).update({
        'members.$uid': 'member',
      });
    } else {
      final doc = _db.collection('households').doc();
      householdId = doc.id;
      await doc.set({
        'name': 'Casa de ${name.trim()}',
        'members': {uid: 'owner'},
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await _db.collection('users').doc(uid).set({
      'displayName': name.trim(),
      'email': email.trim(),
      'householdId': householdId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String?> loadHouseholdId() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['householdId'] as String?;
  }

  Future<void> signOut() => _auth.signOut();

  String messageFor(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'E-mail inválido';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'E-mail ou senha incorretos';
        case 'email-already-in-use':
          return 'Este e-mail já está cadastrado';
        case 'weak-password':
          return 'A senha precisa ter ao menos 6 caracteres';
        case 'network-request-failed':
          return 'Sem conexão com a internet';
      }
    }
    return 'Não foi possível continuar. Tente novamente';
  }
}