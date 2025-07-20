import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_staff_outstation_report/AdminPage/view_status_admin.dart';
import 'package:digital_staff_outstation_report/StatusUser/view_status.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'LoginPage/login_screen.dart';

class UserState extends StatelessWidget {

  Stream<String?> _getUserPosition() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    return FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) => snapshot.exists ? snapshot.get('position') as String? : null);
  }


  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (ctx, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (userSnapshot.data == null) {
          print('User is not logged in yet');
          return Login();
        }

        if (userSnapshot.hasData) {
          print('User is already logged in');
          return StreamBuilder<String?>(
            stream: _getUserPosition(),
            builder: (context, positionSnapshot) {
              if (positionSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (positionSnapshot.hasError || !positionSnapshot.hasData) {
                return const Scaffold(
                  body: Center(
                    child: Text('Failed to determine user position. Try again later.'),
                  ),
                );
              }

              final String? position = positionSnapshot.data;

              if (position == 'Admin') {
                return ViewStatusAdmin();
              } else if (position == 'KJ' || position == 'Staff' || position == 'Pemandu') {
                return ViewStatus();
              } else {
                return const Scaffold(
                  body: Center(
                    child: Text('Unknown position. Contact support.'),
                  ),
                );
              }
            },
          );
        }

        if (userSnapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text('An error has occurred. Try again later.'),
            ),
          );
        }

        return const Scaffold(
          body: Center(
            child: Text('Something went wrong.'),
          ),
        );
      },
    );return const Placeholder();
  }
}
