import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_staff_outstation_report/Services/global_methods.dart';
import 'package:digital_staff_outstation_report/Widgets/bottom_nav_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';

import '../Persistent/persistent.dart';

class UpdateStatus extends StatefulWidget {

  @override
  State<UpdateStatus> createState() => _UpdateStatusState();
}

class _UpdateStatusState extends State<UpdateStatus> {

  final TextEditingController _statusTitleController = TextEditingController(text: 'Pilih tajuk status anda');
  final TextEditingController _statusDescController = TextEditingController();
  final TextEditingController _statusStartController = TextEditingController(text: 'Pilih tarikh mula');
  final TextEditingController _statusEndController = TextEditingController(text: 'Pilih tarikh tamat');

  final _formUpdateStatusKey = GlobalKey<FormState>();
  DateTime? pickedStart;
  DateTime? pickedEnd;
  Timestamp? startTimeStamp;
  Timestamp? endTimeStamp;
  bool _isLoading = false;

  Widget _textTitles({required String label})
  {
    return Padding(padding: const EdgeInsets.all(5.0),
      child: Text(label,
        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'GlacialIndifference'),
      ),
    );
  }

  Widget _textFormFields({
    required String valueKey,
    required TextEditingController controller,
    required bool enabled,
    required Function fct,
    required int maxLength,
  })
  {
    return Padding(padding: const EdgeInsets.all(5.0),
      child: InkWell(
        onTap: (){fct();},
        child: TextFormField(
          validator: (value)
          {
            if(value!.isEmpty)
            {
              return 'Ruangan ini tidak boleh kosong ';
            }
            return null;
          },
          controller: controller,
          enabled: enabled,
          key: ValueKey(valueKey),
          style: const TextStyle(color: Colors.white,),
          maxLines: valueKey == 'statusDescription' ? 2 : 1,
          maxLength: maxLength,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black54,
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black),),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black),),
            errorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.red),),
            suffixIcon: valueKey == 'startDate' || valueKey == 'endDate'
                ? IconButton(
              icon: const Icon(Icons.calendar_today, color: Colors.white70),
              onPressed: () { fct();},
            )
                : null,
          ),
        ),
      ),
    );
  }

  void _pickStartDate() async
  {
    pickedStart = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now().subtract(
            const Duration(days: 0),
        ),
        lastDate: DateTime(2100),
    );

    if(pickedStart != null)
      {
        setState(() {
          _statusStartController.text = '${pickedStart!.year}-${pickedStart!.month}-${pickedStart!.day}';
          startTimeStamp = Timestamp.fromMicrosecondsSinceEpoch(pickedStart!.microsecondsSinceEpoch);
          });
      }
  }

  void _pickEndDate() async {
    if (pickedStart == null) {
      Fluttertoast.showToast(
        msg: 'Sila pilih tarikh mula dahulu',
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.grey,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    pickedEnd = await showDatePicker(
      context: context,
      initialDate: pickedStart!.add(const Duration(days: 1)),
      firstDate: pickedStart!,
      lastDate: DateTime(2100),
    );

    if (pickedEnd != null) {
      setState(() {
        _statusEndController.text = '${pickedEnd!.year}-${pickedEnd!.month}-${pickedEnd!.day}';
        endTimeStamp = Timestamp.fromMicrosecondsSinceEpoch(pickedEnd!.microsecondsSinceEpoch);
      });
    }
  }

  void _updateStatus() async
  {
    final statusId = const Uuid().v4();
    User? user = FirebaseAuth.instance.currentUser;
    final _uid = user!.uid;
    final isValid = _formUpdateStatusKey.currentState!.validate();

    if (isValid) {
      if (_statusTitleController.text == 'Pilih tajuk status anda' ||
          _statusEndController.text == 'Pilih tarikh tamat' ||
          _statusStartController.text == 'Pilih tarikh mula')
      {
        GlobalMethods.showErrorDialog(
            error: 'Ada ruangan yang anda belum isi', ctx: context);
        return;
      }
      setState(() {_isLoading = true;});
      try {

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(_uid).get();

        String? userName = userDoc.get('name');
        String? department = userDoc.get('department');
        String? position = userDoc.get('position');
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(_uid)
            .collection('StatusUser')
            .doc(statusId).set({
          'statusId': statusId,
          'name': userName,
          'department': department,
          'position': position,
          'statusTitle': _statusTitleController.text,
          'statusDescription': _statusDescController.text,
          'startDate': pickedStart != null
              ? "${pickedStart!.year.toString().padLeft(4, '0')}-${pickedStart!.month.toString().padLeft(2, '0')}-${pickedStart!.day.toString().padLeft(2, '0')}"
              : '',
          'endDate': pickedEnd != null
              ? "${pickedEnd!.year.toString().padLeft(4, '0')}-${pickedEnd!.month.toString().padLeft(2, '0')}-${pickedEnd!.day.toString().padLeft(2, '0')}"
              : '',
          'uploadedBy': _uid,
          'createdAt': Timestamp.now(),
        });

        await Fluttertoast.showToast(
          msg: 'Status anda berjaya dimuat naik',
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.grey,
          fontSize: 18.0,
        );
        _statusTitleController.clear();
        _statusDescController.clear();
        _statusStartController.clear();
        _statusEndController.clear();
      }catch(error){
        {
          setState(() {_isLoading = false;});
          GlobalMethods.showErrorDialog(error: error.toString(), ctx: context);
        }
      } finally {
        setState(() {_isLoading = false;});
      }
    } else {
      print('Its not valid');
    }
  }

  _showTitleDialog({required Size size})
  {
    showDialog(context: context, builder: (ctx) {
      return AlertDialog(
        backgroundColor:
        Colors.white30 ,
        title: const Text(
          'Tajuk Status',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 20,
              color: Colors.white
          ),
        ),
        content: Container(width: size.width * 0.9, child: ListView.builder(
            shrinkWrap: true,
            itemCount: Persistent.statusTitle.length,
            itemBuilder: (ctx, index)
            {
              return InkWell(
                onTap: (){
                  setState(() {
                    _statusTitleController.text = Persistent.statusTitle[index];
                  });
                  Navigator.pop(context);
                },
                child: Row(
                  children: [
                    const Icon(Icons.label_outline_rounded, color: Colors.white,),
                    Expanded(
                      child:Padding(padding: const EdgeInsets.all(8.0),
                        child: Text(Persistent.statusTitle[index],
                          style: const TextStyle(color: Colors.white, fontSize: 16,),
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
            onPressed: ()
            {
              Navigator.canPop(context) ? Navigator.pop(context) : null;
            },
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      );
    });
  }

  String? _userPosition;

  @override
  void initState() {
    super.initState();
    _getUserPosition();
  }

  void _getUserPosition() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .get();
      setState(() {
        _userPosition = userDoc.get('position');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white12,
      ),
      child: Scaffold(
        bottomNavigationBar: _userPosition != 'Admin' ? BottomNavBar(indexNum: 1) : null,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Muat Naik Status',
            style: TextStyle(fontFamily: 'AppleGaramond', fontSize: 40,),
          ),
          centerTitle: true,
          flexibleSpace: Container(color: Colors.black54),
        ),
        body: Center(
          child: Padding(padding: const EdgeInsets.all(7.0),
            child: Card(color: Colors.white10,
              child: SingleChildScrollView(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10,),
                    const Align(alignment: Alignment.center,
                      child: Padding(padding: EdgeInsets.all(8.0),
                        child: Text('Sila isi borang ini',
                          style: TextStyle(color: Colors.white, fontSize: 40,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'AppleGaramond',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 0,),
                    const Divider(thickness: 1,),
                    Padding(padding: const EdgeInsets.all(8.0),
                      child: Form(key: _formUpdateStatusKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _textTitles(label: 'Tajuk :'),
                            _textFormFields(
                              valueKey: 'statusTitle',
                              controller: _statusTitleController, enabled: false,
                              fct: () {
                                _showTitleDialog(size: MediaQuery.of(context).size);
                              },
                              maxLength: 100,
                            ),
                            _textTitles(label: 'Penerangan :'),
                            _textFormFields(valueKey: 'statusDescription',
                              controller: _statusDescController, enabled: true,
                              fct: (){}, maxLength: 10000,
                            ),
                            _textTitles(label: 'Tarikh Mula :'),
                            _textFormFields(valueKey: 'startDate',
                              controller: _statusStartController, enabled: false,
                              fct: (){
                                _pickStartDate();
                              }, maxLength: 100,
                            ),
                            _textTitles(label: 'Tarikh Tamat :'),
                            _textFormFields(valueKey: 'endDate',
                              controller: _statusEndController, enabled: false,
                              fct: (){
                                _pickEndDate();
                              }, maxLength: 100,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 30),
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : MaterialButton(
                            onPressed: (){
                            _updateStatus();
                            },
                            color: Colors.blueAccent,
                            elevation: 8,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7),),
                              child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(width: 9,),
                                  Text(' Hantar  ',
                                    style: TextStyle(color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 27,
                                    fontFamily: 'Signatra',
                                  ),
                                ),
                                  Icon(Icons.upload_file, color: Colors.black87),
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
          ),
        ),
      ),
    );
  }
}