import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:myapp/models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirestoreService _firestoreService = FirestoreService();

  AuthService(this._auth);

  Future<void> initializeGoogleSignIn({String? clientId, String? serverClientId}) async {
    try {
      await _googleSignIn.initialize(
        clientId: clientId,
        serverClientId: serverClientId,
      );
    } catch (e, s) {
      developer.log('Error initializing Google Sign In', error: e, stackTrace: s);
      rethrow;
    }
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      UserModel newUser = UserModel(
        uid: result.user!.uid,
        email: email,
        name: '', // Or a default name
        subscriptionStatus: 'Free',
        dailyUsage: {},
        lastReset: Timestamp.now(),
      );
      await _firestoreService.saveUserData(newUser);
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
      final googleAccount = await _googleSignIn.signIn();
      
      if (googleAccount == null) {
        // User canceled the sign-in
        return null;
      }

      final googleAuth = await googleAccount.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result = await _auth.signInWithCredential(credential);

      if (result.additionalUserInfo?.isNewUser ?? false) {
        UserModel newUser = UserModel(
          uid: result.user!.uid,
          email: result.user!.email ?? '',
          name: result.user!.displayName ?? '',
          subscriptionStatus: 'Free',
          dailyUsage: {},
          lastReset: Timestamp.now(),
        );
        await _firestoreService.saveUserData(newUser);
      }

      return result.user;
    } catch (e, s) {
      developer.log('Error signing in with Google', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e, s) {
      developer.log('Error signing out', error: e, stackTrace: s);
      rethrow;
    }
  }

  User? get currentUser => _auth.currentUser;

  bool get isSignedIn => _auth.currentUser != null;
}