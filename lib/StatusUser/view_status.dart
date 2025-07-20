import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_staff_outstation_report/StatusUser/search_staff.dart';
import 'package:digital_staff_outstation_report/Widgets/bottom_nav_bar.dart';
import 'package:digital_staff_outstation_report/Widgets/widget_status.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ViewStatus extends StatefulWidget {
  @override
  State<ViewStatus> createState() => _ViewStatusState();
}

class _ViewStatusState extends State<ViewStatus> {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  String userPosition = "";
  String userDepartment = "";
  String userName = "";

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          userPosition = userDoc['position'] ?? "";
          userDepartment = userDoc['department'] ?? "";
          userName = userDoc['name'] ?? "";
        });

        print("User Position: $userPosition, Department: $userDepartment, Name: $userName"); // Debugging
      } else {
        print("User document does not exist.");
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  String getRelativeDateLabel(Timestamp timestamp) {
    final DateTime date = timestamp.toDate();
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime yesterday = today.subtract(Duration(days: 1));
    final DateTime dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == yesterday) return 'Yesterday';

    return DateFormat('dd MMM yyyy').format(date);
  }

  Widget buildDateDivider(String label) {
    return Row(
      children: [
        const Expanded(child: Divider(thickness: 2, color: Colors.grey)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
              fontFamily: 'AppleGaramond',
            ),
          ),
        ),
        const Expanded(child: Divider(thickness: 2, color: Colors.white)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white12,
      ),
      child: Scaffold(
        bottomNavigationBar: BottomNavBar(indexNum: 0),
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'View Status',
            style: TextStyle(fontFamily: 'AppleGaramond', fontSize: 40),
          ),
          centerTitle: true,
          flexibleSpace: Container(
            color: Colors.black54,
          ),
          actions: [
            IconButton(icon: const Icon(Icons.search, color: Colors.black,),
                onPressed: ()
                {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => SearchStaff()));
                }
            )
          ],
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collectionGroup('StatusUser')
              .orderBy('createdAt', descending: true) // Ascending order
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'Something went wrong',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('There is no status'));
            }

            var filteredStatuses = snapshot.data!.docs.where((doc) {
              var statusData = doc.data();
              String statusOwner = statusData['name'] ?? "";
              String statusDepartment = statusData['department'] ?? "";
              String statusPosition = statusData['position'] ?? "";

              if (userPosition == "Staff") {
                return statusOwner == userName || statusPosition == "Admin" || statusPosition == "Pemandu";
              }
              if (userPosition == "KJ" && userDepartment == "JPA") {
                return statusDepartment == "JPA" || statusPosition == "Admin" || statusPosition == "Pemandu";
              }
              if (userPosition == "KJ" && userDepartment == "JTMK") {
                return statusDepartment == "JTMK" || statusPosition == "Admin" || statusPosition == "Pemandu";
              }
              if (userPosition == "KJ" && userDepartment == "JRKV") {
                return statusDepartment == "JRKV" || statusPosition == "Admin" || statusPosition == "Pemandu";
              }
              if (userPosition == "Pemandu") {
                return statusOwner == userName || statusPosition == "Admin";
              }
              return false;
            }).toList();

            print("Filtered Status Count: ${filteredStatuses.length}");

            if (filteredStatuses.isEmpty) {
              return const Center(child: Text('Upload your status now! ^_^'));
            }

            List<Widget> statusWidgets = [];
            String? lastDateLabel;

            for (var doc in filteredStatuses) {
              var data = doc.data();
              Timestamp createdAt = data['createdAt'] ?? Timestamp.now();
              String dateLabel = getRelativeDateLabel(createdAt);

              if (lastDateLabel != dateLabel) {
                statusWidgets.add(Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: buildDateDivider(dateLabel),
                ));
                lastDateLabel = dateLabel;
              }

              statusWidgets.add(Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
                child: WidgetStatus(
                  statusTitle: data['statusTitle'] ?? 'No Title',
                  statusDescription: data['statusDescription'] ?? 'No Description',
                  statusId: doc.id,
                  uploadedBy: data['uploadedBy'] ?? 'Unknown',
                  name: data['name'] ?? 'Unknown',
                  department: data['department'] ?? 'Unknown',
                  startDate: "Start Date: ${data['startDate'] ?? 'No Start Date'}",
                  endDate: "End Date: ${data['endDate'] ?? 'No End Date'}",
                ),
              ));
            }

            return ListView(children: statusWidgets);
          },
        ),
      ),
    );
  }
}