import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();

  bool _obscurePassword = true;
  bool _isPasswordValid = false;
  String _passwordErrorText = '';

  // Password validation rules
  final RegExp _passwordRegex = RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$', // At least 8 chars with letters and numbers
  );

  void _validatePassword(String value) {
    setState(() {
      if (value.isEmpty) {
        _isPasswordValid = false;
        _passwordErrorText = '';
      } else if (value.length < 8) {
        _isPasswordValid = false;
        _passwordErrorText = 'Password must be at least 8 characters';
      } else if (!_passwordRegex.hasMatch(value)) {
        _isPasswordValid = false;
        _passwordErrorText = 'Password must contain letters and numbers';
      } else {
        _isPasswordValid = true;
        _passwordErrorText = '';
      }
    });
  }

  void signUp() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final username = usernameController.text.trim();
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();

    if (email.isEmpty || username.isEmpty || firstName.isEmpty || lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (!_isPasswordValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid password')),
      );
      return;
    }

    try {
      await authService.signUpWithEmailPassword(email, password, username, firstName, lastName);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account Created Successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/login_background.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Semi-transparent overlay
          Container(
            color: Colors.black.withOpacity(0.3),
          ),

          // Centered content
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Bee animation
                  Lottie.asset(
                    'assets/animation/bee.json',
                    width: 150,
                    height: 150,
                  ),
                  const SizedBox(height: 20),

                  // Sign up form container
                  Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Create Account",
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Username Field
                        TextField(
                          controller: usernameController,
                          decoration: InputDecoration(
                            labelText: "Username",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // First Name Field
                        TextField(
                          controller: firstNameController,
                          decoration: InputDecoration(
                            labelText: "First Name",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Last Name Field
                        TextField(
                          controller: lastNameController,
                          decoration: InputDecoration(
                            labelText: "Last Name",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Email Field
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: "Email",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Password Field with visibility toggle and validation
                        TextField(
                          controller: passwordController,
                          obscureText: _obscurePassword,
                          onChanged: _validatePassword,
                          decoration: InputDecoration(
                            labelText: "Password",
                            errorText: _passwordErrorText.isNotEmpty ? _passwordErrorText : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Password requirements
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Password must:",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "• Be at least 8 characters",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: _passwordErrorText.contains('8 characters')
                                      ? Colors.red
                                      : Colors.grey[700],
                                ),
                              ),
                              Text(
                                "• Contain both letters and numbers",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: _passwordErrorText.contains('letters and numbers')
                                      ? Colors.red
                                      : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Sign Up Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: signUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow[700],
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              "Sign Up",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Login Navigation
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "Already have an account? Log In",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}