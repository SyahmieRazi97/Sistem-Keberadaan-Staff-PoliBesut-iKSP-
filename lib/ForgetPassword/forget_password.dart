import 'package:cached_network_image/cached_network_image.dart';
import 'package:digital_staff_outstation_report/LoginPage/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../Services/global_variables.dart';

class ForgetPassword extends StatefulWidget {

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> with TickerProviderStateMixin {

  late Animation<double> _animation;
  late AnimationController _animationController;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _forgotPassTextController = TextEditingController(text: '');

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _animationController = AnimationController (vsync: this, duration: const Duration(seconds: 20));
    _animation = CurvedAnimation(parent: _animationController , curve: Curves.linear)
      ..addListener(() {setState(() {});})
      ..addStatusListener((animationStatus){
        if(animationStatus == AnimationStatus.completed)
        {
          _animationController.reset();
          _animationController.forward();
        }
      });
    _animationController.forward();
    super.initState();
  }

  void _forgotPassSubmitForm() async
  {
    try{
      await _auth.sendPasswordResetEmail(email: _forgotPassTextController.text,);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Login()));
    }catch(error)
    {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          CachedNetworkImage(imageUrl: PassUrlImage,
            placeholder: (context, url) => Image.asset('Asset/Images/Wallpaper.jpg',
              fit: BoxFit.fill,
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            alignment: FractionalOffset(_animation.value, 0),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              children: [
                SizedBox(height: size.height * 0.1,),
                const Text('Forgot Password',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'AppleGaramond', fontSize: 55),
                ),
                const SizedBox(height: 20,),
                const Text('Email address',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, fontSize: 18),
                ),
                const SizedBox(height: 20,),
                TextField(
                  controller: _forgotPassTextController,
                  decoration: const InputDecoration(filled: true, fillColor: Colors.white54,
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white),),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white),),
                  ),
                ),
                const SizedBox(height: 30,),
                MaterialButton(
                  onPressed: ()
                  {
                    _forgotPassSubmitForm();
                  },
                  color: Colors.white70,
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13),),
                  child: const Padding(padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Reset now',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, fontSize: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}