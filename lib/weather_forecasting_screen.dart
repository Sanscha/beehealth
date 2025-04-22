import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fl_chart/fl_chart.dart';

class WeatherForecastingScreen extends StatefulWidget {
  const WeatherForecastingScreen({super.key});

  @override
  State<WeatherForecastingScreen> createState() => _WeatherForecastingScreenState();
}

class _WeatherForecastingScreenState extends State<WeatherForecastingScreen> {
  List<dynamic> forecastData = [];
  bool isLoading = true;

  final String apiKey = '025efdf8e51d291ac8da4f0d2ab9f6d7';
  final String city = 'Nashik';

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    initializeNotifications();
    fetchForecast();
  }

  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> fetchForecast() async {
    final url =
        'https://api.openweathermap.org/data/2.5/forecast?q=$city&appid=$apiKey&units=metric';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          forecastData = data['list'];
          isLoading = false;
        });

        checkBeehiveWeatherWarnings(forecastData);
      } else {
        throw Exception('Failed to load forecast: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching weather data: $e');
    }
  }

  void checkBeehiveWeatherWarnings(List<dynamic> data) {
    for (var item in data) {
      final temp = item['main']['temp'];
      final humidity = item['main']['humidity'];
      final windSpeed = item['wind']['speed'];
      final condition = item['weather'][0]['main'].toString().toLowerCase();

      if (temp < 10) {
        showLocalNotification("Cold Alert ❄️", "Temperature below 10°C – bees may cluster.");
        break;
      } else if (temp > 35) {
        showLocalNotification("Heat Alert 🔥", "High heat – provide hive ventilation.");
        break;
      }

      if (humidity > 80) {
        showLocalNotification("Humidity Alert 💧", "High moisture – risk of mold in hives.");
        break;
      }

      if (windSpeed > 10) {
        showLocalNotification("Wind Alert 💨", "Strong wind – secure your hives.");
        break;
      }

      if (condition.contains("storm") || condition.contains("rain")) {
        showLocalNotification("Storm/Rain Alert 🌧️", "Unstable weather – reschedule inspections.");
        break;
      }
    }
  }

  Future<void> showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'beehive_channel_id',
      'Beehive Weather Alerts',
      channelDescription: 'Channel for bee-related weather alerts',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  String formatDate(String dtTxt) {
    final date = DateTime.parse(dtTxt);
    return "${date.day}/${date.month} ${date.hour}:00";
  }

  String getSeasonalInsight(double temp) {
    if (temp < 10) {
      return "🧊 Winter Tip: Feed bees & reduce airflow.";
    } else if (temp > 25) {
      return "☀️ Summer Tip: Provide good ventilation.";
    } else {
      return "🍃 Mild conditions – standard care.";
    }
  }

  String getSchedulingTip(String condition) {
    condition = condition.toLowerCase();
    if (condition.contains("rain") || condition.contains("storm")) {
      return "⛈️ Rain expected – reschedule inspections.";
    } else {
      return "✅ Clear skies – ideal for hive work.";
    }
  }

  List<FlSpot> getTempSpots() {
    return List.generate(
      forecastData.length,
          (i) => FlSpot(i.toDouble(), (forecastData[i]['main']['temp'] as num).toDouble()),
    );
  }

  List<FlSpot> getHumiditySpots() {
    return List.generate(
      forecastData.length,
          (i) => FlSpot(i.toDouble(), (forecastData[i]['main']['humidity'] as num).toDouble()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Weather Forecasts',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text("📊 Temperature & Humidity Trends", style: _textStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              height: 300,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: LineChart(
                  LineChartData(
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: getTempSpots(),
                        isCurved: true,
                        color: Colors.orange,
                        barWidth: 3,
                        dotData: FlDotData(show: false),
                      ),
                      LineChartBarData(
                        spots: getHumiditySpots(),
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 3,
                        dotData: FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: forecastData.length,
              itemBuilder: (context, index) {
                final item = forecastData[index];
                final date = formatDate(item['dt_txt']);
                final temp = (item['main']['temp'] as num).toDouble();
                final humidity = (item['main']['humidity'] as num).toDouble();
                final condition = item['weather'][0]['main'];
                final seasonalInsight = getSeasonalInsight(temp);
                final schedulingTip = getSchedulingTip(condition);

                return Card(
                  margin: const EdgeInsets.all(8),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("📅 Date: $date", style: _textStyle()),
                        Text("🌤️ Condition: $condition", style: _textStyle()),
                        Text("🌡️ Temperature: ${temp.toStringAsFixed(1)}°C", style: _textStyle()),
                        Text("💧 Humidity: $humidity%", style: _textStyle()),
                        const SizedBox(height: 6),
                        Text("🧠 Insight: $seasonalInsight", style: _textStyle(fontWeight: FontWeight.w600)),
                        Text("📌 Tip: $schedulingTip", style: _textStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _textStyle({FontWeight fontWeight = FontWeight.normal}) {
    return GoogleFonts.poppins(
      fontSize: 15,
      color: Colors.black87,
      height: 1.5,
      fontWeight: fontWeight,
    );
  }
}
