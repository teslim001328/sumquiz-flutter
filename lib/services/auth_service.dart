import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:myapp/services/referral_service.dart';
import 'package:rxdart/rxdart.dart';

class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final ReferralService _referralService = ReferralService();

  AuthService(this._auth);

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Stream<UserModel?> get user {
    return _auth.authStateChanges().switchMap((user) {
      if (user == null) {
        return Stream.value(null);
      }
      return _firestoreService.streamUser(user.uid);
    });
  }

  Future<void> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential result =
          await _auth.signInWithCredential(credential);
      final user = result.user;

      if (user != null) {
        final isNewUser = result.additionalUserInfo?.isNewUser ?? false;
        if (isNewUser) {
          developer.log('New user signed in with Google: ${user.uid}');
          UserModel newUser = UserModel(
            uid: user.uid,
            displayName: user.displayName ?? '',
            email: user.email ?? '',
          );
          await _firestoreService.saveUserData(newUser);
        } else {
          developer.log('Existing user signed in with Google: ${user.uid}');
        }
      }
    } on FirebaseAuthException catch (e, s) {
      developer.log('Error signing in with Google', error: e, stackTrace: s);
      rethrow;
    } catch (e, s) {
      developer.log('An unexpected error occurred during Google Sign-In',
          error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e, s) {
      developer.log('Error signing in with email', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> signUpWithEmailAndPassword(
      String email, String password, String fullName, String? referralCode) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = result.user;

      if (user != null) {
        // 1. Create the user model.
        UserModel newUser = UserModel(
          uid: user.uid,
          displayName: fullName,
          email: user.email ?? '',
        );

        // 2. Save the basic user data to Firestore.
        await _firestoreService.saveUserData(newUser);

        // 3. If a referral code was provided, apply it.
        // The ReferralService handles rewards for both referrer and invitee.
        if (referralCode != null && referralCode.isNotEmpty) {
          await _referralService.applyReferralCode(referralCode, user.uid);
        }

        developer.log('New user created from email sign up: ${user.uid}');
      }
    } on FirebaseAuthException catch (e, s) {
      developer.log('Error signing up with email', error: e, stackTrace: s);
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

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e, s) {
      developer.log('Error sending password reset email', error: e, stackTrace:s);
      rethrow;
    }
  }

  User? get currentUser => _auth.currentUser;
}
