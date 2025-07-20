import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_staff_outstation_report/StatusUser/view_statistic.dart';
import 'package:digital_staff_outstation_report/Widgets/bottom_nav_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome_icons.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../user_state.dart';

class ProfileUser extends StatefulWidget {

  final String userID;

  const ProfileUser({required this.userID});

  @override
  State<ProfileUser> createState() => _ProfileUserState();
}

class _ProfileUserState extends State<ProfileUser> {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? name;
  String email = '';
  String? department = '';
  String phoneNumber = '';
  String joinedAt = '';
  String? position;
  bool _isLoading = false;
  bool _isSameUser = false;

  void getUserData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userID)
          .get();

      if (userDoc.exists) {
        setState(() {
          name = userDoc.get('name');
          email = userDoc.get('email');
          department = userDoc.get('department');
          phoneNumber = userDoc.get('phoneNumber');
          position = userDoc.get('position');
          Timestamp joinedAtTimeStamp = userDoc.get('createdAt');
          var joinedDate = joinedAtTimeStamp.toDate();
          joinedAt = '${joinedDate.year} - ${joinedDate.month} - ${joinedDate.day}';
        });

        User? user = _auth.currentUser;
        final _uid = user?.uid ?? '';
        setState(() {
          _isSameUser = _uid == widget.userID;
        });
      }
    } catch (error) {
      print("Error fetching user: $error");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUserData();
  }

  Widget userInfo({required IconData icon, required String content})
  {
    return Row(
      children: [
        Icon(icon, color: Colors.blue),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(content, style: const TextStyle(fontSize: 18, color: Colors.white54),),
        ),
      ],
    );
  }

  Widget _contactBy
      ({required Color color, required Function fct, required IconData icon})
  {
    return CircleAvatar(backgroundColor: color, radius: 25,
      child: CircleAvatar(radius: 23, backgroundColor: Colors.white,
        child: IconButton(icon: Icon(icon, color: color,),
          onPressed: ()
          {fct();},
        ),
      ),
    );
  }

  void _openWhatsAppChat() async
  {
    var url = 'https://wa.me/+6$phoneNumber?text=Maaf ganggu, Nak tanya...';
    launchUrlString(url);
  }

  void _callPhoneNumber() async
  {
    var url = 'tel://+6$phoneNumber';launchUrlString(url);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white12,
      ),
      child: Scaffold(
        bottomNavigationBar: _isSameUser ? BottomNavBar(indexNum: 2) : null,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Profile Screen',
            style: TextStyle(fontFamily: 'AppleGaramond', fontSize: 40,),),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              color: Colors.black54,
            ),
          ),
        ),
        body: Center(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 0),
              child: Stack(
                children: [
                  Card(color: Colors.white10, margin: const EdgeInsets.all(30),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10),),
                    child: Padding(padding: const EdgeInsets.all(8.0),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  name ?? 'Name here',
                                  style: const TextStyle(color: Colors.white, fontSize: 25),
                                  textAlign: TextAlign.center, // Center the text inside the widget
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  position ?? 'Position here',
                                  style: const TextStyle(color: Colors.white54, fontSize: 22.0),
                                  textAlign: TextAlign.center, // Center the text
                                ),
                                Text(
                                  department ?? 'Department here',
                                  style: const TextStyle(color: Colors.white54, fontSize: 22.0),
                                  textAlign: TextAlign.center, // Center the text
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Divider(thickness: 1, color: Colors.white,),
                          const SizedBox(height: 10),
                          const Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Text(
                              'Statistik:',
                              style: TextStyle(color: Colors.white54, fontSize: 22),
                            ),
                          ),
                          FutureBuilder<QuerySnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('Users')
                                .doc(widget.userID)
                                .collection('StatusUser')
                                .get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              } else if (snapshot.hasError) {
                                return const Text("Error loading statistics", style: TextStyle(color: Colors.white));
                              } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                return const Text("No status data", style: TextStyle(color: Colors.white));
                              }

                              final statusDocs = snapshot.data!.docs;

                              final Map<String, int> categoryCounts = {
                                'Cuti': 0,
                                'Urusan Luar': 0,
                                'Aktiviti': 0,
                                'Lain-lain': 0,
                              };

                              for (var doc in statusDocs) {
                                final data = doc.data() as Map<String, dynamic>;
                                final category = data['statusTitle'] ?? '';
                                if (categoryCounts.containsKey(category)) {
                                  categoryCounts[category] = categoryCounts[category]! + 1;
                                }
                              }

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Column(
                                  children: categoryCounts.entries.map((entry) {
                                    return Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(entry.key, style: const TextStyle(color: Colors.white70, fontSize: 18)),
                                        Text(entry.value.toString(), style: const TextStyle(color: Colors.white, fontSize: 18)),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          ),
                          if (position == 'KJ' && _isSameUser) ...[
                            const SizedBox(height: 15),
                            Center(
                              child: MaterialButton(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => ViewStatistic())
                                  );
                                },
                                color: Colors.blueAccent,
                                elevation: 6,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.bar_chart, color: Colors.white),
                                      SizedBox(width: 10),
                                      Text(
                                        'Lihat Statistik Staff',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'AppleGaramond',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          const Divider(thickness: 1, color: Colors.white,),
                          const Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Text('Contact :',
                              style: TextStyle(color: Colors.white54, fontSize: 22),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Padding(padding: const EdgeInsets.only(left: 10),
                            child: userInfo(icon: Icons.phone_android, content: phoneNumber),
                          ),
                          Padding(padding: const EdgeInsets.only(left: 10),
                            child: userInfo(icon: Icons.email, content: email),
                          ),
                          const SizedBox(height: 15),
                          const Divider(thickness: 1, color: Colors.white,),
                          const SizedBox(height: 15),
                          _isSameUser
                              ?
                          Container()
                              :
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _contactBy(color: Colors.green,
                                fct: () {_openWhatsAppChat();},
                                icon: FontAwesome.whatsapp,
                              ),
                              _contactBy(
                                color: Colors.black,
                                fct: () {_callPhoneNumber();},
                                icon: Icons.call,
                              ),
                            ],
                          ),
                          !_isSameUser
                              ?
                          Container()
                              :
                          Center(
                            child: Padding(
                              padding:
                              const EdgeInsets.only(bottom: 30),
                              child: MaterialButton(
                                onPressed: () {
                                  _auth.signOut();
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => UserState()));
                                },
                                color: Colors.redAccent,
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(13),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      Text('Logout',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Signatra',
                                          fontSize: 29,
                                        ),
                                      ),
                                      SizedBox(width: 8,),
                                      Icon(Icons.logout, color: Colors.white,),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}