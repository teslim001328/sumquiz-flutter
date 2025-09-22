import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance; // Singleton
  final FirestoreService _firestoreService = FirestoreService();

  AuthService(this._auth);

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _firestoreService.saveUserData(result.user!); // Non-null after creation
      return result.user;
    } catch (e, s) {
      developer.log('Error creating user', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e, s) {
      developer.log('Error signing in with email and password', error: e, stackTrace: s);
      rethrow;
    }
  }


  Future<User?> signInWithGoogle() async {
    try {
      // 1. User-initiated sign-in
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // 2. Get auth details (synchronous - NO await)
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // 3. Create Firebase credential (idToken ONLY)
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase
      final UserCredential result = await _auth.signInWithCredential(credential);

      // 5. Save user data to Firestore
      await _firestoreService.saveUserData(result.user!); 

      return result.user;
    } catch (e, s) {
      developer.log('Error signing in with Google', error: e, stackTrace: s);
      rethrow; // Propagate to UI for loading state reset
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
