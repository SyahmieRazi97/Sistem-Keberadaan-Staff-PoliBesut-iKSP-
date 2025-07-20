import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_staff_outstation_report/AdminPage/profile_admin.dart';
import 'package:digital_staff_outstation_report/StatusUser/search_staff.dart';
import 'package:digital_staff_outstation_report/StatusUser/update_status.dart';
import 'package:digital_staff_outstation_report/Widgets/widget_status.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Persistent/persistent.dart';

class ViewStatusAdmin extends StatefulWidget {
  @override
  State<ViewStatusAdmin> createState() => _ViewStatusAdminState();
}

class _ViewStatusAdminState extends State<ViewStatusAdmin> {

  String? departmentFilter;

  _showDepartmentDialog({required Size size})
  {
    showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: Colors.black54,
            title: const Text('Department',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, color: Colors.white, fontFamily: 'AppleGaramond'),
            ),
            content: Container(
              width: size.width * 0.9,
              child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: Persistent.departmentList.length,
                  itemBuilder: (ctx, index)
                  {
                    return InkWell(
                      onTap: (){
                        setState(() {departmentFilter = Persistent.departmentList[index];});
                        Navigator.canPop(context) ? Navigator.pop(context) : null;
                        print('departmentList[index], ${Persistent.departmentList[index]}');
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.label_outline_rounded, color: Colors.grey,),
                          Expanded(
                            child:Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(Persistent.departmentList[index],
                                style: const TextStyle(color: Colors.grey, fontSize: 16,),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.canPop(context) ? Navigator.pop(context) : null;},
                child: const Text('Close', style: TextStyle(color: Colors.white, fontSize: 16,),),
              ),
              TextButton(
                onPressed: ()
                {
                  setState(() {departmentFilter = null;});
                  Navigator.canPop(context) ? Navigator.pop(context) : null;
                },
                child: const Text('Cancel Filter', style: TextStyle(color: Colors.white),),
              ),
            ],
          );
        }
    );
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
        const Expanded(child: Divider(thickness: 2, color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white12
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'View Status',
            style: TextStyle(fontFamily: 'AppleGaramond', fontSize: 40, color: Colors.black),
          ),
          centerTitle: true,
          flexibleSpace: Container(color: Colors.black54),
          automaticallyImplyLeading: false,

          leading: IconButton(icon: const Icon(Icons.filter_list_rounded, color: Colors.black),
              onPressed: ()
              {
                _showDepartmentDialog(size: size);
              }
          ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.black),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SearchStaff()),
                  );
                },
              ),
              IconButton(
                  icon: const Icon(Icons.person, color: Colors.black),
                  onPressed: () {
                    final FirebaseAuth _auth = FirebaseAuth.instance;
                    final User? user = _auth.currentUser;
                    final String uid = user!.uid;
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => ProfileAdmin(userID: uid)));
                  }
              )
            ]
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: departmentFilter == null
              ? FirebaseFirestore.instance
              .collectionGroup('StatusUser')
              .orderBy('createdAt', descending: true) // Ascending order
              .snapshots()
              : FirebaseFirestore.instance
              .collectionGroup('StatusUser')
              .where('department', isEqualTo: departmentFilter)
              .orderBy('createdAt', descending: true) // Ascending order
              .snapshots(),

          builder: (context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Error loading data',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    Text('Indexing required: ${snapshot.error}'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('No status found'),
                    if (departmentFilter != null)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            departmentFilter = null;
                          });
                        },
                        child: const Text('Clear filter'),
                      )
                  ],
                ),
              );
            }

            List<Widget> statusWidgets = [];
            String? lastDateLabel;

            for (var doc in snapshot.data!.docs) {
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
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => UpdateStatus()));
          },
          backgroundColor: Colors.blueAccent,
          child: const Icon(Icons.add, color: Colors.black),
        ),
      ),
    );
  }
}