import 'package:BeeSentinel/weather_forecasting_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


import 'notification_screen.dart';

class CustomSidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            height: 100,
            child: DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.yellow.shade700,
              ),
              child: Text(
                'Bee Sentinel',
                style: GoogleFonts.poppins(
                  textStyle: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),


          ListTile(
            leading: Icon(Icons.notifications_active, color: Colors.black),
            title: Text(
              'Notifications',
              style: GoogleFonts.poppins(
                textStyle: TextStyle(fontSize: 18),
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.person, color: Colors.black),
            title: Text(
              'Weather forecasting',
              style: GoogleFonts.poppins(
                textStyle: TextStyle(fontSize: 18),
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => WeatherForecastingScreen()),
              );
            },
          ),

          // ✅ Fix Log Out Function to Prevent Back Navigation

        ],
      ),
    );
  }
}
