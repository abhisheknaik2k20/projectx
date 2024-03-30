import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'package:projectx/pages/HomeScreen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:projectx/views/reg_Form.dart';
import 'package:projectx/views/phoneNum.dart';
import 'package:projectx/views/verify_mail.dart';
import 'package:lottie/lottie.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class registrationPage extends StatefulWidget {
  const registrationPage({super.key});

  @override
  State<registrationPage> createState() => _registrationPage();
}

class _registrationPage extends State<registrationPage> {
  bool passwordVisible = true;

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Back To Login'),
            content: const Text('Do you want to head back to Login?'),
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
    DateTime dateTime;
    final controller = Get.put(SignupController());
    return WillPopScope(
      onWillPop: _onWillPop,
      child: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null &&
                user.providerData
                    .any((userInfo) => userInfo.providerId == 'password')) {
              if (user.emailVerified) {
                return const HomeScreen();
              } else {
                return const VerifyMail();
              }
            } else {
              return Container();
            }
          } else {
            return Scaffold(
              backgroundColor: const Color.fromARGB(246, 26, 27, 31),
              body: Form(
                key: controller.signupFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: 30, top: 75, left: 10),
                                  child: Text(
                                    "Let's create your account",
                                    style: GoogleFonts.ptSans(
                                        color: Colors.teal.shade500,
                                        fontSize: 30),
                                  ),
                                ),
                              ],
                            ),
                            Form(
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller:
                                              controller.firstnamecontroller,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'First Name is required';
                                            } else {
                                              return null;
                                            }
                                          },
                                          style: const TextStyle(
                                              color: Colors.white),
                                          cursorColor: Colors.white,
                                          decoration: InputDecoration(
                                            errorStyle: const TextStyle(
                                                color: Colors.white),
                                            errorBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.red.shade900),
                                            ),
                                            focusedErrorBorder:
                                                OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.teal.shade500),
                                            ),
                                            prefixIcon: const Icon(
                                                Icons.account_circle_outlined,
                                                color: Colors.white),
                                            labelText: "First name",
                                            labelStyle: const TextStyle(
                                                color: Colors.white),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.grey.shade200),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Colors.teal.shade500,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      Expanded(
                                        child: TextFormField(
                                          controller:
                                              controller.lastnamecontroller,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Last Name is required';
                                            } else {
                                              return null;
                                            }
                                          },
                                          style: const TextStyle(
                                              color: Colors.white),
                                          cursorColor: Colors.white,
                                          decoration: InputDecoration(
                                            errorStyle: const TextStyle(
                                                color: Colors.white),
                                            errorBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.red.shade900),
                                            ),
                                            focusedErrorBorder:
                                                OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.teal.shade500),
                                            ),
                                            prefixIcon: const Icon(
                                                Icons.account_circle_outlined,
                                                color: Colors.white),
                                            labelText: "Last name",
                                            labelStyle: const TextStyle(
                                                color: Colors.white),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.grey.shade200),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.teal.shade500),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: TextFormField(
                                      controller: controller.usernamecontroller,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'UserName is required';
                                        } else {
                                          return null;
                                        }
                                      },
                                      style:
                                          const TextStyle(color: Colors.white),
                                      cursorColor: Colors.white,
                                      decoration: InputDecoration(
                                        errorStyle: const TextStyle(
                                            color: Colors.white),
                                        errorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.red.shade900),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.teal.shade500),
                                        ),
                                        prefixIcon: Icon(
                                          Icons.android_outlined,
                                          color: Colors.green.shade700,
                                          size: 30,
                                        ),
                                        labelText: "Username",
                                        labelStyle: const TextStyle(
                                            color: Colors.white),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.grey.shade200),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.teal.shade500,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: TextFormField(
                                      controller: controller.emailcontroller,
                                      style:
                                          const TextStyle(color: Colors.white),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Email is required';
                                        }
                                        return null;
                                      },
                                      cursorColor: Colors.white,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: InputDecoration(
                                        errorStyle: const TextStyle(
                                            color: Colors.white),
                                        errorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.red.shade900),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.teal.shade500),
                                        ),
                                        prefixIcon: const Icon(Icons.mail,
                                            color: Colors.white),
                                        labelText: "E-Mail",
                                        labelStyle: const TextStyle(
                                            color: Colors.white),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.grey.shade200),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.teal.shade500,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: TextFormField(
                                      controller:
                                          controller.phonenumbercontroller,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Phone Number is required';
                                        } else if (!RegExp(r"^\d+$")
                                            .hasMatch(value)) {
                                          return 'Format must be a number';
                                        } else
                                          return null;
                                      },
                                      style:
                                          const TextStyle(color: Colors.white),
                                      cursorColor: Colors.white,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        errorStyle: const TextStyle(
                                            color: Colors.white),
                                        errorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.red.shade900),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.teal.shade500),
                                        ),
                                        prefixIcon: const Icon(
                                            Icons.phone_android,
                                            color: Colors.white),
                                        labelText: "Phone Number",
                                        labelStyle: const TextStyle(
                                            color: Colors.white),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.grey.shade200),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.teal.shade500,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: TextFormField(
                                      controller: controller.passcontroller,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Password is required';
                                        } else if (value.length < 6) {
                                          return 'Password must be at least 6 characters';
                                        } else
                                          return null;
                                      },
                                      style:
                                          const TextStyle(color: Colors.white),
                                      cursorColor: Colors.white,
                                      obscureText: passwordVisible,
                                      decoration: InputDecoration(
                                        errorStyle: const TextStyle(
                                            color: Colors.white),
                                        errorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.red.shade900),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.teal.shade500),
                                        ),
                                        prefixIcon: const Icon(Icons.password,
                                            color: Colors.white),
                                        suffixIcon: IconButton(
                                          color: Colors.white,
                                          icon: Icon(passwordVisible
                                              ? Icons.visibility
                                              : Icons.visibility_off),
                                          onPressed: () {
                                            togglepass();
                                          },
                                        ),
                                        labelText: "Password",
                                        labelStyle: const TextStyle(
                                            color: Colors.white),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.grey.shade200),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.teal.shade500,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: TextFormField(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text(
                                                "Pick Date",
                                                style: GoogleFonts.roboto(
                                                  fontSize: 30,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.teal.shade400,
                                                ),
                                              ),
                                              content: Container(
                                                height: 100,
                                                child: CupertinoDatePicker(
                                                  mode: CupertinoDatePickerMode
                                                      .date,
                                                  initialDateTime:
                                                      DateTime(1999, 1, 1),
                                                  onDateTimeChanged:
                                                      (DateTime newDateTime) {
                                                    controller
                                                        .dateofbirthcontrol
                                                        .setText(newDateTime
                                                            .toString());
                                                  },
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: Text(
                                                    "Done",
                                                    style: GoogleFonts.roboto(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          Colors.teal.shade400,
                                                    ),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: Text(
                                                    "Close",
                                                    style: GoogleFonts.roboto(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          Colors.teal.shade400,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      readOnly: true,
                                      controller: controller.dateofbirthcontrol,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Date of Birth is required';
                                        }
                                      },
                                      style:
                                          const TextStyle(color: Colors.white),
                                      cursorColor: Colors.white,
                                      decoration: InputDecoration(
                                        errorStyle: const TextStyle(
                                            color: Colors.white),
                                        errorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.red.shade900),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.teal.shade500),
                                        ),
                                        prefixIcon: const Icon(
                                            Icons.calendar_month,
                                            color: Colors.white),
                                        labelText: "Date of Birth",
                                        labelStyle: const TextStyle(
                                            color: Colors.white),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.grey.shade200),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.teal.shade500,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 15, left: 6),
                                        child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: Checkbox(
                                              activeColor: Colors.blue,
                                              checkColor: Colors.white,
                                              value: true,
                                              onChanged: (value) {},
                                            )),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 15, left: 7),
                                        child: Text.rich(TextSpan(children: [
                                          const TextSpan(
                                              text: 'I agree to ',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                          TextSpan(
                                              text: 'Privacy Policy ',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium!
                                                  .apply(
                                                      decoration: TextDecoration
                                                          .underline,
                                                      color: Colors
                                                          .teal.shade400)),
                                          const TextSpan(
                                              text: 'and ',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                          TextSpan(
                                              text: 'Terms and Use',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium!
                                                  .apply(
                                                      decoration: TextDecoration
                                                          .underline,
                                                      color: Colors
                                                          .teal.shade400)),
                                        ])),
                                      )
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: SizedBox(
                                      width: 120,
                                      height: 40,
                                      child: ElevatedButton(
                                        style: ButtonStyle(
                                          overlayColor: MaterialStateProperty
                                              .resolveWith<Color>(
                                            (Set<MaterialState> states) {
                                              if (states.contains(
                                                  MaterialState.pressed)) {
                                                return Colors.grey
                                                    .withOpacity(0.8);
                                              }
                                              return Colors.transparent;
                                            },
                                          ),
                                          backgroundColor:
                                              MaterialStateProperty.all(
                                                  Colors.teal.shade500),
                                        ),
                                        onPressed: () async {
                                          if (controller
                                                  .signupFormKey.currentState
                                                  ?.validate() ??
                                              false) {
                                            await controller.signup(context);
                                            controller.signupFormKey =
                                                GlobalKey<FormState>();
                                          }
                                        },
                                        child: Text(
                                          "Register",
                                          style: GoogleFonts.ptSansCaption(
                                              color: Colors.black,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: TextButton(
                                      onPressed: () async {
                                        if (controller
                                                .signupFormKey.currentState
                                                ?.validate() ??
                                            false) {
                                          showSnackbarWithProgress(context);
                                          await FirebaseAuth.instance
                                              .verifyPhoneNumber(
                                            timeout:
                                                const Duration(seconds: 60),
                                            phoneNumber:
                                                '+91${controller.phonenumbercontroller.text}',
                                            verificationCompleted:
                                                (PhoneAuthCredential
                                                    credential) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Account Created Successfully',
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            },
                                            verificationFailed:
                                                (FirebaseAuthException
                                                    e) async {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    e.code,
                                                    style: const TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            },
                                            codeSent: (String verificationId,
                                                int? resendToken) async {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      phoneNumVerfication(
                                                    firstname: controller
                                                        .firstnamecontroller
                                                        .text,
                                                    lastname: controller
                                                        .lastnamecontroller
                                                        .text,
                                                    username: controller
                                                        .usernamecontroller
                                                        .text,
                                                    email: controller
                                                        .emailcontroller.text,
                                                    phonenumber: controller
                                                        .phonenumbercontroller
                                                        .text,
                                                    password: controller
                                                        .passcontroller.text,
                                                  ),
                                                  settings: RouteSettings(
                                                    arguments: AcceptPhoneNumber(
                                                        controller
                                                            .phonenumbercontroller
                                                            .text,
                                                        verificationId),
                                                  ),
                                                ),
                                              );
                                            },
                                            codeAutoRetrievalTimeout: (String
                                                verificationId) async {},
                                          );
                                        }
                                      },
                                      child: Text(
                                        'Try OTP Verification',
                                        style: GoogleFonts.ptSans(
                                            color: Colors.blue, fontSize: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> showSnackbarWithProgress(BuildContext context) async {
    final snackBar = SnackBar(
      content: Row(
        children: [
          SizedBox(width: 50, child: Lottie.asset('assets/loading2.json')),
          const SizedBox(width: 16.0),
          const Text("Generating OTP..........."),
        ],
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    await Future.delayed(const Duration(seconds: 7));
  }

  void togglepass() {
    passwordVisible = !passwordVisible;
    setState(() {});
  }
}
