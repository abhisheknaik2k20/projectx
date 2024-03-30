import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_swipe/PageHelpers/LiquidController.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:lottie/lottie.dart';
import 'package:projectx/views/flashScreen.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class welcomeScreen extends StatefulWidget {
  const welcomeScreen({super.key});

  @override
  State<welcomeScreen> createState() => _welcomeScreenState();
}

class _welcomeScreenState extends State<welcomeScreen> {
  LiquidController controllerl = LiquidController();
  int totalPages = 5;
  bool isVisible = true;
  bool islastPage = false;
  bool loaded = false;

  @override
  void initState() {
    loaded = true;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return loaded
        ? Scaffold(
            body: Stack(
            children: [
              LiquidSwipe(
                liquidController: controllerl,
                waveType: WaveType.liquidReveal,
                onPageChangeCallback: (index) {
                  setState(() {
                    islastPage = index == (totalPages - 1);
                    isVisible = !islastPage;
                  });
                },
                slideIconWidget: isVisible
                    ? SizedBox(
                        width: 100,
                        height: 100,
                        child: Lottie.asset('assets/left2.json',
                            fit: BoxFit.cover))
                    : const SizedBox(),
                pages: [
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
                              padding:
                                  const EdgeInsets.only(left: 60, right: 60),
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
                              padding:
                                  const EdgeInsets.only(left: 60, right: 60),
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
                                      builder: (context) =>
                                          const flashScreen()),
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
                              padding:
                                  const EdgeInsets.only(left: 60, right: 60),
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
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedSmoothIndicator(
                      activeIndex: controllerl.currentPage,
                      count: totalPages,
                      effect: const WormEffect(
                        spacing: 16,
                        dotColor: Colors.white54,
                        activeDotColor: Colors.white,
                      ),
                      onDotClicked: (index) => {
                        controllerl.animateToPage(page: index),
                      },
                    ),
                  ),
                ),
              )
            ],
          ))
        : Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.teal.shade500,
              ),
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
