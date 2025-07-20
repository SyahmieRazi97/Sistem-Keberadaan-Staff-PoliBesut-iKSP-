import 'package:digital_staff_outstation_report/LoginPage/login_screen.dart';
import 'package:digital_staff_outstation_report/user_state.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _initialization,
        builder: (context, snapshot)
        {
          if(snapshot.connectionState == ConnectionState.waiting)
          {
            return const MaterialApp(
                home: Scaffold(
                  body: Center(
                    child: Text('DSOR app is being initialized',
                      style: TextStyle(
                          color: Colors.cyan,
                          fontSize: 40,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                )
            );
          } else if(snapshot.hasError)
          {
            return const MaterialApp(
                home: Scaffold(
                  body: Center(
                    child: Text('An error has been occurred',
                      style: TextStyle(
                        color: Colors.cyan,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
            );
          } return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Digital Staff Outstation Report App',
            theme: ThemeData(
                scaffoldBackgroundColor: Colors.black,
                primarySwatch: Colors.blue
            ),
            home: UserState(),
          );
        }
    );
  }
}