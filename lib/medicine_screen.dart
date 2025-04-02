import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MedicineScreen extends StatelessWidget {
  final String disease;

  MedicineScreen({required this.disease});

  // Dummy medicines for different diseases
  final Map<String, String> _medicineSuggestions = {
    "Varroa Mites": "Use **Oxalic Acid** or **Formic Acid** vapor treatment.",
    "Nosema Disease": "Treat with **Fumagilin-B** and provide clean food sources.",
    "American Foulbrood": "Use **Terramycin** or **Tylosin** under expert guidance.",
    "European Foulbrood": "Use **Oxytetracycline** and requeen the colony.",
    "Deformed Wing Virus": "Control **Varroa Mites**, and feed **protein supplements**.",
    "Chalkbrood": "Improve hive ventilation and replace old combs.",
    "No Disease Found": "Bee appears healthy! Maintain regular hive checks.",
  };

  @override
  Widget build(BuildContext context) {
    String medicine = _medicineSuggestions[disease] ?? "No specific treatment available.";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow.shade700,
        title: Text("Recommended Treatment",style: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black,
    )),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("🦟 Disease Identified:", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(disease, style: GoogleFonts.poppins(fontSize: 16, color: Colors.black)),
            SizedBox(height: 20),
            Text("💊 Suggested Treatment:", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(medicine, style: GoogleFonts.poppins(fontSize: 16)),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow.shade700),
                child: Text("🔙 Back to Results", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
