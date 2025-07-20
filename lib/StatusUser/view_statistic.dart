import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ViewStatistic extends StatefulWidget {
  @override
  _ViewStatisticState createState() => _ViewStatisticState();
}

class _ViewStatisticState extends State<ViewStatistic> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? department;
  bool _isLoading = true;
  List<Map<String, dynamic>> staffStats = [];

  @override
  void initState() {
    super.initState();
    fetchStaffStatistics();
  }

  Future<void> fetchStaffStatistics() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Get current month and year
      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;

      // Get current user info
      DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.uid)
          .get();

      String position = currentUserDoc['position'];
      department = currentUserDoc['department'];

      QuerySnapshot staffQuery;

      if (position == 'Admin') {
        staffQuery = await FirebaseFirestore.instance
            .collection('Users')
            .where('position', whereIn: ['Staff', 'KJ','Pemandu'])
            .get();
      } else {
        staffQuery = await FirebaseFirestore.instance
            .collection('Users')
            .where('department', isEqualTo: department)
            .where('position', isEqualTo: 'Staff')
            .get();
      }

      for (var staffDoc in staffQuery.docs) {
        String staffName = staffDoc['name'];
        String staffID = staffDoc.id;

        // Get status records
        QuerySnapshot statusSnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .doc(staffID)
            .collection('StatusUser')
            .get();

        Map<String, int> categoryCounts = {
          'Cuti': 0,
          'Urusan Luar': 0,
          'Aktiviti': 0,
          'Lain-lain': 0,
        };

        for (var doc in statusSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final statusTitle = data['statusTitle'];
          final timestamp = data['timestamp'] != null
              ? (data['timestamp'] as Timestamp).toDate()
              : null;

          if (timestamp != null &&
              timestamp.month == currentMonth &&
              timestamp.year == currentYear &&
              categoryCounts.containsKey(statusTitle)) {
            categoryCounts[statusTitle] = categoryCounts[statusTitle]! + 1;
          }
        }

        staffStats.add({
          'name': staffName,
          'stats': categoryCounts,
        });
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print("Error fetching staff statistics: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white12,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Statistik Staff',
              style: TextStyle(fontFamily: 'AppleGaramond', fontSize: 40)
          ),
          centerTitle: true,
          flexibleSpace: Container(color: Colors.black54),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
          itemCount: staffStats.length,
          itemBuilder: (context, index) {
            final staff = staffStats[index];
            final name = staff['name'];
            final stats = staff['stats'] as Map<String, int>;

            return Card(
              margin: const EdgeInsets.all(10),
              color: Colors.white10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'AppleGaramond',)),
                    const SizedBox(height: 10),
                    ...stats.entries.map((entry) => Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 16)),
                        Text(entry.value.toString(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16)),
                      ],
                    )),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
