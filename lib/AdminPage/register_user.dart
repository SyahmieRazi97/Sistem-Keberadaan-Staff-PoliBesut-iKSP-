import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digital_staff_outstation_report/AdminPage/profile_admin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../Persistent/persistent.dart';
import '../Services/global_methods.dart';

class RegisterUser extends StatefulWidget {

  @override
  State<RegisterUser> createState() => _RegisterUserState();
}

class _RegisterUserState extends State<RegisterUser> {

  final TextEditingController _fullNameController = TextEditingController(text: '');
  final TextEditingController _emailTextController = TextEditingController(text: '');
  final TextEditingController _passTextController = TextEditingController(text: '');
  final TextEditingController _phoneNumberController = TextEditingController(text: '');
  final TextEditingController _departmentController = TextEditingController(text: 'Pilih jabatan staff anda');
  final TextEditingController _positionUserController = TextEditingController(text: '');

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passFocusNode = FocusNode();
  final FocusNode _phoneNumberFocusNode = FocusNode();
  final FocusNode _departmentFocusNode = FocusNode();
  final FocusNode _positionUserFocusNode = FocusNode();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _registerUserFormKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _selectedRole = 'Staff';

  void dispose() {
    _fullNameController.dispose();
    _emailTextController.dispose();
    _passTextController.dispose();
    _phoneNumberController.dispose();
    _departmentController.dispose();
    _positionUserController.dispose();
    _emailFocusNode.dispose();
    _passFocusNode.dispose();
    _phoneNumberFocusNode.dispose();
    _departmentFocusNode.dispose();
    _positionUserFocusNode.dispose();
    super.dispose();
  }

  void _submitFormOnRegisterUser() async {
    final isValid = _registerUserFormKey.currentState!.validate();
    if (isValid) {
      setState(() {
        _isLoading = true;
      });
      try {

        await _auth.createUserWithEmailAndPassword(
          email: _emailTextController.text.trim().toLowerCase(),
          password: _passTextController.text.trim(),
        );
        final User? user = _auth.currentUser;
        final _uid = user!.uid;
        FirebaseFirestore.instance.collection('Users').doc(_uid).set({
          'id': _uid,
          'name': _fullNameController.text,
          'email': _emailTextController.text,
          'ic': _passTextController.text,
          'phoneNumber': _phoneNumberController.text,
          'department': _departmentController.text,
          'position': _selectedRole,
          'createdAt': Timestamp.now(),
        });

        await Fluttertoast.showToast(
          msg: 'Staff baru berjaya didaftarkan',
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.grey,
          fontSize: 18.0,
        );
      } catch (error) {
        setState(() {_isLoading = false;});
        GlobalMethods.showErrorDialog(error: error.toString(), ctx: context);
      }
    }
    setState(() {_isLoading = false;});
  }

  _showDepartmentDialog({required Size size})
  {
    showDialog(context: context, builder: (ctx) {
      return AlertDialog(
        backgroundColor:
        Colors.black12,
        title: const Text(
          'Department',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 20,
              color: Colors.black
          ),
        ),
        content: Container(width: size.width * 0.9, child: ListView.builder(
            shrinkWrap: true,
            itemCount: Persistent.departmentList.length,
            itemBuilder: (ctx, index)
            {
              return InkWell(
                onTap: (){
                  setState(() {
                    _departmentController.text = Persistent.departmentList[index];
                  });
                  Navigator.pop(context);
                },
                child: Row(
                  children: [
                    const Icon(Icons.label_outline_rounded, color: Colors.white,),
                    Expanded(
                      child:Padding(padding: const EdgeInsets.all(8.0),
                        child: Text(Persistent.departmentList[index],
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

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Staff',
          style: TextStyle(fontFamily: 'AppleGaramond', fontSize: 40,),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          color: Colors.black54,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: (){
            final FirebaseAuth _auth = FirebaseAuth.instance;
            final User? user = _auth.currentUser;
            final String uid = user!.uid;
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ProfileAdmin(userID: uid)));
          },
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.white60],
                begin: Alignment.centerRight,
                end: Alignment.bottomLeft,
                stops: [0.4,0.9],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 80),
              child: ListView(
                children: [
                  Form(
                    key: _registerUserFormKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        TextFormField(
                          textInputAction: TextInputAction.next,
                          onEditingComplete: () => FocusScope.of(context).requestFocus(_emailFocusNode),
                          keyboardType: TextInputType.name,
                          controller: _fullNameController,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Sila masukan nama penuh staff';
                            }
                            else {return null;}
                          },
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration(
                            hintText: 'Nama penuh',
                            hintStyle: TextStyle(color: Colors.black),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black),),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black),),
                            errorBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.red),),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          textInputAction: TextInputAction.next,
                          onEditingComplete: () => FocusScope.of(context).requestFocus(_passFocusNode),
                          keyboardType: TextInputType.emailAddress,
                          controller: _emailTextController,
                          validator: (value) {
                            if (value!.isEmpty || !value.contains('@')) {
                              return 'Sila masukan email staff yang sah';
                            }
                            else {return null;}
                          },
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration(
                            hintText: 'Email',
                            hintStyle: TextStyle(color: Colors.black),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black),),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black),),
                            errorBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.red),),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          textInputAction: TextInputAction.next,
                          onEditingComplete: () => FocusScope.of(context).requestFocus(_phoneNumberFocusNode),
                          keyboardType: TextInputType.visiblePassword,
                          controller: _passTextController,
                          validator: (value) {
                            if (value!.isEmpty || value.length < 7) {
                              return 'Kata laluan mestilah melebihi 7 karakter';
                            } else {
                              return null;
                            }
                          },
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration(
                            hintText: 'Kata laluan (I/C)',
                            hintStyle: TextStyle(color: Colors.black),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black),),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black),),
                            errorBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.red),),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          textInputAction: TextInputAction.next,
                          onEditingComplete: () => FocusScope.of(context).requestFocus(_departmentFocusNode),
                          keyboardType: TextInputType.phone,
                          controller: _phoneNumberController,
                          validator: (value) {
                            if (value!.isEmpty) {return 'Sila masukan no telefon staff';
                            }
                            else {return null;}
                          },
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration(
                            hintText: 'No Telefon',
                            hintStyle: TextStyle(color: Colors.black),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black),),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black),),
                            errorBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.red),),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          textInputAction: TextInputAction.next,
                          onEditingComplete: () => FocusScope.of(context).requestFocus(_positionUserFocusNode),
                          keyboardType: TextInputType.text,
                          controller: _departmentController,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Sila pilih jabatan';
                            }
                            return null;
                          },
                          style: const TextStyle(color: Colors.black),
                          readOnly: true, // Prevents keyboard input, only dialog selection
                          onTap: () {
                            _showDepartmentDialog(size: size);
                          },
                          decoration: const InputDecoration(
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                            errorBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.red)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Posisi :',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                Radio(
                                  value: 'Staff',
                                  groupValue: _selectedRole,
                                  onChanged: (String? value) {
                                    setState(() {
                                      _selectedRole = value!;
                                    });
                                  },
                                  activeColor: Colors.black,
                                ),
                                const Text(
                                  'Staff',
                                  style: TextStyle(color: Colors.black, fontSize: 16),
                                ),
                                Radio(
                                  value: 'KJ',
                                  groupValue: _selectedRole,
                                  onChanged: (String? value) {
                                    setState(() {
                                      _selectedRole = value!;
                                    });
                                  },
                                  activeColor: Colors.black,
                                ),
                                const Text(
                                  'KJ',
                                  style: TextStyle(color: Colors.black, fontSize: 16),
                                ),
                                Radio(
                                  value: 'Pemandu',
                                  groupValue: _selectedRole,
                                  onChanged: (String? value) {
                                    setState(() {
                                      _selectedRole = value!;
                                    });
                                  },
                                  activeColor: Colors.black,
                                ),
                                const Text(
                                  'Pemandu',
                                  style: TextStyle(color: Colors.black, fontSize: 16),
                                ),
                                Radio(
                                  value: 'Admin',
                                  groupValue: _selectedRole,
                                  onChanged: (String? value) {
                                    setState(() {
                                      _selectedRole = value!;
                                    });
                                  },
                                  activeColor: Colors.black,
                                ),
                                const Text(
                                  'Admin',
                                  style: TextStyle(color: Colors.black, fontSize: 16),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 25),
                        _isLoading
                            ? Center(
                              child: Container(width: 70, height: 70,
                                child: const CircularProgressIndicator(),
                              ),
                              )
                            : MaterialButton(
                                onPressed: () {_submitFormOnRegisterUser();},
                                color: Colors.black38,
                                elevation: 8,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13),),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Row(mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                  Text('Daftar',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      fontFamily: 'AppleGaramond'
                                    ),
                                  )
                                  ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
