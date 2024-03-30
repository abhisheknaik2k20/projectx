import 'package:flutter/material.dart';
import 'package:flutter_carousel_slider/carousel_slider.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:projectx/views/flashScreen.dart';

class WelcomeScreen2 extends StatefulWidget {
  const WelcomeScreen2({super.key});

  @override
  State<WelcomeScreen2> createState() => _WelcomeScreen2State();
}

class _WelcomeScreen2State extends State<WelcomeScreen2> {
  @override
  Widget build(BuildContext context) {
    double screenheight = MediaQuery.of(context).size.height;
    double screenwidth = MediaQuery.of(context).size.width;
    CarouselSliderController cs = CarouselSliderController();

    @override
    void initstate() {
      cs.reactive.addListener(() {});
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          CarouselSlider(
            controller: cs,
            unlimitedMode: true,
            slideTransform: const CubeTransform(),
            slideIndicator: CircularSlideIndicator(
              padding: const EdgeInsets.only(
                bottom: 50,
              ),
              currentIndicatorColor: Colors.white,
            ),
            children: [
              Container(
                  color: Colors.teal.shade500,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.asset('assets/hello.json'),
                        Text(
                          "HELLO!",
                          style: GoogleFonts.anton(fontSize: 40),
                        ),
                        Text(
                          "Welcome to our Messaging App!",
                          style: GoogleFonts.ptSansCaption(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                  )),
              Container(
                  color: Colors.pink,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.asset('assets/animation3.json'),
                        Padding(
                          padding: const EdgeInsets.only(left: 60, right: 60),
                          child: Text(
                            "Connect instantly with friends and loved ones, no matter the distance",
                            style: GoogleFonts.ptSansCaption(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                  )),
              Container(
                  color: Colors.amber,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.asset('assets/gc.json'),
                        Padding(
                          padding: const EdgeInsets.only(left: 60, right: 60),
                          child: Text(
                            "Connect with multiple friends at once - create and enjoy group chats for easy collaboration",
                            style: GoogleFonts.ptSansCaption(
                                fontSize: 20,
                                color: Colors.blue.shade900,
                                fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                  )),
              Container(
                color: Colors.blue,
                child: Stack(
                  children: [
                    Positioned(
                      top: 100,
                      left: 45,
                      child: SizedBox(
                        width: 250,
                        child: Lottie.asset('assets/flutter.json'),
                      ),
                    ),
                    Positioned(
                      top: 200,
                      right: 45,
                      child: SizedBox(
                        width: 250,
                        child: Lottie.asset('assets/firebase.json'),
                      ),
                    ),
                    Positioned.fill(
                      top: 250,
                      child: Center(
                          child: Padding(
                        padding: const EdgeInsets.only(left: 60, right: 60),
                        child: Text(
                          " This app is crafted with Flutter for a smooth interface and fortified by Firebase's advanced security features",
                          style: GoogleFonts.ptSansCaption(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      )),
                    )
                  ],
                ),
              ),
              Container(
                  color: const Color.fromARGB(255, 26, 27, 31),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                            padding: const EdgeInsets.all(8),
                            child: Lottie.asset("assets/log.json")),
                        InkWell(
                          onTap: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const flashScreen()),
                              (route) => false,
                            );
                            showSnackbarWithProgress(context);
                          },
                          child: SizedBox(
                            width: 300,
                            child: Stack(
                              children: [
                                Lottie.asset('assets/start.json'),
                                Positioned.fill(
                                  child: Center(
                                    child: Text(
                                      'Login',
                                      style: GoogleFonts.anton(
                                        color: Colors.white,
                                        fontSize: 40,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 60, right: 60),
                          child: Text(
                            "Let's Get Started!",
                            style: GoogleFonts.ptSansCaption(
                                fontSize: 20,
                                color: Colors.teal,
                                fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                  )),
            ],
          ),
          Positioned(
            top: screenheight * 0.8,
            right: screenwidth * 0.1,
            child: SizedBox(
              width: 100,
              height: 100,
              child: Lottie.asset('assets/left2.json', fit: BoxFit.cover),
            ),
          )
        ],
      ),
    );
  }

  void showSnackbarWithProgress(BuildContext context) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          SizedBox(width: 50, child: Lottie.asset('assets/loading2.json')),
          const SizedBox(width: 16.0),
          const Text("Loading, Please Wait......."),
        ],
      ),
      duration: const Duration(seconds: 4),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
