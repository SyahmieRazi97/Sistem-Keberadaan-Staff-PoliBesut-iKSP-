import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:digital_staff_outstation_report/StatusUser/profile_user.dart';
import 'package:digital_staff_outstation_report/StatusUser/update_status.dart';
import 'package:digital_staff_outstation_report/StatusUser/view_status.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int indexNum;

  BottomNavBar({required this.indexNum});

  @override
  Widget build(BuildContext context) {

        return CurvedNavigationBar(
          color: Colors.black54,
          backgroundColor: Colors.white70,
          buttonBackgroundColor: Colors.blueAccent,
          height: 50,
          index: indexNum, // Set the adjusted index
          items: const [
            Icon(Icons.receipt, size: 19, color: Colors.black),
            Icon(Icons.upload, size: 19, color: Colors.black),
            Icon(Icons.person_pin, size: 19, color: Colors.black),
          ],
          animationDuration: const Duration(milliseconds: 300),
          animationCurve: Curves.bounceInOut,
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ViewStatus()));
            } else if (index == 1) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => UpdateStatus()));
            } else if (index == 2) {
              final FirebaseAuth _auth = FirebaseAuth.instance;
              final User? user = _auth.currentUser;
              final String uid = user!.uid;
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProfileUser(userID: uid)));
            }
          },
        );
      }
  }

