// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:projectx/pages/API_Call_Screen/WebRTCLogic.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Signaling signaling = Signaling();
  MediaStream? localStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  String? roomId;
  String? AccessKey;
  String? myUid;
  String? otherUid;
  TextEditingController textEditingController = TextEditingController(text: '');
  DocumentSnapshot? snapshot;
  Map<String, dynamic>? data;
  MediaStream? media;
  bool sending_Call = false;
  bool reciving_Call = false;
  bool isMuted = false;
  bool disableAudio = false;
  bool isCamOn = true;
  bool displayRemoteRenderer = true;
  String? currrentUser;
  String? otherUser;
  static const platform = MethodChannel('samples.flutter.dev/microphone');

  Future<void> _muteMicrophone() async {
    try {
      await platform.invokeMethod('muteMicrophone');
      FirebaseFirestore.instance.collection('rooms').doc(AccessKey).update({
        '${currrentUser}Audio': false,
      });
    } on PlatformException catch (e) {
      print("Failed to mute microphone: '${e.message}'.");
    }
  }

  Future<void> _unmuteMicrophone() async {
    try {
      await platform.invokeMethod('unmuteMicrophone');
      FirebaseFirestore.instance.collection('rooms').doc(AccessKey).update({
        '${currrentUser}Audio': true,
      });
    } on PlatformException catch (e) {
      print("Failed to unmute microphone: '${e.message}'.");
    }
  }

  void createRoom() async {
    roomId = await signaling.createRoom(_remoteRenderer);
    setState(() {});
    AccessKey = data!['key'];
    await FirebaseFirestore.instance.collection('rooms').doc(AccessKey).set({
      'roomID': roomId,
      'user1Cam': true,
      'user1Audio': true,
      'user2Cam': true,
      'user2Audio': true,
      'user1hangup': false,
      'user2hangup': false
    });
    currrentUser = 'user1';
    otherUser = 'user2';
    List substring = AccessKey!.split('_');
    if (substring[0] == FirebaseAuth.instance.currentUser!.uid) {
      myUid = substring[0];
      otherUid = substring[1];
    } else {
      myUid = substring[1];
      otherUid = substring[0];
    }
    print(myUid);
    print(otherUid);
  }

  void joinRoom() async {
    AccessKey = data!['key'];
    snapshot = await db.collection('rooms').doc(AccessKey).get();
    data = snapshot!.data() as Map<String, dynamic>;
    roomId = data?['roomID'];
    signaling.joinRoom(roomId!, _remoteRenderer);
    currrentUser = 'user2';
    otherUser = 'user1';
  }

  void getSnapShot() async {
    snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('call_info')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();
    data = snapshot!.data() as Map<String, dynamic>;
  }

  @override
  void initState() {
    _localRenderer.initialize();
    _remoteRenderer.initialize();
    signaling.onAddRemoteStream = ((stream) {
      _remoteRenderer.srcObject = stream;
      setState(() {});
    });
    getSnapShot();
    signaling.openUserMedia(_localRenderer, _remoteRenderer);
    super.initState();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  FirebaseFirestore db = FirebaseFirestore.instance;
  String uid = FirebaseAuth.instance.currentUser!.uid;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: db
            .collection('users')
            .doc(uid)
            .collection('call_info')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data?.data()?['sending_Call'] == true &&
                sending_Call == false) {
              sending_Call = true;
              createRoom();
            }
            if (snapshot.data?.data()?['reciving_Call'] == true &&
                reciving_Call == false) {
              reciving_Call = true;
              joinRoom();
            }
          }
          return Scaffold(
            backgroundColor: Colors.grey.shade700,
            body: Column(
              children: [
                const SizedBox(height: 8),
                Expanded(
                  child: Stack(
                    alignment: Alignment.bottomLeft,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: StreamBuilder(
                            stream: FirebaseFirestore.instance
                                .collection('rooms')
                                .doc(AccessKey)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                var data = snapshot.data!.data();
                                if (data?['${otherUser}hangup'] == true) {
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'The Call has Ended',
                                            style: GoogleFonts.ptSansCaption(
                                              fontSize: 20,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(5),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(70),
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.call_end,
                                              color: Colors.white,
                                              size: 100,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                }
                                return Stack(
                                  alignment: Alignment.topLeft,
                                  children: [
                                    data?['${otherUser}Cam'] == true
                                        ? RTCVideoView(_remoteRenderer)
                                        : data?['${otherUser}Cam'] == false
                                            ? const Center(
                                                child: Icon(
                                                  Icons.videocam_off,
                                                  color: Colors.white,
                                                  size: 200,
                                                ),
                                              )
                                            : Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Lottie.asset(
                                                        'assets/loading3.json'),
                                                    Text(
                                                      'Connecting.....',
                                                      style: GoogleFonts
                                                          .ptSansCaption(
                                                        fontSize: 15,
                                                        color: Colors.white,
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              ),
                                    data?['${otherUser}Audio'] == false
                                        ? const Padding(
                                            padding: EdgeInsets.all(20.0),
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Icon(
                                                  Icons.circle,
                                                  size: 70,
                                                  color: Color.fromARGB(
                                                      255, 38, 166, 154),
                                                ),
                                                Icon(
                                                  Icons.mic_off,
                                                  color: Colors.white,
                                                  size: 50,
                                                ),
                                              ],
                                            ),
                                          )
                                        : Container()
                                  ],
                                );
                              }
                              return Center(
                                child: CircularProgressIndicator(
                                  color: Colors.teal.shade500,
                                ),
                              );
                            }),
                      ),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(10)),
                          color: Colors.teal.shade500,
                          border: Border.all(
                            color: Colors.teal.shade500,
                          ),
                        ),
                        child: Positioned(
                          child: SizedBox(
                            height: 200,
                            width: 100,
                            child: RTCVideoView(
                              _localRenderer,
                              mirror: true,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 30,
                    right: 30,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(40),
                      ),
                      color: Colors.teal.shade800,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.teal.shade500,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(40),
                            ),
                          ),
                          child: IconButton(
                            onPressed: () async {
                              isMuted = !isMuted;
                              isMuted
                                  ? (_muteMicrophone(),)
                                  : (_unmuteMicrophone());
                              setState(() {});
                            },
                            icon: isMuted
                                ? const Icon(
                                    Icons.mic_off,
                                    color: Colors.white,
                                    size: 60,
                                  )
                                : const Icon(
                                    Icons.mic,
                                    color: Colors.white,
                                    size: 60,
                                  ),
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.teal.shade500,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(40),
                            ),
                          ),
                          child: IconButton(
                            onPressed: () async {
                              isCamOn = !isCamOn;
                              FirebaseFirestore.instance
                                  .collection('rooms')
                                  .doc(AccessKey)
                                  .update({
                                '${currrentUser}Cam': isCamOn,
                              });
                              setState(() {});
                            },
                            icon: isCamOn
                                ? const Icon(
                                    Icons.videocam,
                                    color: Colors.white,
                                    size: 60,
                                  )
                                : const Icon(
                                    Icons.videocam_off,
                                    color: Colors.white,
                                    size: 60,
                                  ),
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.all(
                              Radius.circular(40),
                            ),
                          ),
                          child: IconButton(
                            onPressed: () async {
                              signaling.hangUp(_localRenderer);
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(FirebaseAuth.instance.currentUser!.uid)
                                  .collection('call_info')
                                  .doc(FirebaseAuth.instance.currentUser!.uid)
                                  .delete();
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(FirebaseAuth.instance.currentUser!.uid)
                                  .update({'isCall': false});
                              try {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(otherUid)
                                    .collection('call_info')
                                    .doc(otherUid)
                                    .delete();
                                await FirebaseFirestore.instance
                                    .collection('rooms')
                                    .doc(AccessKey)
                                    .update({'${currrentUser}hangup': true});
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(otherUid)
                                    .update({'isCall': false});
                              } catch (e) {}
                              // ignore: use_build_context_synchronously
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(
                              Icons.call_end,
                              color: Colors.white,
                              size: 60,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
              ],
            ),
          );
        });
  }
}
