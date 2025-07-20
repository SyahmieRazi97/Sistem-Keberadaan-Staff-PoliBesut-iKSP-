import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ActivitySheet extends StatelessWidget {
  const ActivitySheet({super.key});

  Future<List<Map<String, dynamic>>> fetchActivitiData() async {
    List<Map<String, dynamic>> activitiList = [];
    final now = DateTime.now();

    QuerySnapshot usersSnapshot = await FirebaseFirestore.instance.collection('Users').get();

    for (var userDoc in usersSnapshot.docs) {
      final userId = userDoc.id;
      final userName = userDoc['name'] ?? 'Unknown';

      QuerySnapshot statusSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('StatusUser')
          .where('statusTitle', isEqualTo: 'Aktiviti')
          .get();

      for (var statusDoc in statusSnapshot.docs) {
        final data = statusDoc.data() as Map<String, dynamic>;

        try {
          final startDate = DateTime.parse(data['startDate']);
          final endDate = DateTime.parse(data['endDate']);

          // Only include future or today's activities
          if (startDate.isAfter(now) || startDate.year == now.year && startDate.month == now.month && startDate.day == now.day) {
            activitiList.add({
              'name': userName,
              'startDate': startDate,
              'endDate': endDate,
              'description': data['statusDescription'] ?? '',
            });
          }
        } catch (e) {
          // Handle date parsing error
          print('Error parsing date for user $userName: $e');
        }
      }
    }

    activitiList.sort((a, b) => a['startDate'].compareTo(b['startDate']));

    return activitiList;
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchActivitiData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Tiada rekod Aktiviti akan datang."));
          }

          final activitiList = snapshot.data!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text("Senarai Aktiviti",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: activitiList.length,
                  itemBuilder: (context, index) {
                    final item = activitiList[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.event, color: Colors.teal),
                        title: Text(
                          item['description'] ?? '',
                          style: const TextStyle(fontSize: 19),
                        ),
                        subtitle: Text(
                          "${item['name']}\n${item['startDate'].toString().split(' ')[0]} ➝ ${item['endDate'].toString().split(' ')[0]}",
                          style: const TextStyle(fontSize: 17, height: 1.4),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}