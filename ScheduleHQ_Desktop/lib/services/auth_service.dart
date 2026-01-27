import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

/// Service for managing Firebase authentication
class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Cloud Run URLs for Firebase v2 callable functions
  // Format: https://[function-name]-[project-hash].[region].run.app
  static const String _createAccountUrl = 
      'https://createmanageraccountwithauthcode-to5pidma6a-uc.a.run.app';
  static const String _getAuthCodeUrl = 
      'https://getmanagerauthcode-to5pidma6a-uc.a.run.app';

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

  /// Create a new manager account via Cloud Function with auth code validation
  Future<UserCredential> createManagerAccount({
    required String email,
    required String password,
    required String authCode,
    String? displayName,
  }) async {
    try {
      // Call Cloud Function via HTTP (works on all platforms including Windows)
      final response = await http.post(
        Uri.parse(_createAccountUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'data': {
            'email': email,
            'password': password,
            'displayName': displayName,
            'authCode': authCode,
          }
        }),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode != 200) {
        final error = responseData['error'] ?? {};
        final errorCode = error['status'] ?? 'unknown';
        final errorMessage = error['message'] ?? 'Failed to create account';
        
        log('Create account error: $errorCode - $errorMessage', name: 'AuthService');
        
        // Convert error codes to user-friendly messages
        if (errorCode == 'PERMISSION_DENIED' || errorMessage.contains('Invalid authorization')) {
          throw FirebaseAuthException(
            code: 'invalid-auth-code',
            message: 'Invalid authorization code',
          );
        } else if (errorCode == 'ALREADY_EXISTS' || errorMessage.contains('already exists')) {
          throw FirebaseAuthException(
            code: 'email-already-in-use',
            message: 'An account with this email already exists',
          );
        } else if (errorCode == 'FAILED_PRECONDITION') {
          throw FirebaseAuthException(
            code: 'not-configured',
            message: errorMessage,
          );
        } else {
          throw FirebaseAuthException(
            code: errorCode,
            message: errorMessage,
          );
        }
      }

      final result = responseData['result'] ?? responseData;
      if (result['success'] != true) {
        throw FirebaseAuthException(
          code: 'creation-failed',
          message: result['message'] ?? 'Failed to create account',
        );
      }

      // Sign in with the newly created account
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      log('Manager account created: $email', name: 'AuthService');
      return credential;
    } catch (e) {
      log('Create account error: $e', name: 'AuthService');
      rethrow;
    }
  }

  /// Get the current manager authorization code (managers only)
  Future<String?> getManagerAuthCode() async {
    try {
      final idToken = await _auth.currentUser?.getIdToken();
      if (idToken == null) {
        throw FirebaseAuthException(
          code: 'unauthenticated',
          message: 'Must be logged in to get auth code',
        );
      }

      final response = await http.post(
        Uri.parse(_getAuthCodeUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'data': {}}),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body)['error'] ?? {};
        throw FirebaseAuthException(
          code: error['status'] ?? 'unknown',
          message: error['message'] ?? 'Failed to get authorization code',
        );
      }

      final result = jsonDecode(response.body)['result'] ?? jsonDecode(response.body);
      return result['code'] as String?;
    } catch (e) {
      log('Get auth code error: $e', name: 'AuthService');
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
