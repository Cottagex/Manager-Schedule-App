import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing Firebase authentication
class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Current logged in user
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Whether a user is currently signed in
  bool get isSignedIn => currentUser != null;

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Verify user has manager role
      if (credential.user != null) {
        final isManager = await _checkManagerRole(credential.user!.uid);
        if (!isManager) {
          await signOut();
          throw FirebaseAuthException(
            code: 'not-manager',
            message: 'This account does not have manager access.',
          );
        }
      }
      
      log('User signed in: ${credential.user?.email}', name: 'AuthService');
      return credential;
    } catch (e) {
      log('Sign in error: $e', name: 'AuthService');
      rethrow;
    }
  }

  /// Check if the user has manager role in Firestore
  Future<bool> _checkManagerRole(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        // First time manager login - create the user doc with manager role
        // This should only happen for the initial manager setup
        await _firestore.collection('users').doc(uid).set({
          'email': currentUser?.email,
          'role': 'manager',
          'createdAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
      return userDoc.data()?['role'] == 'manager';
    } catch (e) {
      log('Error checking manager role: $e', name: 'AuthService');
      // If we can't check, allow access (Firestore rules will protect data)
      return true;
    }
  }

  /// Create a new manager account
  Future<UserCredential> createManagerAccount({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document with manager role
      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'email': email,
          'displayName': displayName,
          'role': 'manager',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Update display name if provided
        if (displayName != null && displayName.isNotEmpty) {
          await credential.user!.updateDisplayName(displayName);
        }
      }

      log('Manager account created: $email', name: 'AuthService');
      return credential;
    } catch (e) {
      log('Create account error: $e', name: 'AuthService');
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
    log('Password reset email sent to: $email', name: 'AuthService');
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    log('User signed out', name: 'AuthService');
  }

  /// Get current user's email
  String? get currentUserEmail => currentUser?.email;

  /// Get current user's UID
  String? get currentUserUid => currentUser?.uid;
}

/// Custom exception for Firebase Auth errors
class FirebaseAuthException implements Exception {
  final String code;
  final String message;

  FirebaseAuthException({required this.code, required this.message});

  @override
  String toString() => 'FirebaseAuthException: $message (code: $code)';
}

/// Helper to get user-friendly error messages from Firebase Auth errors
String getAuthErrorMessage(dynamic error) {
  if (error is FirebaseAuthException) {
    return error.message;
  }
  
  if (error is FirebaseException) {
    switch (error.code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return error.message ?? 'An error occurred. Please try again.';
    }
  }
  
  return error.toString();
}
