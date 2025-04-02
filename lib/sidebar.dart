import 'package:BeeSentinel/profile_screen.dart';
import 'package:BeeSentinel/resulthistory_screen.dart';
import 'package:BeeSentinel/scanBee_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dashboard_screen.dart';
import 'healthTips_screen.dart';
import 'login_screen.dart';
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
            leading: Icon(Icons.dashboard, color: Colors.black),
            title: Text(
              'Dashboard',
              style: GoogleFonts.poppins(
                textStyle: TextStyle(fontSize: 18),
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DashboardScreen()),
              );
            },
          ),

          // Scan Bee Tile with Icon
          ListTile(
            leading: Icon(Icons.camera_alt, color: Colors.black),
            title: Text(
              'Scan Bee',
              style: GoogleFonts.poppins(
                textStyle: TextStyle(fontSize: 18),
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ScanBeeScreen()),
              );
            },
          ),

          // ✅ Replace Results Screen with Results History
          ListTile(
            leading: Icon(Icons.history, color: Colors.black),
            title: Text(
              'Results History',
              style: GoogleFonts.poppins(
                textStyle: TextStyle(fontSize: 18),
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ResultsHistoryScreen()),
              );
            },
          ),

          // Health Tips Tile with Icon
          ListTile(
            leading: Icon(Icons.health_and_safety, color: Colors.black),
            title: Text(
              'Health Tips',
              style: GoogleFonts.poppins(
                textStyle: TextStyle(fontSize: 18),
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HealthtipsScreen()),
              );
            },
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
              'Profile',
              style: GoogleFonts.poppins(
                textStyle: TextStyle(fontSize: 18),
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
          ),

          // ✅ Fix Log Out Function to Prevent Back Navigation
          ListTile(
            leading: Icon(Icons.logout, color: Colors.black),
            title: Text(
              'Log out',
              style: GoogleFonts.poppins(
                textStyle: TextStyle(fontSize: 18),
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false, // Clears navigation stack
              );
            },
          ),
        ],
      ),
    );
  }
}
