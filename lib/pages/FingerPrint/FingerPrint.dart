import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:projectx/pages/HomeScreen.dart';

class FingerScannerClass extends StatefulWidget {
  const FingerScannerClass({super.key});

  @override
  State<FingerScannerClass> createState() => _FingerScannerClassState();
}

class _FingerScannerClassState extends State<FingerScannerClass> {
  @override
  void initState() {
    auth = LocalAuthentication();
    auth.isDeviceSupported().then((bool isDeviceSupported) => setState(() {
          _supportState = isDeviceSupported;
        }));
    super.initState();
  }

  late final LocalAuthentication auth;
  late final List<BiometricType> availablebiometrics;
  late bool _authenticated;
  bool _supportState = false;
  @override
  Widget build(BuildContext context) {
    if (_supportState) {
      _getAvailableBio();
    }
    return const Scaffold(
      body: Column(
        children: [],
      ),
    );
  }

  Future<void> _getAvailableBio() async {
    try {
      availablebiometrics = await auth.getAvailableBiometrics();
      _authenticate();
    } catch (e) {
      print(e);
    }
  }

  Future<void> _authenticate() async {
    try {
      bool _authenticated = await auth.authenticate(
        localizedReason: '     ',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      print("Authenticate : $_authenticated");
      if (!_authenticated) {
        _authenticated;
      } else {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) {
          return const HomeScreen();
        }));
      }
    } on PlatformException catch (e) {
      print(e);
    }
  }
}
