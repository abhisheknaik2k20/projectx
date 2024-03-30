import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:projectx/pages/HomeScreen.dart';
import 'package:projectx/pages/QRScanner/SuccessLoading.dart';
import 'package:projectx/pages/QRScanner/SuccessPage.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QRScanner extends StatefulWidget {
  const QRScanner({super.key});

  @override
  State<QRScanner> createState() => _QRScannerState();
}

class _QRScannerState extends State<QRScanner> {
  Barcode? result;
  QRViewController? controller;
  bool isVisible = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _showWrongQR() {
    showDialog(
        context: context,
        builder: ((context) => AlertDialog(
              alignment: Alignment.center,
              backgroundColor: Colors.red.shade200,
              title: Text(
                'IMPROPER QR',
                style: GoogleFonts.anton(
                    fontSize: 40,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]),
              ),
              content: Lottie.asset('assets/wrongqr.json'),
              actions: [
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateColor.resolveWith(
                      (states) {
                        if (states.contains(MaterialState.pressed)) {
                          return Colors.red.shade900;
                        }
                        if (states.contains(MaterialState.hovered)) {
                          return Colors.red.shade700;
                        }
                        return Colors.red.shade400;
                      },
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'OK',
                    style: GoogleFonts.anton(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            )));
  }

  void _showInitialAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.teal.shade200,
        title: Text(
          'Welcome',
          style: GoogleFonts.anton(fontSize: 40, color: Colors.white, shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ]),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Lottie.asset('assets/qr3.json'),
              Text(
                '1. Open The app on WEB',
                style: GoogleFonts.ptSans(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Text(
                '2. Scan the QR code displayed on your computer screen.',
                softWrap: true,
                style: GoogleFonts.ptSans(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Text(
                "3. Once scanned, you're logged in to  Web app",
                style: GoogleFonts.ptSans(
                  fontSize: 20,
                  color: Colors.white,
                ),
              )
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateColor.resolveWith(
                (states) {
                  if (states.contains(MaterialState.pressed)) {
                    return Colors.teal.shade900;
                  }
                  if (states.contains(MaterialState.hovered)) {
                    return Colors.teal.shade700;
                  }
                  return Colors.teal.shade500;
                },
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.anton(
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onQRViewCreated(QRViewController controller) async {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
      });
    });
    if (result != null) {
      if (result!.code!.endsWith('projectx-223eb.web.app')) {
        String ID = result!.code!.replaceAll('projectx-223eb.web.app', '');
        try {
          DocumentSnapshot snapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .get();
          if (snapshot.exists) {
            Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
            if (data['WEB'] == null) {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(ID)
                  .set(data);
            }
          }
        } catch (error) {
          //print('Error fetching data: $error');
        }
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (context) => SuccessLoading(
                    resultid: ID,
                  )),
        );
      } else {
        _showWrongQR();
        print('ERROR');
      }
    }
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Back To HomeScreen',
              style: GoogleFonts.ptSans(
                fontSize: 20,
                color: Colors.grey.shade800,
              ),
            ),
            content: const Text('Do you want to head back?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'No',
                  style: GoogleFonts.ptSans(
                    fontSize: 20,
                    color: Colors.teal.shade500,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const HomeScreen(),
                    ),
                    (route) => false),
                child: Text(
                  'Yes',
                  style: GoogleFonts.ptSans(
                    fontSize: 20,
                    color: Colors.teal.shade500,
                  ),
                ),
              ),
            ],
          ),
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    FirebaseFirestore db = FirebaseFirestore.instance;
    FirebaseAuth auth = FirebaseAuth.instance;
    return WillPopScope(
      onWillPop: _onWillPop,
      child: StreamBuilder(
        stream: db.collection('users').doc(auth.currentUser!.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            Map<String, dynamic> data = snapshot.data!.data()!;
            if (data['WEB'] != null) {
              return Success(resultid: data['WEB']);
            } else {
              return Scaffold(
                appBar: AppBar(
                  backgroundColor: Colors.teal.shade500,
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  title: Text(
                    'Scan QR code',
                    style: GoogleFonts.ubuntu(
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                      fontSize: 30,
                      color: Colors.white,
                    ),
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(left: 15.0),
                      child: IconButton(
                        onPressed: () {
                          _showInitialAlert();
                        },
                        icon: const Icon(
                          Icons.question_mark_outlined,
                          color: Colors.white,
                        ),
                      ),
                    )
                  ],
                ),
                backgroundColor: Colors.grey.shade200,
                body: Container(
                  width: double.maxFinite,
                  alignment: Alignment.center,
                  child: Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        isVisible
                            ? Container(
                                decoration: const BoxDecoration(
                                  color: Colors.grey,
                                ),
                              )
                            : QRView(
                                key: GlobalKey(debugLabel: 'QR'),
                                onQRViewCreated: _onQRViewCreated,
                              ),
                        Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Lottie.asset(
                            'assets/qr.json',
                            fit: BoxFit.cover,
                            width: 500,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            }
          } else {
            return Scaffold(
              body: Container(
                color: Colors.grey.shade400,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.teal.shade500,
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
