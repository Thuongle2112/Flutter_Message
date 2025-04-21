import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/app_user.dart';
import '../../models/app_user_model.dart';
import 'auth_datasource.dart';

class AuthDataSourceImpl implements AuthDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthDataSourceImpl(this._firebaseAuth, [FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<AppUser> login(String email, String password) async {
    try {
      // Clear any previous sessions to avoid conflicts
      if (_firebaseAuth.currentUser != null) {
        await _firebaseAuth.signOut();
      }

      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Login failed: No user returned');
      }

      // Ensure token is refreshed
      await userCredential.user!.getIdToken(true);

      // Fetch user data from Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User data not found in database');
      }

      return AppUserModel.fromMap({
        ...userDoc.data()!,
        'id': userCredential.user!.uid,
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No user found with this email');
      } else if (e.code == 'wrong-password') {
        throw Exception('Wrong password provided');
      } else if (e.code == 'invalid-credential') {
        throw Exception('Invalid email or password');
      } else if (e.code == 'user-disabled') {
        throw Exception('This account has been disabled');
      } else {
        throw Exception('Login failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  @override
  Future<AppUser> register(String name, String email, String password) async {
    try {
      // Clear any previous sessions to avoid conflicts
      if (_firebaseAuth.currentUser != null) {
        await _firebaseAuth.signOut();
      }

      // Create the Firebase Auth user first
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Registration failed: No user created');
      }

      // Update display name in Firebase Auth
      await userCredential.user!.updateDisplayName(name);

      try {
        // Ensure we're properly authenticated before writing to Firestore
        await userCredential.user!.getIdToken(true);

        // Create user profile in Firestore
        final newUser = AppUserModel(
          id: userCredential.user!.uid,
          name: name,
          email: email,
          photoUrl: null,
          createdAt: DateTime.now(),
          friendIds: const [], // Use const for empty lists
          friendRequestIds: const [], // Use const for empty lists
        );

        // Make sure we're using the user's ID for the document ID
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(newUser.toMap());

        return newUser;
      } catch (firestoreError) {
        // If Firestore write fails, delete the auth user to avoid orphaned accounts
        await userCredential.user!.delete();
        throw Exception('Failed to create user profile: $firestoreError');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('The password provided is too weak');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('An account already exists for that email');
      } else if (e.code == 'invalid-email') {
        throw Exception('The email address is not valid');
      } else {
        throw Exception('Registration failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;

      // Check if token is valid and refresh if needed
      try {
        await user.getIdToken(true);
      } catch (tokenError) {
        // If token refresh fails, the user is effectively signed out
        await _firebaseAuth.signOut();
        return null;
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        return null;
      }

      return AppUserModel.fromMap({
        ...userDoc.data()!,
        'id': user.uid,
      });
    } on FirebaseAuthException catch (e) {
      // Handle auth exceptions that might indicate the user is no longer valid
      if (e.code == 'user-token-expired' ||
          e.code == 'user-not-found' ||
          e.code == 'user-disabled') {
        await _firebaseAuth.signOut();
        return null;
      }
      throw Exception('Error getting current user: ${e.message}');
    } catch (e) {
      throw Exception('Error getting current user: $e');
    }
  }

  @override
  Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }

  @override
  Stream<AppUser?> userDataChanges() {
    return _firebaseAuth.authStateChanges().asyncMap((User? user) async {
      if (user == null) {
        return null;
      }

      try {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          return null;
        }

        return AppUserModel.fromMap({
          ...userDoc.data()!,
          'id': user.uid,
        });
      } catch (e) {
        print('Error in user data changes stream: $e');
        return null;
      }
    });
  }
}
