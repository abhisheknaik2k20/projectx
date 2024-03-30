import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:projectx/pages/HomeScreen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:projectx/views/registration.dart';
import 'package:lottie/lottie.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool passwordVisible = true;
  bool isButtonDisabled = false;
  late final TextEditingController emailcontroller;
  late final TextEditingController passcontroller;

  @override
  void initState() {
    emailcontroller = TextEditingController();
    passcontroller = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    if (mounted) {
      emailcontroller.dispose();
      passcontroller.dispose();
    }
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Are you sure?'),
            content: const Text('Do you want to Quit?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            final user = FirebaseAuth.instance.currentUser;
            if (snapshot.hasData) {
              print(user);
              return const HomeScreen();
            } else {
              return Scaffold(
                  backgroundColor: const Color.fromARGB(246, 26, 27, 31),
                  body: Form(
                    child: SafeArea(
                        child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                                child: Lottie.asset('assets/animation1.json')),
                            Text("WELCOME",
                                style: GoogleFonts.anton(
                                  color: Colors.teal.shade500,
                                  fontSize: 60,
                                )),
                            Text("Login to your account",
                                style: GoogleFonts.ptSansCaption(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 5),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 50.0),
                              child: TextField(
                                controller: emailcontroller,
                                style: const TextStyle(color: Colors.white),
                                cursorColor: Colors.white,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  errorStyle:
                                      const TextStyle(color: Colors.white),
                                  errorBorder: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.red.shade800),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.teal.shade500),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.mail,
                                    color: Colors.grey.shade300,
                                  ),
                                  labelText: "Enter E-Mail",
                                  labelStyle:
                                      const TextStyle(color: Colors.white),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.teal.shade500),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 50.0),
                                child: TextField(
                                  controller: passcontroller,
                                  style: const TextStyle(color: Colors.white),
                                  cursorColor: Colors.white,
                                  obscureText: passwordVisible,
                                  decoration: InputDecoration(
                                    errorStyle:
                                        const TextStyle(color: Colors.white),
                                    errorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.red.shade800),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.teal.shade500),
                                    ),
                                    prefixIcon: const Icon(Icons.password,
                                        color: Colors.white),
                                    suffixIcon: IconButton(
                                      icon: Icon(passwordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off),
                                      color: Colors.white,
                                      onPressed: () {
                                        togglepass();
                                      },
                                    ),
                                    labelText: "Enter Password",
                                    labelStyle:
                                        const TextStyle(color: Colors.white),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.teal.shade500,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                )),
                            const SizedBox(
                              height: 20,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 75,
                              ),
                              child: SizedBox(
                                  width: 150,
                                  height: 40,
                                  child: ElevatedButton(
                                      style: ButtonStyle(
                                        overlayColor: MaterialStateProperty
                                            .resolveWith<Color>(
                                          (Set<MaterialState> states) {
                                            if (states.contains(
                                                MaterialState.pressed)) {
                                              return Colors.teal.shade900
                                                  .withOpacity(0.8);
                                            }
                                            return Colors.transparent;
                                          },
                                        ),
                                        backgroundColor:
                                            MaterialStateProperty.all(
                                          Colors.teal.shade500,
                                        ),
                                      ),
                                      onPressed: () async {
                                        if (emailcontroller.text.isNotEmpty &&
                                            passcontroller.text.isNotEmpty) {
                                          try {
                                            await FirebaseAuth.instance
                                                .signInWithEmailAndPassword(
                                              email: emailcontroller.text,
                                              password: passcontroller.text,
                                            );
                                            clearText();
                                            String? fCMToken =
                                                await FirebaseMessaging.instance
                                                    .getToken();
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(FirebaseAuth
                                                    .instance.currentUser!.uid)
                                                .update({'fcmToken': fCMToken});
                                            _showSnackbar(context);
                                          } on FirebaseAuthException catch (e) {
                                            _showErrorSnackbar(e.code, context);
                                            clearText();
                                          }
                                        } else {
                                          if (emailcontroller.text.isEmpty) {
                                            if (passcontroller.text.isEmpty) {
                                              _showErrorSnackbar(
                                                  "Both Fields are Empty",
                                                  context);
                                            } else {
                                              _showErrorSnackbar(
                                                  "Emai Field Empty", context);
                                            }
                                          } else {
                                            if (!emailcontroller.text.isEmail) {
                                              _showErrorSnackbar(
                                                  "Invalid EMail", context);
                                            } else {
                                              if (passcontroller.text.isEmpty) {
                                                _showErrorSnackbar(
                                                    "Enter Password", context);
                                              }
                                            }
                                          }
                                        }
                                      },
                                      child: Text("LOGIN",
                                          style: GoogleFonts.ptSansCaption(
                                              color: Colors.black,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold)))),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Not a member?',
                                  style: GoogleFonts.ptSans(
                                      color: Colors.white, fontSize: 15),
                                ),
                                TextButton(
                                    onPressed: () async {
                                      showSnackbarWithProgress(context,
                                          "Creating a new User...........", 4);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const registrationPage()),
                                      );
                                    },
                                    child: Text(
                                      'Register Here',
                                      style: GoogleFonts.ptSans(
                                          color: Colors.blue.shade400,
                                          fontSize: 15),
                                    ))
                              ],
                            ),
                            Padding(
                                padding: const EdgeInsets.all(0),
                                child: Text("Sign-in with:",
                                    style: GoogleFonts.ptSans(
                                        color: Colors.white, fontSize: 15))),
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Container(
                                  decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(20)),
                                      color: Colors.grey.shade700),
                                  width: 50,
                                  child: IconButton(
                                    onPressed: () {
                                      signInWithGoogle();
                                    },
                                    icon: Image.asset('assets/google.png'),
                                    iconSize: 50,
                                  )),
                            )
                          ],
                        ),
                      ),
                    )),
                  ));
            }
          }),
    );
  }

  void togglepass() {
    passwordVisible = !passwordVisible;
    setState(() {});
  }

  void showSnackbarWithProgress(
      BuildContext context, String message, int timer) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          SizedBox(width: 50, child: Lottie.asset('assets/loading2.json')),
          const SizedBox(width: 16.0),
          Text(message),
        ],
      ),
      duration: Duration(seconds: timer),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showErrorSnackbar(String message, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(height: 85, child: Lottie.asset('assets/error2.json')),
            const SizedBox(width: 8.0),
            Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
          ],
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSnackbar(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(height: 50, child: Lottie.asset('assets/success.json')),
            const SizedBox(width: 8.0),
            const Text(
              'Logging in..........',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void clearText() {
    emailcontroller.clear();
    passcontroller.clear();
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );
      showSnackbarWithProgress(context, "Please Wait...........", 2);
      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      _showErrorSnackbar(e.code, context);
    }
  }
}
