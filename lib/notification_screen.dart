// notification_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationScreen extends StatefulWidget {
  final String? scanId; // Add this parameter

  const NotificationScreen({super.key, this.scanId});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> _weightUpdates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeightUpdates();
  }

  Future<void> _loadWeightUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> updates = [];

    if (widget.scanId != null) {
      // Load specific scan data if scanId was provided
      final scanData = jsonDecode(prefs.getString('scan_${widget.scanId}')!);
      updates = List<Map<String, dynamic>>.from(jsonDecode(scanData['weightHistory']));
    } else {
      // Load all weight updates if no specific scanId
      final activeScans = prefs.getKeys().where((key) => key.startsWith('scan_')).toList();
      for (String scanKey in activeScans) {
        final scanData = jsonDecode(prefs.getString(scanKey)!);
        updates.addAll(List<Map<String, dynamic>>.from(jsonDecode(scanData['weightHistory'])));
      }
    }

    // Sort by timestamp (newest first)
    updates.sort((a, b) => DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));

    setState(() {
      _weightUpdates = updates;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weight Updates',
          style: GoogleFonts.poppins(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black,
          ),),
        backgroundColor: Colors.yellow.shade700,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _weightUpdates.isEmpty
          ? const Center(child: Text('No weight updates available'))
          : ListView.builder(
        itemCount: _weightUpdates.length,
        itemBuilder: (context, index) {
          final update = _weightUpdates[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: const Icon(Icons.scale, color: Colors.amber,),
              title: Text('Day ${update['day']} - ${update['weight'].toStringAsFixed(2)}g',style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),),
              subtitle: Text(
                update['day'] == 1
                    ? 'Initial Weight'
                    : 'Increased by ${update['increase'].toStringAsFixed(2)}g',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              trailing: Text(
                DateTime.parse(update['timestamp']).toString().split(' ')[0],
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}