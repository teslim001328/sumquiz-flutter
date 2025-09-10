import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get user => _auth.authStateChanges();

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // The user canceled the sign-in
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        await _createUserDocument(user.uid, user.displayName ?? 'No Name', user.email ?? '');
      }
      return user;
    } catch (e, s) {
      Logger.error('Error during Google Sign-In', e, s);
      return null;
    }
  }

  Future<User?> signUpWithEmail(String email, String password, String name) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = userCredential.user;

      if (user != null) {
        await _createUserDocument(user.uid, name, email);
      }
      return user;
    } catch (e, s) {
      Logger.error('Error during Email/Password Sign-Up', e, s);
      return null;
    }
  }

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e, s) {
      Logger.error('Error during Email/Password Sign-In', e, s);
      return null;
    }
  }

  Future<void> _createUserDocument(String uid, String name, String email) async {
    final userRef = _db.collection('users').doc(uid);
    final doc = await userRef.get();

    if (!doc.exists) {
      userRef.set({
        'name': name,
        'email': email,
        'subscription_status': 'Free',
        'daily_usage': {'summaries': 0, 'quizzes': 0, 'flashcards': 0},
        'last_reset': Timestamp.now(),
      });
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e, s) {
      Logger.error('Error signing out', e, s);
    }
  }
}
