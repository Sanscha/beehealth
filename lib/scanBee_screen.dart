import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:BeeSentinel/result_screen.dart';
import 'package:BeeSentinel/resulthistory_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
      apiKey: 'AIzaSyCm0P159Sw13W6GbJ84m7sN08yCQWn4PEQ', // Replace with your API key
    );
    _simulateDailyWeightIncreaseForAllImages();
  }

  Future<void> _simulateDailyWeightIncreaseForAllImages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('scanHistory') ?? [];

    for (String entry in history) {
      Map<String, dynamic> data = jsonDecode(entry);
      String path = data['imagePath'];
      String key = path.replaceAll('/', '_');

      double lastWeight = prefs.getDouble('${key}_lastWeight') ?? 0.0;
      int lastDay = prefs.getInt('${key}_lastDay') ?? 1;

      if (lastDay < 4 && lastWeight < 36) {
        double dailyIncrease = 1 + Random().nextDouble() * 3;
        double newWeight = (lastWeight + dailyIncrease).clamp(0, 36);
        await prefs.setDouble('${key}_lastWeight', newWeight);
        await prefs.setInt('${key}_lastDay', lastDay + 1);
        showHiveWeightNotification(newWeight - lastWeight, tag: key);
      }
    }
  }

  Future<void> _pickImage() async {
    final prefs = await SharedPreferences.getInstance();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      String path = pickedFile.path;
      String key = path.replaceAll('/', '_');
      if (prefs.containsKey('${key}_lastWeight')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Image already scanned. Wait for daily updates.")),
        );
        return;
      }
      setState(() => _imageFile = File(path));
      _analyzeImage(_imageFile!);
    }
  }

  Future<void> _analyzeImage(File imageFile) async {
    setState(() => _isLoading = true);
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
              "Respond in single line with comma-separated values in the same order",
        ),
      ];

      final response = await _model.generateContent(content);
      String responseText = response.text ?? "No response";
      List<String> parts = responseText.split(',').map((e) => e.trim()).toList();
      while (parts.length < 7) parts.add("Unknown");

      final random = Random();
      String tempDisplay = _formatTemp(parts[4], random);
      String humidityDisplay = _formatHumidity(parts[5], random);

      String analysisText = "• Health: ${parts[0]}\n"
          "• Disease: ${parts[1]}\n"
          "• Wings: ${parts[2]}\n"
          "• Legs: ${parts[3]}\n"
          "• Temperature: $tempDisplay\n"
          "• Humidity: $humidityDisplay\n"
          "• Species: ${parts[6]}";

      String path = imageFile.path;
      String key = path.replaceAll('/', '_');

      double initialWeight = 8 + random.nextDouble() * 2;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('${key}_lastWeight', initialWeight);
      await prefs.setInt('${key}_lastDay', 1);
      showHiveWeightNotification(0.0, isInitial: true, initialWeight: initialWeight, tag: key);

      String detectedDisease = parts[1].contains("None") ? "No Disease Found" : parts[1];
      String medicines = detectedDisease == "No Disease Found"
          ? "No medicines needed"
          : _simplifyMedicineResponse(await _fetchMedicines(detectedDisease));

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
  }

  String _formatTemp(String status, Random random) {
    status = status.replaceAll('-', '').trim();
    if (status == "Unknown" || status == "Optimal") return "${(33 + random.nextDouble() * 3).toStringAsFixed(1)}°C (Optimal)";
    return status == "High"
        ? "${(36 + random.nextDouble() * 2).toStringAsFixed(1)}°C (High)"
        : "${(30 + random.nextDouble() * 3).toStringAsFixed(1)}°C (Low)";
  }

  String _formatHumidity(String status, Random random) {
    status = status.replaceAll('-', '').trim();
    if (status == "Unknown" || status == "Optimal") return "${(50 + random.nextDouble() * 10).toStringAsFixed(1)}% (Optimal)";
    return status == "High"
        ? "${(70 + random.nextDouble() * 10).toStringAsFixed(1)}% (High)"
        : "${(30 + random.nextDouble() * 20).toStringAsFixed(1)}% (Low)";
  }

  void showHiveWeightNotification(double weightGain,
      {bool isInitial = false, double initialWeight = 0.0, required String tag}) async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'weight_channel',
      'Hive Weight',
      channelDescription: 'Daily hive weight update',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    String title = 'Hive Weight Update';
    String body = isInitial
        ? 'Initial hive weight ${initialWeight.toStringAsFixed(2)} gms'
        : 'Weight increased by ${weightGain.toStringAsFixed(2)} gms for $tag today!';

    await flutterLocalNotificationsPlugin.show(tag.hashCode, title, body, platformDetails);
  }

  String _simplifyMedicineResponse(String medicines) {
    final lines = medicines.split('\n').where((line) => line.trim().isNotEmpty).toList();
    return lines.take(3).join('\n');
  }

  Future<String> _fetchMedicines(String disease) async {
    try {
      final response = await _model.generateContent([
        Content.text(
          "List exactly 3 medicines for $disease in honeybees in this format:\n"
              "1. MedicineName - BriefUsage\n"
              "2. MedicineName - BriefUsage\n"
              "3. MedicineName - BriefUsage",
        ),
      ]);

      return response.text
          ?.split('\n')
          .where((line) => line.trim().isNotEmpty)
          .take(3)
          .map((line) => line.replaceFirst(RegExp(r'^\d+\.\s*'), '• '))
          .join('\n') ??
          "No medicines found";
    } catch (e) {
      return "Error fetching medicines";
    }
  }

  Future<void> _saveResult(String imagePath, String analysisText, String disease, String medicines) async {
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
        title: Center(
          child: Text(
            'Scan Bee Health',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: _openHistoryScreen,
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/scan_background.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.2)),
          Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Card(
                    margin: EdgeInsets.all(20),
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
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
                              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
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
