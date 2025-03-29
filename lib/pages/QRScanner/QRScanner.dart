import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:SwiftTalk/pages/BlackScreen.dart';
import 'package:SwiftTalk/pages/QRScanner/SuccessPage.dart';
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
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      if (Theme.of(context).platform == TargetPlatform.android) {
        controller!.pauseCamera();
      }
      controller!.resumeCamera();
    }
  }

  void _showWrongQR() {
    showDialog(
      context: context,
      builder: ((context) => AlertDialog(
            alignment: Alignment.center,
            backgroundColor: Colors.red.shade200,
            title: Text(
              'IMPROPER QR',
              style: TextStyle(
                  fontSize: 40,
                  color: Colors.white,
                  fontFamily: 'Anton',
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]),
            ),
            content: const Icon(Icons.close, size: 100, color: Colors.white),
            actions: [
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateColor.resolveWith(
                    (states) {
                      if (states.contains(WidgetState.pressed)) {
                        return Colors.red.shade900;
                      }
                      if (states.contains(WidgetState.hovered)) {
                        return Colors.red.shade700;
                      }
                      return Colors.red.shade400;
                    },
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  // Resume camera after wrong QR dialog
                  controller?.resumeCamera();
                },
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontFamily: 'Anton',
                  ),
                ),
              ),
            ],
          )),
    );
  }

  void _showInitialAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.teal.shade200,
        title: Text(
          'Welcome',
          style: TextStyle(
              fontSize: 40,
              color: Colors.white,
              fontFamily: 'Anton',
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]),
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.qr_code, size: 100, color: Colors.white),
              Text(
                '1. Open The app on WEB',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontFamily: 'PTSans',
                ),
              ),
              SizedBox(height: 20),
              Text(
                '2. Scan the QR code displayed on your computer screen.',
                softWrap: true,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontFamily: 'PTSans',
                ),
              ),
              SizedBox(height: 20),
              Text(
                "3. Once scanned, you're logged in to  Web app",
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontFamily: 'PTSans',
                ),
              )
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateColor.resolveWith(
                (states) {
                  if (states.contains(WidgetState.pressed)) {
                    return Colors.teal.shade900;
                  }
                  if (states.contains(WidgetState.hovered)) {
                    return Colors.teal.shade700;
                  }
                  return Colors.teal.shade500;
                },
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontFamily: 'Anton',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processQRCode(String ID) async {
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

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (context) => SuccessLoading(
                    resultid: ID,
                  )),
        );
      }
    } catch (error) {
      print('Error processing QR code: $error');
      // Show error dialog or handle the error appropriately
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing QR code: $error'),
          backgroundColor: Colors.red,
        ),
      );
      // Resume camera if processing fails
      controller?.resumeCamera();
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });

    controller.scannedDataStream.listen((scanData) async {
      // Pause camera to prevent multiple scans
      await controller.pauseCamera();

      if (scanData.code != null) {
        if (scanData.code!.endsWith('SwiftTalk-223eb.web.app')) {
          String ID = scanData.code!.replaceAll('SwiftTalk-223eb.web.app', '');
          await _processQRCode(ID);
        } else {
          _showWrongQR();
          // Resume camera after showing wrong QR dialog
          await controller.resumeCamera();
        }
      } else {
        // Resume camera if no valid code
        await controller.resumeCamera();
      }
    }, onError: (error) {
      print('QR Scan Stream Error: $error');
      controller.resumeCamera();
    });
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Back To HomeScreen',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey.shade800,
                fontFamily: 'PTSans',
              ),
            ),
            content: const Text('Do you want to head back?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'No',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.teal.shade500,
                    fontFamily: 'PTSans',
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const BlackScreen(),
                    ),
                    (route) => false),
                child: Text(
                  'Yes',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.teal.shade500,
                    fontFamily: 'PTSans',
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
                    style: TextStyle(
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                      fontSize: 30,
                      color: Colors.white,
                      fontFamily: 'Ubuntu',
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
                body: Column(
                  children: <Widget>[
                    Expanded(
                      flex: 5,
                      child: QRView(
                        key: qrKey,
                        onQRViewCreated: _onQRViewCreated,
                        overlay: QrScannerOverlayShape(
                          borderColor: Colors.teal.shade500,
                          borderRadius: 10,
                          borderLength: 30,
                          borderWidth: 10,
                          cutOutSize: 300,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: Text(
                          'Align QR code within the scan area',
                          style: TextStyle(
                            color: Colors.teal.shade500,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    )
                  ],
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

class SuccessLoading extends StatefulWidget {
  final String resultid;
  const SuccessLoading({super.key, required this.resultid});

  @override
  State<SuccessLoading> createState() => _SuccessLoadingState();
}

class _SuccessLoadingState extends State<SuccessLoading> {
  @override
  void initState() {
    super.initState();
    Timer(
      const Duration(seconds: 5),
      () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => Success(
                    resultid: widget.resultid,
                  )),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade400,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_download,
              size: 100,
              color: Colors.grey.shade800,
            ),
            const SizedBox(height: 20),
            Text(
              'Fetching Details.....',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade800,
              ),
            )
          ],
        ),
      ),
    );
  }
}
