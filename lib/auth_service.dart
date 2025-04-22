import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database_helper.dart';
import 'login_screen.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

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

      // 3. Create user with email and password
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
        "createdAt": DateTime.now().toIso8601String(),
        "updatedAt": DateTime.now().toIso8601String(),
      };

      // 4. Save user details in Firebase Realtime Database
      await _database.ref("users/$userId").set(userData);

      // 5. Save in SQLite
      await DatabaseHelper.instance.insertUser({
        'userId': userId,
        'email': email.trim(),
        'username': username.trim(),
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
      });

      // 6. Optional email verification
      await userCredential.user!.sendEmailVerification();

      return null; // Success

    } on FirebaseAuthException catch (e) {
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
    } catch (e) {
      debugPrint("Registration error: $e");
      return "An unexpected error occurred. Please try again.";
    }
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
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

  Future<User?> loginWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      sharedPreferences.setString('email', email.trim());
      return userCredential.user;
    } catch (e) {
      throw Exception("Login failed: $e");
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      await _auth.signOut();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await prefs.remove('userEmail');

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${e.toString()}')),
      );
    }
  }
}
