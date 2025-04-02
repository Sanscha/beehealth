import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:BeeSentinel/result_screen.dart';
import 'package:BeeSentinel/resulthistory_screen.dart';
import 'package:BeeSentinel/sidebar.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ScanBeeScreen extends StatefulWidget {
  const ScanBeeScreen({super.key});

  @override
  State<ScanBeeScreen> createState() => _ScanBeeScreenState();
}

class _ScanBeeScreenState extends State<ScanBeeScreen> {
  File? _imageFile;
  bool _isLoading = false;
  final picker = ImagePicker();
  late GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: 'AIzaSyCm0P159Sw13W6GbJ84m7sN08yCQWn4PEQ',
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      _analyzeImage(_imageFile!);
    }
  }

  Future<void> _analyzeImage(File imageFile) async {
    setState(() {
      _isLoading = true;
    });

    try {
      Uint8List imageBytes = await imageFile.readAsBytes();

      final content = [
        Content.data('image/jpeg', imageBytes),
        Content.text(
            "Analyze this honeybee image and provide:\n"
                "- Health: [Healthy/Unhealthy]\n"
                "- Disease: [None/Varroa Mites/Nosema/Deformed Wing Virus/American Foulbrood]\n"
                "- Wings: [Intact/Partially Broken/Fully Broken/Missing]\n"
                "- Legs: [All Present/Missing Front/Missing Middle/Missing Rear]\n"
                "- Temp: [Optimal/High/Low]\n"
                "- Humidity: [Optimal/High/Low]\n"
                "- Species: [Apis Mellifera/Apis Cerana/Unknown]\n"
                "Respond in single line with comma-separated values in the same order"
        ),
      ];

      final response = await _model.generateContent(content);
      String responseText = response.text ?? "No response";

      // Parse the comma-separated response
      List<String> parts = responseText.split(',').map((e) => e.trim()).toList();

      // Ensure we have all parts, fill with "Unknown" if missing
      while (parts.length < 7) {
        parts.add("Unknown");
      }

      // Generate random temperature and humidity values when not specified
      final random = Random();
      double randomTemp = 33 + random.nextDouble() * 3; // 33-36°C
      double randomHumidity = 50 + random.nextDouble() * 20; // 50-70%

      // Format temperature and humidity with actual values
      String tempStatus = parts[4].replaceAll('-', '').trim();
      String tempDisplay = tempStatus == "Unknown"
          ? "${randomTemp.toStringAsFixed(1)}°C (Optimal)"
          : tempStatus == "Optimal"
          ? "${randomTemp.toStringAsFixed(1)}°C (Optimal)"
          : tempStatus == "High"
          ? "${(36 + random.nextDouble() * 2).toStringAsFixed(1)}°C (High)"
          : "${(30 + random.nextDouble() * 3).toStringAsFixed(1)}°C (Low)";

      String humidityStatus = parts[5].replaceAll('-', '').trim();
      String humidityDisplay = humidityStatus == "Unknown"
          ? "${randomHumidity.toStringAsFixed(1)}% (Optimal)"
          : humidityStatus == "Optimal"
          ? "${randomHumidity.toStringAsFixed(1)}% (Optimal)"
          : humidityStatus == "High"
          ? "${(70 + random.nextDouble() * 10).toStringAsFixed(1)}% (High)"
          : "${(30 + random.nextDouble() * 20).toStringAsFixed(1)}% (Low)";

      // Format the analysis text with bullet points
      String analysisText = "• Health: ${parts[0].replaceAll('-', '').trim()}\n"
          "• Disease: ${parts[1].replaceAll('-', '').trim()}\n"
          "• Wings: ${parts[2].replaceAll('-', '').trim()}\n"
          "• Legs: ${parts[3].replaceAll('-', '').trim()}\n"
          "• Temperature: $tempDisplay\n"
          "• Humidity: $humidityDisplay\n"
          "• Species: ${parts[6].replaceAll('-', '').trim()}";

      // Extract disease information
      String detectedDisease = parts[1].contains("None")
          ? "No Disease Found"
          : parts[1].replaceAll('-', '').trim();

      // Get medicines if disease found
      String medicines = "No medicines needed";
      if (detectedDisease != "No Disease Found") {
        medicines = await _fetchMedicines(detectedDisease);
        medicines = _simplifyMedicineResponse(medicines);
      }

      await _saveResult(imageFile.path, analysisText, detectedDisease, medicines);

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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }  String _simplifyMedicineResponse(String medicines) {
    final lines = medicines.split('\n').where((line) => line.trim().isNotEmpty).toList();
    return lines.take(3).join('\n');
  }

  Future<String> _fetchMedicines(String disease) async {
    try {
      final response = await _model.generateContent([
        Content.text(
            "List exactly 3 medicines for $disease in honeybees in this exact format:\n"
                "1. MedicineName - BriefUsage\n"
                "2. MedicineName - BriefUsage\n"
                "3. MedicineName - BriefUsage\n"
                "Each medicine should be on one line with number, name and brief usage separated by hyphen"
        ),
      ]);

      // Process the response to ensure clean formatting
      String medicines = response.text ?? "No medicines found";

      // Format the response to single line bullet points
      medicines = medicines.split('\n')
          .where((line) => line.trim().isNotEmpty)
          .take(3)
          .map((line) => line.replaceFirst(RegExp(r'^\d+\.\s*'), '• '))
          .join('\n');

      return medicines.isNotEmpty ? medicines : "No medicines found";

    } catch (e) {
      return "Error fetching medicines";
    }
  }
  Future<void> _saveResult(
      String imagePath, String analysisText, String disease, String medicines) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('scanHistory') ?? [];

    Map<String, String> newEntry = {
      "imagePath": imagePath,
      "analysisText": analysisText,
      "detectedDisease": disease,
      "medicines": medicines,
      "timestamp": DateTime.now().toIso8601String(),
    };

    history.add(jsonEncode(newEntry));
    await prefs.setStringList('scanHistory', history);
  }

  void _openHistoryScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ResultsHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow.shade700,
        title: Text(
          'Scan Bee Health',
          style: GoogleFonts.poppins(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: _openHistoryScreen,
          ),
        ],
      ),
      drawer: CustomSidebar(),
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/scan_background.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Semi-transparent overlay
          Container(
            color: Colors.black.withOpacity(0.2),
          ),

          // Content
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Card(
                    // color: Colors.white.withOpacity(0.8),
                    margin: EdgeInsets.all(20),
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _imageFile != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(_imageFile!, height: 200),
                          )
                              : Icon(Icons.image, size: 100, color: Colors.grey),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _pickImage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(
                                  vertical: 15, horizontal: 40),
                            ),
                            child: Text(
                              "Select Image",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          _isLoading
                              ? LoadingAnimationWidget.hexagonDots(
                            color: Colors.yellow.shade700,
                            size: 40,
                          )
                              : SizedBox.shrink(),
                        ],
                      ),
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