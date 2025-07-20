import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_staff_outstation_report/AdminPage/register_user.dart';
import 'package:digital_staff_outstation_report/AdminPage/view_status_admin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../StatusUser/view_statistic.dart';
import '../user_state.dart';

class ProfileAdmin extends StatefulWidget {

  final String userID;

  const ProfileAdmin({required this.userID});

  @override
  State<ProfileAdmin> createState() => _ProfileAdminState();
}

class _ProfileAdminState extends State<ProfileAdmin> {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? name;
  String email = '';
  String? department = '';
  String phoneNumber = '';
  String joinedAt = '';
  String? position;
  bool _isLoading = false;

  void getCurrentUserData() async {
    try {
      setState(() => _isLoading = true);
      User? user = _auth.currentUser;

      if (user != null) {
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            name = userDoc.get('name');
            email = userDoc.get('email');
            department = userDoc.get('department');
            phoneNumber = userDoc.get('phoneNumber');
            Timestamp joinedAtTimeStamp = userDoc.get('createdAt');
            var joinedDate = joinedAtTimeStamp.toDate();
            joinedAt = '${joinedDate.year}-${joinedDate.month}-${joinedDate.day}';
            position = userDoc.get('position');
          });
        }
      }
    } catch (error) {
      print("Error fetching user: $error");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    getCurrentUserData();
  }

  Widget userInfo({required IconData icon, required String content}) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(width: 10),
        Text(
          content,
          style: const TextStyle(fontSize: 18, color: Colors.white54),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white12,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Profile Screen',
            style: TextStyle(fontFamily: 'AppleGaramond', fontSize: 40,),),
          centerTitle: true,
          flexibleSpace: Container(
            color: Colors.black54,
          ),
          automaticallyImplyLeading: false,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black,),
              onPressed: ()
              {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ViewStatusAdmin()),);
              }
          ),
          actions: [
            IconButton(icon: const Icon(Icons.person_add, color: Colors.black,),
                onPressed: ()
                {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => RegisterUser()));
                }
            )
          ],
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
                              mainAxisAlignment: MainAxisAlignment.center, // Centers the Column content
                              crossAxisAlignment: CrossAxisAlignment.center, // Aligns text to center horizontally
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
                                ),
                                Text(
                                  department ?? 'Department here',
                                  style: const TextStyle(color: Colors.white54, fontSize: 22.0),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Divider(thickness: 2, color: Colors.white,),
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
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                MaterialButton(
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => ViewStatistic()));
                                  },
                                  color: Colors.blueAccent,
                                  elevation: 6,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(width: 10),
                                        Text(
                                          'Statistik Staff  ',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'AppleGaramond',
                                          ),
                                        ),
                                        Icon(Icons.bar_chart, color: Colors.white),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Divider(thickness: 2 , color: Colors.white,),
                          const Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Text('Contact :',
                              style: TextStyle(color: Colors.white54, fontSize: 22),
                            ),
                          ),
                          Padding(padding: const EdgeInsets.only(left: 15),
                            child: userInfo(icon: Icons.phone_android, content: phoneNumber),
                          ),
                          Padding(padding: const EdgeInsets.only(left: 15),
                            child: userInfo(icon: Icons.email, content: email),
                          ),
                          const SizedBox(height: 15),
                          const Divider(thickness: 2, color: Colors.white,),
                          const SizedBox(height: 15),
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
                                          fontFamily: 'AppleGaramond',
                                          //fontFamily: 'Signatra',
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
