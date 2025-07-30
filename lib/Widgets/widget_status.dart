import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_staff_outstation_report/StatusUser/profile_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../Persistent/persistent.dart';
import '../Services/global_methods.dart';

class WidgetStatus extends StatefulWidget {
  final String statusTitle;
  final String statusDescription;
  final String statusId;
  final String name;
  final String department;
  final String uploadedBy;
  final String startDate;
  final String endDate;

  const WidgetStatus({
    required this.statusTitle,
    required this.statusDescription,
    required this.statusId,
    required this.name,
    required this.department,
    required this.uploadedBy,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<WidgetStatus> createState() => _WidgetStatusState();
}

class _WidgetStatusState extends State<WidgetStatus> {
  final List<Color> _colors = [
    Colors.amber,
    Colors.orange,
    Colors.pink.shade200,
    Colors.brown,
    Colors.cyan,
    Colors.blueAccent,
    Colors.deepOrange,
  ];

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> _getUserPosition() async {
    User? user = _auth.currentUser;
    if (user == null) return '';

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .get();

    return userDoc.get('position') ?? '';
  }

  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  }


  void _editStatusDialog() async {
    final TextEditingController _titleController = TextEditingController(text: widget.statusTitle);
    final TextEditingController _descController = TextEditingController(text: widget.statusDescription);
    final TextEditingController _startDateController = TextEditingController(text: widget.startDate);
    final TextEditingController _endDateController = TextEditingController(text: widget.endDate);

    DateTime? selectedStartDate = DateTime.tryParse(widget.startDate);
    DateTime? selectedEndDate = DateTime.tryParse(widget.endDate);

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Ubahsuai Status'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    String? selectedTitle = await showDialog<String>(
                      context: context,
                      builder: (BuildContext context) {
                        return SimpleDialog(
                          title: const Text('Pilih Tajuk Status'),
                          children: Persistent.statusTitle.map((String title) {
                            return SimpleDialogOption(
                              onPressed: () {
                                Navigator.pop(context, title);
                              },
                              child: Text(title),
                            );
                          }).toList(),
                        );
                      },
                    );

                    if (selectedTitle != null) {
                      _titleController.text = selectedTitle;
                    }
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                    ),
                  ),
                ),
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: _startDateController,
                  decoration: const InputDecoration(labelText: 'Start Date'),
                  readOnly: true,
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedStartDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Colors.blue,
                              onPrimary: Colors.white,
                              onSurface: Colors.black,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() {
                        selectedStartDate = picked;
                        _startDateController.text =
                        picked.toIso8601String().split('T')[0];
                      });
                    }
                  },
                ),
                TextField(
                  controller: _endDateController,
                  decoration: const InputDecoration(labelText: 'End Date'),
                  readOnly: true,
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedEndDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Colors.blue,
                              onPrimary: Colors.white,
                              onSurface: Colors.black,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() {
                        selectedEndDate = picked;
                        _endDateController.text =
                        picked.toIso8601String().split('T')[0];
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('Users')
                      .doc(widget.uploadedBy)
                      .collection('StatusUser')
                      .doc(widget.statusId)
                      .update({
                    'statusTitle': _titleController.text.trim(),
                    'statusDescription': _descController.text.trim(),
                    'startDate': _startDateController.text.trim(),
                    'endDate': _endDateController.text.trim(),
                  });

                  Navigator.pop(ctx);

                  Fluttertoast.showToast(
                    msg: 'Status berjaya diubahsuai!',
                    toastLength: Toast.LENGTH_SHORT,
                    backgroundColor: Colors.grey,
                    fontSize: 16.0,
                  );
                } catch (error) {
                  GlobalMethods.showErrorDialog(
                      error: error.toString(), ctx : ctx);
                }
              },
              child: const Text('Simpan'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  void _showOptionsDialog() async {
    String position = await _getUserPosition();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Kepastian"),
          content: const Text("Adakah anda ingin mengubahsuai status ini?"),
          actions: [
            if (position == 'Admin')
              TextButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('Users')
                      .doc(widget.uploadedBy)
                      .collection('StatusUser')
                      .doc(widget.statusId)
                      .delete();

                  Fluttertoast.showToast(
                    msg: 'Status berjaya dipadam',
                    backgroundColor: Colors.grey,
                  );
                  Navigator.pop(context);
                },
                child: const Text("Padam", style: TextStyle(color: Colors.red)),
              ),
            if ((_currentUserId == widget.uploadedBy) && (position == 'KJ' || position == 'Staff'))
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _editStatusDialog();
                },
                child: const Text("Ya", style: TextStyle(color: Colors.green)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Tidak"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _colors.shuffle();
    return Card(
      color: Colors.white10,
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: ListTile(
        onTap: () {
          if (widget.uploadedBy != _currentUserId) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileUser(userID: widget.uploadedBy),
              ),
            );
          }
        },
        onLongPress: _showOptionsDialog,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        leading: Container(
          height: 40,
          width: 45,
          padding: const EdgeInsets.only(right: 12),
          decoration: const BoxDecoration(
            border: Border(
              right: BorderSide(width: 1),
            ),
          ),
          child: Icon(
            Icons.person_pin,
            color: _colors[1],
            size: 40,
          ),
        ),
        title: Text(
          widget.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white54,
            fontWeight: FontWeight.bold,
            fontFamily: 'AppleGaramond',
            fontSize: 25.5,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.statusTitle,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'TimesNewRomance',
                fontSize: 25,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.statusDescription,
              style: const TextStyle(color: Colors.white54, fontSize: 20.5),
            ),
            const SizedBox(height: 8),
            Text(
              widget.startDate,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'GlacialIndifference',
                fontSize: 21,
              ),
            ),
            Text(
              widget.endDate,
              style: const TextStyle(
                color: Colors.white54,
                fontFamily: 'GlacialIndifference',
                fontSize: 21,
              ),
            ),
          ],
        ),
        trailing: const Icon(
          Icons.keyboard_arrow_right,
          size: 30,
          color: Colors.blueAccent,
        ),
      ),
    );
  }
}
