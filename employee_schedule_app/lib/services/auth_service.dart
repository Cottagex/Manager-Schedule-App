import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for handling Firebase Authentication for employees
class AuthService {
  static final AuthService _instance = AuthService._internal();
  static AuthService get instance => _instance;
  
  AuthService._internal();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Get current user
  User? get currentUser => _auth.currentUser;
  
  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
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
      
      // Verify this is an employee account (not a manager)
      final userDoc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();
      
      if (userDoc.exists && userDoc.data()?['role'] == 'manager') {
        // Sign out and throw error - managers should use the manager app
        await _auth.signOut();
        throw EmployeeAuthException(
          code: 'wrong-app',
          message: 'Manager accounts should use the Manager Schedule App',
        );
      }
      
      log('Employee signed in: ${credential.user?.email}', name: 'AuthService');
      return credential;
    } catch (e) {
      log('Sign in error: $e', name: 'AuthService');
      rethrow;
    }
  }
  
  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    log('User signed out', name: 'AuthService');
  }
  
  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
    log('Password reset email sent to $email', name: 'AuthService');
  }
  
  /// Get employee data from Firestore
  Future<Map<String, dynamic>?> getEmployeeData() async {
    final user = currentUser;
    if (user == null) return null;
    
    // Find employee doc by uid
    final query = await _firestore
        .collection('employees')
        .where('uid', isEqualTo: user.uid)
        .limit(1)
        .get();
    
    if (query.docs.isEmpty) return null;
    
    return query.docs.first.data();
  }
  
  /// Get employee's local ID (from manager app)
  Future<int?> getEmployeeLocalId() async {
    final data = await getEmployeeData();
    return data?['localId'] as int?;
  }
}

/// Custom exception for Employee Auth
class EmployeeAuthException implements Exception {
  final String code;
  final String message;
  
  EmployeeAuthException({required this.code, required this.message});
  
  @override
  String toString() => message;
}
