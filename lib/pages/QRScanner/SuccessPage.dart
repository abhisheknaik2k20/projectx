import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:projectx/pages/QRScanner/QRScanner.dart';
import 'package:intl/intl.dart';

// ignore: must_be_immutable
class Success extends StatefulWidget {
  String resultid;
  Success({super.key, required this.resultid});

  @override
  State<Success> createState() => _SuccessState();
}

class _SuccessState extends State<Success> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    FirebaseFirestore db = FirebaseFirestore.instance;
    FirebaseAuth auth = FirebaseAuth.instance;
    double screenHeight = MediaQuery.of(context).size.height;

    return StreamBuilder(
      stream: db.collection('users').doc(auth.currentUser!.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          Map<String, dynamic> data = snapshot.data!.data()!;
          if (data['WEB'] != null) {
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  'Desktop Details',
                  style: TextStyle(fontSize: 30, color: Colors.white, shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                centerTitle: true,
              ),
              body: SizedBox(
                width: double.maxFinite,
                child: StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(data['uid'])
                        .collection('WEB')
                        .doc(data['WEB'])
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        Map<String, dynamic> data2 = snapshot.data!.data()!;
                        DateTime dateTime = DateTime.fromMicrosecondsSinceEpoch(
                            data2['TimeStamp'].microsecondsSinceEpoch);
                        String formattedDate =
                            DateFormat('dd-MM-yy  HH:mm aa').format(dateTime);
                        return Column(
                          children: [
                            Container(
                              height: screenHeight * 0.25,
                              width: double.maxFinite,
                              decoration: BoxDecoration(
                                color: Colors.teal.shade500,
                                borderRadius: const BorderRadius.only(
                                  bottomRight: Radius.circular(70),
                                ),
                              ),
                              child: const Icon(
                                Icons.desktop_windows,
                                size: 100,
                                color: Colors.white,
                              ),
                            ),
                            Stack(
                              children: [
                                Container(
                                  height: screenHeight * 0.5,
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade500,
                                  ),
                                ),
                                Container(
                                  height: screenHeight * 0.5,
                                  width: double.maxFinite,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(70),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(30),
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      width: double.maxFinite,
                                      decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.all(
                                            Radius.circular(40),
                                          ),
                                          gradient: LinearGradient(colors: [
                                            Colors.teal.shade500,
                                            Colors.teal.shade600,
                                            Colors.teal.shade700,
                                          ])),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Container(
                                              width: double.maxFinite,
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  bottom: BorderSide(
                                                    color: Colors.grey.shade400,
                                                  ),
                                                ),
                                              ),
                                              child: Text(
                                                "IP Address : ${data2['IP Address']}",
                                                style: TextStyle(
                                                  fontSize: 25,
                                                  color: Colors.grey.shade100,
                                                ),
                                              )),
                                          Container(
                                              width: double.maxFinite,
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  bottom: BorderSide(
                                                    color: Colors.grey.shade400,
                                                  ),
                                                ),
                                              ),
                                              child: Text(
                                                "City :  ${data2['City']}",
                                                style: TextStyle(
                                                  fontSize: 25,
                                                  color: Colors.grey.shade100,
                                                ),
                                              )),
                                          Container(
                                            width: double.maxFinite,
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: Colors.grey.shade400,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              "Region : ${data2['Region']}",
                                              style: TextStyle(
                                                fontSize: 25,
                                                color: Colors.grey.shade100,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            width: double.maxFinite,
                                            padding: const EdgeInsets.all(10),
                                            child: Text(
                                              "Login TimeStamp : $formattedDate",
                                              style: TextStyle(
                                                fontSize: 25,
                                                color: Colors.grey.shade100,
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: ElevatedButton(
                                style: ButtonStyle(
                                  backgroundColor: WidgetStateColor.resolveWith(
                                    (states) {
                                      if (states
                                          .contains(WidgetState.pressed)) {
                                        return Colors.teal.shade900;
                                      }
                                      if (states
                                          .contains(WidgetState.hovered)) {
                                        return Colors.teal.shade700;
                                      }
                                      return Colors.teal.shade500;
                                    },
                                  ),
                                ),
                                onPressed: () async {
                                  print(widget.resultid);
                                  await db
                                      .collection('users')
                                      .doc(auth.currentUser!.uid)
                                      .update({'WEB': null});
                                  print('SET NULL');
                                  await db
                                      .collection('users')
                                      .doc(auth.currentUser!.uid)
                                      .collection('WEB')
                                      .doc(widget.resultid)
                                      .delete();
                                  print('DELETED');
                                },
                                child: const Text(
                                  'LOGOUT',
                                  style: TextStyle(
                                    fontSize: 35,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Container(
                          color: Colors.grey.shade400,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.teal.shade500,
                            ),
                          ),
                        );
                      }
                    }),
              ),
            );
          } else {
            return const QRScanner();
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
          ));
        }
      },
    );
  }
}
