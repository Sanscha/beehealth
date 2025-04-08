import 'package:BeeSentinel/sidebar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String temperature = 'Loading...';
  String humidity = 'Loading...';

  @override
  void initState() {
    super.initState();
    loadTempAndHumidity();
  }

  Future<void> loadTempAndHumidity() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      temperature = prefs.getString('temperature') ?? 'Not available';
      humidity = prefs.getString('humidity') ?? 'Not available';
    });

    print('Saved Temperature: $temperature');
    print('Saved Humidity: $humidity');
  }

  final List<FlSpot> tempHumidityData = [
    FlSpot(25, 45),
    FlSpot(26, 50),
    FlSpot(27, 55),
    FlSpot(28, 52),
    FlSpot(29, 58),
    FlSpot(30, 60),
    FlSpot(31, 62),
    FlSpot(32, 65),
    FlSpot(31, 63),
    FlSpot(30, 58),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow.shade700,
        elevation: 0,
        title: Center(
          child: Text(
            'Dashboard',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Temperature vs Humidity",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: LineChart(
                LineChartData(
                  minX: 24,
                  maxX: 33,
                  minY: 40,
                  maxY: 70,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}%');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}°C');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  gridData: FlGridData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: tempHumidityData,
                      isCurved: true,
                      color: Colors.orange,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.orange.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 15),
            // Text("Temperature: $temperature",
            //     style: GoogleFonts.poppins(
            //         fontSize: 18, fontWeight: FontWeight.w600)),
            // Text("Humidity: $humidity",
            //     style: GoogleFonts.poppins(
            //         fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
