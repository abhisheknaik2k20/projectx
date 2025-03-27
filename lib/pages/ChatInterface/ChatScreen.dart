import 'dart:convert';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:projectx/pages/ChatInterface/AppBar.dart';
import 'package:projectx/pages/ChatInterface/Message.dart';
import 'package:projectx/pages/ChatInterface/Widget_list.dart';
import 'package:projectx/pages/ChatInterface/chat_Service.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class ChatPage extends StatelessWidget {
  final String receiverEmail;
  final String receiverUid;
  final String receiverName;
  const ChatPage({
    super.key,
    required this.receiverEmail,
    required this.receiverUid,
    required this.receiverName,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: WhatsAppChatAppBar(
            receiverEmail: receiverEmail,
            receiverUid: receiverUid,
            receiverName: receiverName,
            chatroomID: ([FirebaseAuth.instance.currentUser!.uid, receiverUid]
                  ..sort())
                .join("_")),
        body: ChatPageContent(
            receiverUid: receiverUid,
            receiverName: receiverName,
            receiverEmail: receiverEmail));
  }
}

class ChatPageContent extends StatefulWidget {
  final String receiverUid;
  final String receiverName;
  final String receiverEmail;

  const ChatPageContent({
    super.key,
    required this.receiverUid,
    required this.receiverEmail,
    required this.receiverName,
  });

  @override
  State<ChatPageContent> createState() => _ChatPageContentState();
}

class _ChatPageContentState extends State<ChatPageContent>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SpeechToText _speechToText = SpeechToText();
  String wordsSpoken = '';
  File? imageFile;
  File? videoFile;
  File? audioFile;
  File? docFile;
  bool isListning = false;
  bool startcall = false;
  bool shouldListen = false;
  bool speechEnabled = false;
  late String ChatroomID;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    setStatus('Online');
    List<String> ids = [_auth.currentUser!.uid, widget.receiverUid];
    ids.sort();
    ChatroomID =
        ([_auth.currentUser!.uid, widget.receiverUid]..sort()).join("_");
    initializeSpeech();
  }

  void initializeSpeech() async {
    speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void startListning() async {
    String ogText = _messageController.text;
    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          if (_messageController.text.isNotEmpty) {
            String newString = result.recognizedWords;
            _messageController.text = '$ogText $newString';
          } else {
            _messageController.text = result.recognizedWords;
          }
        });
      },
    );
  }

  void stopListning() async {
    await _speechToText.stop();
    setState(() {});
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setStatus('Online');
    } else {
      DateTime now = DateTime.now();
      setStatus('Last seen ${DateFormat('yyyy-MM-dd hh:mm a').format(now)}');
    }
    super.didChangeAppLifecycleState(state);
  }

  void setStatus(String status) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .update({'status': status});
  }

  void sendMessage() async {
    HapticFeedback.selectionClick();
    if (_messageController.text.isNotEmpty) {
      String textmessage = _messageController.text;
      _messageController.clear();
      await _chatService.SendMessage(widget.receiverUid, textmessage);
    }
  }

  Future getImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif'],
    );
    if (result != null) {
      File file = File(result.files.single.path!);
      if (result.files.single.extension?.toLowerCase() == 'jpg' ||
          result.files.single.extension?.toLowerCase() == 'jpeg' ||
          result.files.single.extension?.toLowerCase() == 'png' ||
          result.files.single.extension?.toLowerCase() == 'gif') {
        imageFile = file;
        uploadImage(result.files.single.name);
      } else {
        print("Unsupported file type");
      }
    }
  }

  Future getVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['gif', 'mp4', 'mov', 'avi'],
    );
    if (result != null) {
      File file = File(result.files.single.path!);
      if (result.files.single.extension?.toLowerCase() == 'mp4' ||
          result.files.single.extension?.toLowerCase() == 'mov' ||
          result.files.single.extension?.toLowerCase() == 'avi') {
        videoFile = file;
        uploadVideo(result.files.single.name);
      }
    }
  }

  Future getAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'm4a', 'opus', 'aac'],
    );
    if (result != null) {
      File file = File(result.files.single.path!);
      if (result.files.single.extension?.toLowerCase() == 'mp3' ||
          result.files.single.extension?.toLowerCase() == 'm4a' ||
          result.files.single.extension?.toLowerCase() == 'opus' ||
          result.files.single.extension?.toLowerCase() == 'aac') {
        audioFile = file;
        uploadAudio(result.files.single.name);
      }
    }
  }

  Future getDocs() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      File file = File(result.files.single.path!);
      print(result.files.single.name);
      if (result.files.single.extension?.toLowerCase() == 'pdf') {
        docFile = file;
        uploadPDF(result.files.single.name);
      }
    }
  }

  Future uploadVideo(String actualfilename) async {
    String filename = const Uuid().v1();
    int status = 1;
    List<String> ids = [_auth.currentUser!.uid, widget.receiverUid];
    ids.sort();
    String ChatroomID = ids.join("_");
    await _firestore
        .collection('chat_Rooms')
        .doc(ChatroomID)
        .collection('messages')
        .doc(filename)
        .set({
      'senderName': _auth.currentUser!.displayName,
      'senderId': _auth.currentUser!.uid,
      'senderEmail': _auth.currentUser!.email,
      'reciverId': widget.receiverEmail,
      'message': '',
      'timestamp': Timestamp.now(),
      'type': 'Video',
      'filename': actualfilename
    });
    var ref =
        FirebaseStorage.instance.ref().child('videos').child(actualfilename);
    // ignore: body_might_complete_normally_catch_error
    await ref.putFile(videoFile!).catchError((error) async {
      await _firestore
          .collection('chat_Rooms')
          .doc(ChatroomID)
          .collection('messages')
          .doc(filename)
          .delete();
      status = 0;
    });
    if (status == 1) {
      String ImageUrl = await ref.getDownloadURL();
      await _firestore
          .collection('chat_Rooms')
          .doc(ChatroomID)
          .collection('messages')
          .doc(filename)
          .update({'message': ImageUrl});
      try {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.receiverUid)
            .get();
        Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
        // print('fcmToken :' + data!['fcmToken']);
        var object = {
          'to': data?['fcmToken'],
          'priority': 'high',
          'notification': {
            'title': _auth.currentUser!.displayName,
            'body': 'Video'
          }
        };
        NotificationInfo notificationInfo = NotificationInfo(
          senderName: _auth.currentUser!.displayName!,
          senderID: _auth.currentUser!.uid,
          senderEmail: _auth.currentUser!.email!,
          reciverId: widget.receiverUid,
          recieveMessage: ImageUrl,
          timestamp: Timestamp.now(),
          type: 'Video',
        );
        await _firestore
            .collection('users')
            .doc(widget.receiverUid)
            .collection('noti_Info')
            .add(notificationInfo.toMap());
        await http.post(
          Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization':
                'key=AAAADHtCBX4:APA91bFlK9ZKNKNP0c46KUBQRgnEpf4d1mXhjtjbZXO0Wcp3-zFTPYkKzqUNooJjw6NIwT7BCwlp0Zh9jQ8OpunTJcUk2GsHUj5pngLO-8CXiPPdhGzw0NCStfyryRIel6RkDhn5OTfH',
          },
          body: jsonEncode(object),
        );

        //print(response.statusCode);
        //print(response.body);
      } catch (Except) {
        //print(Except);
      }
    }
  }

  Future uploadAudio(String actualfilename) async {
    String filename = const Uuid().v1();
    int status = 1;
    List<String> ids = [_auth.currentUser!.uid, widget.receiverUid];
    ids.sort();
    String ChatroomID = ids.join("_");
    await _firestore
        .collection('chat_Rooms')
        .doc(ChatroomID)
        .collection('messages')
        .doc(filename)
        .set({
      'senderName': _auth.currentUser!.displayName,
      'senderId': _auth.currentUser!.uid,
      'senderEmail': _auth.currentUser!.email,
      'reciverId': widget.receiverEmail,
      'message': '',
      'timestamp': Timestamp.now(),
      'type': 'Audio',
      'filename': actualfilename
    });
    var ref =
        FirebaseStorage.instance.ref().child('audio').child(actualfilename);
    // ignore: body_might_complete_normally_catch_error
    await ref.putFile(audioFile!).catchError((error) async {
      await _firestore
          .collection('chat_Rooms')
          .doc(ChatroomID)
          .collection('messages')
          .doc(filename)
          .delete();
      status = 0;
    });
    if (status == 1) {
      String ImageUrl = await ref.getDownloadURL();
      await _firestore
          .collection('chat_Rooms')
          .doc(ChatroomID)
          .collection('messages')
          .doc(filename)
          .update({'message': ImageUrl});
      try {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.receiverUid)
            .get();
        Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
        var object = {
          'to': data?['fcmToken'],
          'priority': 'high',
          'notification': {
            'title': _auth.currentUser!.displayName,
            'body': 'Audio'
          }
        };
        NotificationInfo notificationInfo = NotificationInfo(
          senderName: _auth.currentUser!.displayName!,
          senderID: _auth.currentUser!.uid,
          senderEmail: _auth.currentUser!.email!,
          reciverId: widget.receiverUid,
          recieveMessage: ImageUrl,
          timestamp: Timestamp.now(),
          type: 'Audio',
        );
        await _firestore
            .collection('users')
            .doc(widget.receiverUid)
            .collection('noti_Info')
            .add(notificationInfo.toMap());
        await http.post(
          Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization':
                'key=AAAADHtCBX4:APA91bFlK9ZKNKNP0c46KUBQRgnEpf4d1mXhjtjbZXO0Wcp3-zFTPYkKzqUNooJjw6NIwT7BCwlp0Zh9jQ8OpunTJcUk2GsHUj5pngLO-8CXiPPdhGzw0NCStfyryRIel6RkDhn5OTfH',
          },
          body: jsonEncode(object),
        );
      } catch (Except) {
        //  print(Except);
      }
    }
  }

  Future uploadPDF(String actualfilename) async {
    String filename = const Uuid().v1();
    int status = 1;
    List<String> ids = [_auth.currentUser!.uid, widget.receiverUid];
    ids.sort();
    String ChatroomID = ids.join("_");
    await _firestore
        .collection('chat_Rooms')
        .doc(ChatroomID)
        .collection('messages')
        .doc(filename)
        .set({
      'senderName': _auth.currentUser!.displayName,
      'senderId': _auth.currentUser!.uid,
      'senderEmail': _auth.currentUser!.email,
      'reciverId': widget.receiverEmail,
      'message': '',
      'timestamp': Timestamp.now(),
      'type': 'PDF',
      'filename': actualfilename
    });
    var ref = FirebaseStorage.instance.ref().child('pdf').child(actualfilename);
    // ignore: body_might_complete_normally_catch_error
    await ref.putFile(docFile!).catchError((error) async {
      await _firestore
          .collection('chat_Rooms')
          .doc(ChatroomID)
          .collection('messages')
          .doc(filename)
          .delete();
      status = 0;
    });
    if (status == 1) {
      String ImageUrl = await ref.getDownloadURL();
      await _firestore
          .collection('chat_Rooms')
          .doc(ChatroomID)
          .collection('messages')
          .doc(filename)
          .update({'message': ImageUrl});
      try {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.receiverUid)
            .get();
        Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
        // print('fcmToken :' + data!['fcmToken']);
        var object = {
          'to': data?['fcmToken'],
          'priority': 'high',
          'notification': {
            'title': _auth.currentUser!.displayName,
            'body': 'PDF'
          }
        };
        NotificationInfo notificationInfo = NotificationInfo(
          senderName: _auth.currentUser!.displayName!,
          senderID: _auth.currentUser!.uid,
          senderEmail: _auth.currentUser!.email!,
          reciverId: widget.receiverUid,
          recieveMessage: ImageUrl,
          timestamp: Timestamp.now(),
          type: 'PDF',
        );
        await _firestore
            .collection('users')
            .doc(widget.receiverUid)
            .collection('noti_Info')
            .add(notificationInfo.toMap());
        await http.post(
          Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization':
                'key=AAAADHtCBX4:APA91bFlK9ZKNKNP0c46KUBQRgnEpf4d1mXhjtjbZXO0Wcp3-zFTPYkKzqUNooJjw6NIwT7BCwlp0Zh9jQ8OpunTJcUk2GsHUj5pngLO-8CXiPPdhGzw0NCStfyryRIel6RkDhn5OTfH',
          },
          body: jsonEncode(object),
        );

        //print(response.statusCode);
        //print(response.body);
      } catch (Except) {
        //print(Except);
      }
    }
  }

  Future uploadImage(String actualfilename) async {
    String filename = const Uuid().v1();
    int status = 1;
    List<String> ids = [_auth.currentUser!.uid, widget.receiverUid];
    ids.sort();
    String ChatroomID = ids.join("_");
    await _firestore
        .collection('chat_Rooms')
        .doc(ChatroomID)
        .collection('messages')
        .doc(filename)
        .set({
      'senderName': _auth.currentUser!.displayName,
      'senderId': _auth.currentUser!.uid,
      'senderEmail': _auth.currentUser!.email,
      'reciverId': widget.receiverEmail,
      'message': '',
      'timestamp': Timestamp.now(),
      'type': 'Image',
      'filename': actualfilename,
    });
    var ref =
        FirebaseStorage.instance.ref().child('images').child(actualfilename);
    // ignore: body_might_complete_normally_catch_error
    await ref.putFile(imageFile!).catchError((error) async {
      await _firestore
          .collection('chat_Rooms')
          .doc(ChatroomID)
          .collection('messages')
          .doc(filename)
          .delete();
      status = 0;
    });
    if (status == 1) {
      String ImageUrl = await ref.getDownloadURL();
      await _firestore
          .collection('chat_Rooms')
          .doc(ChatroomID)
          .collection('messages')
          .doc(filename)
          .update({'message': ImageUrl});
      print(ImageUrl);
      try {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.receiverUid)
            .get();
        Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
        print('fcmToken :' + data!['fcmToken']);
        var object = {
          'to': data['fcmToken'],
          'priority': 'high',
          'notification': {
            'title': _auth.currentUser!.displayName,
            'body': 'Image'
          }
        };
        NotificationInfo notificationInfo = NotificationInfo(
          senderName: _auth.currentUser!.displayName!,
          senderID: _auth.currentUser!.uid,
          senderEmail: _auth.currentUser!.email!,
          reciverId: widget.receiverUid,
          recieveMessage: ImageUrl,
          timestamp: Timestamp.now(),
          type: 'Image',
        );
        await _firestore
            .collection('users')
            .doc(widget.receiverUid)
            .collection('noti_Info')
            .add(notificationInfo.toMap());

        var response = await http.post(
          Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization':
                'key=AAAADHtCBX4:APA91bFlK9ZKNKNP0c46KUBQRgnEpf4d1mXhjtjbZXO0Wcp3-zFTPYkKzqUNooJjw6NIwT7BCwlp0Zh9jQ8OpunTJcUk2GsHUj5pngLO-8CXiPPdhGzw0NCStfyryRIel6RkDhn5OTfH',
          },
          body: jsonEncode(object),
        );

        print(response.statusCode);
        print(response.body);
      } catch (except) {
        print(except);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: WhatsAppMessageList(
            receiverUid: widget.receiverUid,
            scrollController: _scrollController,
            auth: _auth,
            chatService: _chatService,
            context: context,
            chatroomid: ChatroomID,
          ),
        ),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.black87,
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              showBottomSheet(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                context: context,
                builder: (context) {
                  return Container(
                    padding: const EdgeInsets.only(
                      top: 20,
                      left: 4,
                      right: 4,
                    ),
                    height: 325,
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 44, 43, 43),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: 20,
                          ),
                          child: Container(
                            height: 2,
                            width: 150,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.of(context).pop();
                                getImage();
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset('assets/imageup.png', width: 100),
                                  const Text(
                                    'Send Image',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                    ),
                                  )
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.of(context).pop();
                                getVideo();
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/videoup.png',
                                    width: 100,
                                  ),
                                  const Text(
                                    'Send Video',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                    ),
                                  )
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.of(context).pop();
                                getAudio();
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/audioup.png',
                                    width: 100,
                                  ),
                                  const Text(
                                    'Send Audio',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.of(context).pop();
                                getDocs();
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/docup.png',
                                    width: 100,
                                    height: 100,
                                  ),
                                  const Text(
                                    'Send PDF',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                    ),
                                  )
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.of(context).pop();
                                startListning();
                              },
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.mic,
                                    color: Colors.teal,
                                  ),
                                  Text(
                                    'Speech to Text',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  );
                },
              );
            },
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
            ),
          ),
          isListning
              ? Expanded(
                  child: Container(),
                )
              : Expanded(
                  child: TextField(
                    obscureText: false,
                    controller: _messageController,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                    cursorColor: Colors.teal,
                    decoration: const InputDecoration(
                      hintText: ' Enter Message Here',
                      hintStyle: TextStyle(
                        color: Colors.grey,
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.white,
                        ),
                      ),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 2.0),
            child: GestureDetector(
              onTap: sendMessage,
              onLongPress: () {
                HapticFeedback.heavyImpact();
                setState(() {
                  isListning = true;
                  startListning();
                });
                _showBottomSheet();
              },
              onLongPressEnd: (deatils) {
                setState(() {
                  isListning = false;
                  stopListning();
                });
                Navigator.of(context).pop();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.teal.shade500,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(10),
                  ),
                  border: Border.all(
                    color: Colors.white,
                    width: 2.0,
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(5.0),
                  child: Icon(
                    Icons.send_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBottomSheet() {
    showBottomSheet(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
        ),
        context: context,
        builder: (context) {
          return Container(
            padding: const EdgeInsets.all(
              20,
            ),
            height: 300,
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(40),
                topRight: Radius.circular(40),
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mic, size: 60),
                SizedBox(
                  height: 30,
                ),
                Text(
                  'Listning......',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                )
              ],
            ),
          );
        });
  }
}
