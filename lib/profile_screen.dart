import 'package:BeeSentinel/forgot_password_screen.dart';
import 'package:BeeSentinel/sidebar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _userProfile;
  bool _isLoading = true;
  String? _errorMessage;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final User? user = _auth.currentUser;
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      String? email = user?.email ?? sharedPreferences.getString('email');

      if (email == null) {
        throw Exception('No authenticated user found and no email in SharedPreferences');
      }

      final userData = await DatabaseHelper.instance.getUserByEmail(email);
      if (userData != null) {
        _updateProfile(userData);
      } else {
        throw Exception('No user data found in local database for email: $email');
      }
    } catch (e) {
      _handleError('Error loading profile: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  void _updateProfile(Map<String, dynamic> data) {
    setState(() {
      _userProfile = UserProfile(
        userId: data['userId'] ?? '',
        email: data['email'] ?? '',
        username: data['username'] ?? '',
        firstName: data['firstName'] ?? '',
        lastName: data['lastName'] ?? '',
      );
      _errorMessage = null;
    });
  }

  void _handleError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow.shade700,
        elevation: 0,
        title: Text(
          'My Profile',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadUserData,
          ),
        ],
      ),
      drawer: CustomSidebar(),

      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildBody(),
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow.shade700,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    "Log Out",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 5,),

          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.yellow));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            _errorMessage!,
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_userProfile == null) {
      return Center(
        child: Text(
          'No profile data found',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 16,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile Header Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.yellow.shade700.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              children: [
                // Profile Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.yellow.shade700,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      _userProfile!.firstName.isNotEmpty && _userProfile!.lastName.isNotEmpty
                          ? '${_userProfile!.firstName[0]}${_userProfile!.lastName[0]}'
                          : '?',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_userProfile!.firstName} ${_userProfile!.lastName}',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _userProfile!.username,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _userProfile!.email,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Profile Details Section
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildDetailCard(
                  icon: Icons.person_outline,
                  title: 'Personal Information',
                  items: [
                    _buildDetailItem('First Name', _userProfile!.firstName),
                    _buildDetailItem('Last Name', _userProfile!.lastName),
                  ],
                ),
                const SizedBox(height: 20),
                _buildDetailCard(
                  icon: Icons.alternate_email,
                  title: 'Account Information',
                  items: [
                    _buildDetailItem('Username', _userProfile!.username),
                    _buildDetailItem('Email', _userProfile!.email),
                  ],
                ),
                const SizedBox(height: 30),
                // Logout Button

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required List<Widget> items,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.yellow.shade700, size: 24),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isNotEmpty ? value : 'Not provided',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const Divider(height: 20, thickness: 0.5),
        ],
      ),
    );
  }
}

class UserProfile {
  final String userId;
  final String email;
  final String username;
  final String firstName;
  final String lastName;

  UserProfile({
    required this.userId,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
  });
}