import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_staff_outstation_report/StatusUser/view_status.dart';
import 'package:digital_staff_outstation_report/Widgets/widget_status.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../AdminPage/view_status_admin.dart';

class SearchStaff extends StatefulWidget {
  @override
  State<SearchStaff> createState() => _SearchStaffState();
}

class _SearchStaffState extends State<SearchStaff> {
  final TextEditingController _searchQueryController = TextEditingController();
  String searchQuery = '';

  Widget _buildSearchField() {
    return TextField(
      controller: _searchQueryController,
      autocorrect: true,
      decoration: const InputDecoration(
        hintText: 'Nok Cari Sapo Eh.... ',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.black, fontSize: 19),
      ),
      style: const TextStyle(color: Colors.black, fontSize: 19),
      onChanged: (query) => updateSearchQuery(query),
    );
  }

  List<Widget> _buildActions() {
    return <Widget>[
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          _clearSearchQuery();
        },
      ),
    ];
  }

  void _clearSearchQuery() {
    setState(() {
      _searchQueryController.clear();
      updateSearchQuery('');
    });
  }

  void updateSearchQuery(String newQuery) {
    setState(() {
      searchQuery = newQuery.toUpperCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.greenAccent, Colors.cyan],
          begin: Alignment.centerRight,
          end: Alignment.bottomLeft,
          stops: [0.2, 0.7],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.lightGreenAccent, Colors.greenAccent],
                begin: Alignment.bottomLeft,
                end: Alignment.centerRight,
                stops: [0.2, 0.4],
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final user = FirebaseFirestore.instance
                  .collection('Users')
                  .doc(FirebaseAuth.instance.currentUser!.uid);

              final userDoc = await user.get();
              final role = userDoc['position'];

              if (role == 'Admin') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ViewStatusAdmin()),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ViewStatus()),
                );
              }
            },
          ),
          title: _buildSearchField(),
          actions: _buildActions(),
        ),
        body: searchQuery.isEmpty
            ? const Center(
          child: Text("Cari Sapo Terrr", style: TextStyle(fontSize: 18)),
        )
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('Users')
              .where('name', isGreaterThanOrEqualTo: searchQuery)
              .where('name', isLessThanOrEqualTo: searchQuery + '\uf8ff')
              .snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (userSnapshot.hasError) {
              return const Center(child: Text('Something went wrong'));
            } else if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
              return const Center(child: Text('There is no data'));
            }

            final userDocs = userSnapshot.data!.docs;

            return ListView.builder(
              itemCount: userDocs.length,
              itemBuilder: (context, index) {
                final userDoc = userDocs[index];
                final userData = userDoc.data();
                final userId = userDoc.id;

                return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  future: FirebaseFirestore.instance
                      .collection('Users')
                      .doc(userId)
                      .collection('StatusUser')
                      .orderBy('createdAt', descending: true)
                      .get(),
                  builder: (context, statusSnapshot) {
                    if (statusSnapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    } else if (statusSnapshot.hasError) {
                      return const Text("Error loading status");
                    } else if (!statusSnapshot.hasData || statusSnapshot.data!.docs.isEmpty) {
                      return ListTile(
                        title: Text(userData['name'] ?? 'No Name'),
                        subtitle: const Text("No status available"),
                      );
                    }

                    final statusDocs = statusSnapshot.data!.docs;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        ...statusDocs.map((doc) {
                          final statusData = doc.data();
                          final uploadedBy = userId;
                          return WidgetStatus(
                            statusTitle: statusData['statusTitle'] ?? '',
                            statusDescription: statusData['statusDescription'] ?? '',
                            statusId: statusData['statusId'] ?? '',
                            name: userData['name'] ?? '',
                            department: userData['department'] ?? '',
                            uploadedBy: uploadedBy,
                            startDate: "Start Date: ${statusData['startDate'] ?? 'No Start Date'}",
                            endDate: "End Date: ${statusData['endDate'] ?? 'No End Date'}",
                          );
                        }).toList(),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}