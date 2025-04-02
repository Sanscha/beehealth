import 'package:BeeSentinel/sidebar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'database_helper.dart';

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
      if (user == null || user.email == null) {
        throw Exception('No authenticated user found');
      }

      final userData = await DatabaseHelper.instance.getUserByEmail(user.email!);
      if (userData != null) {
        _updateProfile(userData);
      } else {
        throw Exception('No user data found in local database');
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
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),

        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadUserData,
          ),
        ],
      ),
      drawer:  CustomSidebar(),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/account_background.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _errorMessage != null
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              _errorMessage!,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        )
            : _userProfile == null
            ? Center(
          child: Text(
            'No profile data found',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        )
            : _buildProfileContent(),
      ),
    );
  }

  Widget _buildProfileContent() {
    return Column(
      children: [
        const SizedBox(height: 20),
        // Profile Header
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
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
                    const SizedBox(height: 15),

                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        // Profile Details
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildDetailCard(
                  icon: Icons.person_outline,
                  title: 'Personal Info',
                  items: [
                    _buildDetailItem('First Name', _userProfile!.firstName),
                    _buildDetailItem('Last Name', _userProfile!.lastName),
                  ],
                ),
                const SizedBox(height: 20),
                _buildDetailCard(
                  icon: Icons.alternate_email,
                  title: 'Account Info',
                  items: [
                    _buildDetailItem('Username', _userProfile!.username),
                    _buildDetailItem('Email', _userProfile!.email),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required List<Widget> items,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0,vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.black, size: 22),
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