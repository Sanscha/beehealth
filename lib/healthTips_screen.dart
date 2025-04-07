import 'package:BeeSentinel/sidebar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class HealthtipsScreen extends StatefulWidget {
  const HealthtipsScreen({super.key});

  @override
  State<HealthtipsScreen> createState() => _HealthtipsScreenState();
}

class _HealthtipsScreenState extends State<HealthtipsScreen> {
  late GenerativeModel _model;
  String _healthTips = "";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: 'AIzaSyCm0P159Sw13W6GbJ84m7sN08yCQWn4PEQ',
    );
    _fetchHealthTips();
  }

  Future<void> _fetchHealthTips() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _model.generateContent([
        Content.text(
            "Provide 10 concise health tips for honeybees in bullet point format (start each with •). "
                "Include disease prevention, colony health, and hive maintenance. "
                "Return only the bullet points without any additional text."
        )
      ]);

      setState(() {
        _healthTips = response.text?.replaceAll('•', '•') ?? "❌ No response from AI.";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _healthTips = "❌ Failed to load health tips. Please try again.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow.shade700,
        title: Text(
          'Bee Sentinell Tips',
          style: GoogleFonts.poppins(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      // drawer: CustomSidebar(),
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/statistical_background.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Semi-transparent overlay
          Container(
            color: Colors.black.withOpacity(0.2),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isLoading
                ? Center(
              child: LoadingAnimationWidget.hexagonDots(
                color: Colors.yellow.shade700,
                size: 40,
              ),
            )
                : Card(
              color: Colors.white.withOpacity(0.85),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Text(
                    _healthTips,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}