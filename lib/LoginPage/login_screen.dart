import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_staff_outstation_report/ForgetPassword/forget_password.dart';
import 'package:digital_staff_outstation_report/Services/global_methods.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart'; // Import Marquee package

import '../Services/global_variables.dart';
import '../Widgets/activity_sheet.dart';

class Login extends StatefulWidget {
  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> with TickerProviderStateMixin {
  late Animation<double> _animation;
  late AnimationController _animationController;
  final TextEditingController _emailTextController = TextEditingController();
  final TextEditingController _passTextController = TextEditingController();
  final FocusNode _passFocusNode = FocusNode();
  bool _isLoading = false;
  bool _obscureText = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _loginFormKey = GlobalKey<FormState>();

  String userName = "Fetching user...";
  List<Map<String, String>> allStatuses = [];

  @override
  void dispose() {
    _animationController.dispose();
    _emailTextController.dispose();
    _passTextController.dispose();
    _passFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 35));
    _animation = CurvedAnimation(parent: _animationController, curve: Curves.linear)
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((animationStatus) {
        if (animationStatus == AnimationStatus.completed) {
          _animationController.reset();
          _animationController.forward();
        }
      });
    _animationController.forward();

    // Fetch Firestore data
    _fetchUserStatus();
  }

  Future<void> _fetchUserStatus() async {
    try {
      print("Fetching user statuses...");

      // Fetch all users
      QuerySnapshot usersSnapshot = await FirebaseFirestore.instance.collection('Users').get();

      List<Map<String, String>> fetchedStatuses = [];

      for (var userDoc in usersSnapshot.docs) {
        String fetchedUserName = userDoc['name'] ?? "Unknown User";

        // Fetch all statuses from subcollection "StatusUser"
        QuerySnapshot statusSnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .doc(userDoc.id)
            .collection('StatusUser')
            .orderBy('startDate', descending: true) // Order by latest date
            .get();

        for (var statusDoc in statusSnapshot.docs) {
          String startDateStr = "Not Set";
          String endDateStr = "Not Set";

          if (statusDoc['startDate'] != null) {
            if (statusDoc['startDate'] is Timestamp) {
              startDateStr = (statusDoc['startDate'] as Timestamp).toDate().toString().split(' ')[0];
            } else {
              startDateStr = statusDoc['startDate'].toString();
            }
          }

          if (statusDoc['endDate'] != null) {
            if (statusDoc['endDate'] is Timestamp) {
              endDateStr = (statusDoc['endDate'] as Timestamp).toDate().toString().split(' ')[0];
            } else {
              endDateStr = statusDoc['endDate'].toString();
            }
          }

          fetchedStatuses.add({
            "userName": fetchedUserName,
            "statusTitle": statusDoc['statusTitle'] ?? "No Status",
            "startDate": startDateStr,
            "endDate": endDateStr,
            "statusDescription": statusDoc['statusDescription'] ?? "",
          });

          print("Fetched status: ${fetchedStatuses.last}");
        }
      }

      if (fetchedStatuses.isEmpty) {
        print("No statuses found.");
      } else {
        print("Total statuses fetched: ${fetchedStatuses.length}");
      }

      setState(() {
        allStatuses = fetchedStatuses;
      });
    } catch (e) {
      print("Error fetching statuses: $e");
    }
  }

  String _buildOrderedStatusText() {
    List<String> priorityOrder = ['Aktiviti', 'Cuti', 'Urusan Luar', 'Lain-lain'];

    List<Map<String, String>> sortedStatuses = allStatuses.toList()
      ..sort((a, b) {
        int indexA = priorityOrder.indexOf(a['statusTitle'] ?? '') ?? 999;
        int indexB = priorityOrder.indexOf(b['statusTitle'] ?? '') ?? 999;
        return indexA.compareTo(indexB);
      });

    return sortedStatuses.map((status) {
      String emoji;
      switch (status['statusTitle']) {
        case 'Aktiviti':
          emoji = '📚';
          break;
        case 'Cuti':
          emoji = '🏡️';
          break;
        case 'Urusan Luar':
          emoji = '🚗';
          break;
        case 'Lain-lain':
          emoji = '📢';
          break;
        default:
          emoji = '🔔';
      }

      String descriptionText = '';
      if (status['statusTitle'] == 'Aktiviti' && status['statusDescription'] != null && status['statusDescription']!.isNotEmpty) {
        descriptionText = ' - ${status['statusDescription']}';
      }

      return "👤 ${status['userName']} $emoji ${status['statusTitle']}$descriptionText 📅 ${status['startDate']} / ${status['endDate']}  •  ";
    }).join(" ");
  }

  void _submitFormOnLogin() async {
    final isValid = _loginFormKey.currentState!.validate();
    if (isValid) {
      setState(() {
        _isLoading = true;
      });
      try {
        await _auth.signInWithEmailAndPassword(
          email: _emailTextController.text.trim(),
          password: _passTextController.text.trim(),
        );
        Navigator.canPop(context) ? Navigator.pop(context) : null;
      } catch (error) {
        setState(() {
          _isLoading = false;
        });
        GlobalMethods.showErrorDialog(error: error.toString(), ctx: context);
        print('Error occurred $error');
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CachedNetworkImage(
            imageUrl: loginUrlImage,
            placeholder: (context, url) => Image.asset(
              'Asset/Images/Wallpaper.jpg',
              fit: BoxFit.fill,
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            alignment: FractionalOffset(_animation.value, 0),
          ),
          Container(
            color: Colors.black26,
          ),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 80),
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 80, right: 80),
                    child: Image.asset('Asset/Images/BESUT.png'),
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _loginFormKey,
                    child: Column(
                      children: [
                        TextFormField(
                          textInputAction: TextInputAction.next,
                          onEditingComplete: () =>
                              FocusScope.of(context).requestFocus(_passFocusNode),
                          keyboardType: TextInputType.emailAddress,
                          controller: _emailTextController,
                          validator: (value) {
                            if (value!.isEmpty || !value.contains('@')) {
                              return 'Please enter a valid Email address';
                            } else {
                              return null;
                            }
                          },
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Email',
                            hintStyle: TextStyle(color: Colors.white),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            errorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        TextFormField(
                          textInputAction: TextInputAction.next,
                          focusNode: _passFocusNode,
                          keyboardType: TextInputType.visiblePassword,
                          controller: _passTextController,
                          obscureText: !_obscureText,
                          validator: (value) {
                            if (value!.isEmpty || value.length < 7) {
                              return 'Please enter a valid password';
                            } else {
                              return null;
                            }
                          },
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            suffixIcon: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                              child: Icon(
                                _obscureText ? Icons.visibility : Icons.visibility_off,
                                color: Colors.white,
                              ),
                            ),
                            hintText: 'Password',
                            hintStyle: const TextStyle(color: Colors.white),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            errorBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ForgetPassword()));
                            },
                            child: const Text(
                              'Forget Password?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        MaterialButton(
                          onPressed: _submitFormOnLogin,
                          color: Colors.blueGrey,
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Login',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Positioned(
            top: 10,
            right: 16,
            child: SafeArea(
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
                      ),
                      builder: (context) => ActivitySheet(),
                    );
                  },
                ),
              ),
            ),
          ),
          // News Crawl Animation at the Bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 40,
              color: Colors.black54,
              child: Marquee(
                text: allStatuses.isNotEmpty
                    ? _buildOrderedStatusText()
                    : "Fetching latest updates...",
                style: const TextStyle(color: Colors.white, fontSize: 18),
                scrollAxis: Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.start,
                blankSpace: 30.0,
                velocity: 50.0,
                pauseAfterRound: Duration(seconds: 1),
                startPadding: 10.0,
                accelerationDuration: Duration(seconds: 2),
                accelerationCurve: Curves.easeIn,
                decelerationDuration: Duration(milliseconds: 500),
                decelerationCurve: Curves.easeOut,
              ),
            ),
          ),

        ],
      ),
    );
  }

}
