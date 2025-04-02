import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database_helper.dart';
import 'login_screen.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> signUpWithEmailPassword(
      String email,
      String password,
      String username,
      String firstName,
      String lastName,
      ) async {
    try {
      // 1. Validate input fields
      if (email.isEmpty || password.isEmpty || username.isEmpty) {
        return "Please fill in all required fields";
      }

      // 2. Check if email is already in use
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        return "The email address is already in use. Please log in instead.";
      }

      // 3. Create user with email and password in Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final userId = userCredential.user!.uid;
      final userData = {
        "uid": userId,
        "email": email.trim(),
        "username": username.trim(),
        "firstName": firstName.trim(),
        "lastName": lastName.trim(),
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      };

      // 4. Save user details in Firestore (with transaction for reliability)
      await _firestore.runTransaction((transaction) async {
        final userDoc = _firestore.collection("users").doc(userId);
        transaction.set(userDoc, userData);
      });

      // 5. Save user details in SQLite database
      await DatabaseHelper.instance.insertUser({
        'userId': userId,
        'email': email.trim(),
        'username': username.trim(),
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        // Never store password in local database
      });

      // 6. Optional: Send email verification
      await userCredential.user!.sendEmailVerification();

      return null; // Success

    } on FirebaseAuthException catch (e) {
      // Handle specific FirebaseAuth exceptions
      switch (e.code) {
        case 'email-already-in-use':
          return "The email address is already in use.";
        case 'weak-password':
          return "Password should be at least 6 characters.";
        case 'invalid-email':
          return "The email address is invalid.";
        case 'operation-not-allowed':
          return "Email/password accounts are not enabled.";
        default:
          return "Registration failed: ${e.message}";
      }
    } on FirebaseException catch (e) {
      // Handle Firestore exceptions
      return "Failed to save user data: ${e.message}";
    } on Exception catch (e) {
      // Handle SQLite or other exceptions
      debugPrint("Registration error: $e");
      return "An unexpected error occurred. Please try again.";
    }
  }
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null; // Success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          return "The email address is invalid.";
        case 'user-not-found':
          return "No user found with this email address.";
        default:
          return "Password reset failed: ${e.message}";
      }
    } catch (e) {
      debugPrint("Password reset error: $e");
      return "An unexpected error occurred. Please try again.";
    }
  }
  // Login Function
  Future<User?> loginWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      throw Exception("Login failed: $e");
    }
  }

  // Logout Function
  Future<void> logout(BuildContext context) async {  // Add BuildContext parameter
    try {
      // 1. Sign out from authentication service
      await _auth.signOut();

      // 2. Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await prefs.remove('userEmail');

      // 3. Navigate to login screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${e.toString()}')),
      );
    }
  }}
