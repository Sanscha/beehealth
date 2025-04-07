import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'result_screen.dart';
import 'sidebar.dart';

class ResultsHistoryScreen extends StatefulWidget {
  const ResultsHistoryScreen({super.key});

  @override
  State<ResultsHistoryScreen> createState() => _ResultsHistoryScreenState();
}

class _ResultsHistoryScreenState extends State<ResultsHistoryScreen> {
  List<Map<String, String>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('scanHistory') ?? [];

    setState(() {
      _history = history
          .map((item) => Map<String, String>.from(jsonDecode(item)))
          .toList();
    });
  }

  void _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('scanHistory');
    setState(() {
      _history.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow.shade700,
        title: Text(
          'Scan History',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearHistory,
          ),
        ],
      ),
      // drawer: CustomSidebar(),
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
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
          _history.isEmpty
              ? Center(
            child: Card(
              color: Colors.white.withOpacity(0.8),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "No scan history available.",
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
            ),
          )
              : ListView.builder(
            itemCount: _history.length,
            itemBuilder: (context, index) {
              String imagePath = _history[index]["imagePath"]!;
              String analysisText = _history[index]["analysisText"]!;
              String detectedDisease = _history[index]["detectedDisease"] ?? "Unknown";
              String medicines = _history[index]["medicines"] ?? "No medicines found";

              File imageFile = File(imagePath);
              bool fileExists = imageFile.existsSync();

              return Card(
                margin: const EdgeInsets.all(10),
                elevation: 3,
                color: Colors.white.withOpacity(0.85),
                child: ListTile(
                  leading: fileExists
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.file(
                      imageFile,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  )
                      : const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                  title: Text(
                    analysisText.split('\n').first, // Show first line of analysis
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(),
                  ),
                  subtitle: Text(
                    "Disease: $detectedDisease",
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  onTap: () {
                    if (fileExists) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResultScreen(
                            imageFile: imageFile,
                            analysisText: analysisText,
                            detectedDisease: detectedDisease,
                            medicines: medicines,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Image file not found."),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}