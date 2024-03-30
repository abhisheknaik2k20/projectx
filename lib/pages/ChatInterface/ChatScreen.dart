import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pinput/pinput.dart';
import 'package:projectx/pages/API_Call_Screen/Screen1.dart';
import 'package:projectx/pages/CAllScreen/callScreen.dart';
import 'package:projectx/pages/ChatInterface/ImagePage.dart';
import 'package:projectx/pages/ChatInterface/Notification.dart';
import 'package:projectx/pages/ChatInterface/PDFView/pdfview.dart';
import 'package:projectx/pages/ChatInterface/Video_player/VideoPlayer.dart';
import 'package:projectx/pages/ChatInterface/chatBubble.dart';
import 'package:projectx/pages/ChatInterface/chat_Service.dart';
import 'package:projectx/pages/Profile.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:stroke_text/stroke_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;

class ChatPage extends StatelessWidget {
  final String receiverEmail;
  final String receiverUid;
  final String receiverName;
  const ChatPage({
    Key? key,
    required this.receiverEmail,
    required this.receiverUid,
    required this.receiverName,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    FirebaseFirestore db = FirebaseFirestore.instance;
    FirebaseAuth _auth = FirebaseAuth.instance;
    List<String> ids = [_auth.currentUser!.uid, receiverUid];
    ids.sort();
    String ChatroomID = ids.join("_");

    void setReciver() async {
      await db
          .collection('users')
          .doc(receiverUid)
          .collection('call_info')
          .doc(receiverUid)
          .set(
        {
          'key': ChatroomID,
          'reciving_Call': true,
          'sending_Call': false,
          'caller_Name': _auth.currentUser?.displayName
        },
      );
    }

    void setSender() async {
      await db
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('call_info')
          .doc(_auth.currentUser!.uid)
          .set(
        {
          'key': ChatroomID,
          'reciving_Call': false,
          'sending_Call': true,
        },
      );
    }

    return StreamBuilder(
        stream: db.collection('users').doc(_auth.currentUser!.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.data?.data()?['isCall'] != null) {
            if (snapshot.data?.data()?['isCall'] != false) {
              return CallScreen();
            }
          }
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(
                  Icons.arrow_back_ios,
                  size: 25,
                  color: Colors.white,
                ),
              ),
              centerTitle: true,
              title: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(receiverUid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return SingleChildScrollView(
                      child: Container(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              receiverName,
                              style: GoogleFonts.ptSans(
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 25,
                              ),
                            ),
                            StrokeText(
                              text: snapshot.data!['status'],
                              textStyle: GoogleFonts.ptSans(
                                color: snapshot.data!['status'] == 'Online'
                                    ? Colors.blue
                                    : Colors.white,
                                fontSize: 12,
                              ),
                              strokeColor: Colors.grey.shade800,
                              strokeWidth: 1,
                            )
                          ],
                        ),
                      ),
                    );
                  } else {
                    return Container();
                  }
                },
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(
                          UserUID: receiverUid,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.info,
                    size: 25,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(receiverUid)
                        .update({'isCall': true});
                    DocumentSnapshot datasnapshot = await FirebaseFirestore
                        .instance
                        .collection('users')
                        .doc(receiverUid)
                        .get();
                    Map<String, dynamic>? datasnapshot2 =
                        datasnapshot.data() as Map<String, dynamic>?;
                    var object = {
                      'to': datasnapshot2!['fcmToken'],
                      'priority': 'high',
                      'data': {
                        'custom_key': 'custom_value',
                        'other_key': 'other_value'
                      }
                    };
                    await await http.post(
                      Uri.parse('https://fcm.googleapis.com/fcm/send'),
                      headers: {
                        'Content-Type': 'application/json',
                        'Authorization':
                            'key=AAAADHtCBX4:APA91bFlK9ZKNKNP0c46KUBQRgnEpf4d1mXhjtjbZXO0Wcp3-zFTPYkKzqUNooJjw6NIwT7BCwlp0Zh9jQ8OpunTJcUk2GsHUj5pngLO-8CXiPPdhGzw0NCStfyryRIel6RkDhn5OTfH',
                      },
                      body: jsonEncode(object),
                    );
                    setReciver();
                    setSender();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MyHomePage(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.call,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.video_call,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            body: ChatPageContent(
              receiverUid: receiverUid,
              receiverName: receiverName,
              receiverEmail: receiverEmail,
            ),
          );
        });
  }
}

class ChatPageContent extends StatefulWidget {
  final String receiverUid;
  final String receiverName;
  final String receiverEmail;

  const ChatPageContent({
    Key? key,
    required this.receiverUid,
    required this.receiverEmail,
    required this.receiverName,
  }) : super(key: key);

  @override
  _ChatPageContentState createState() => _ChatPageContentState();
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
    ChatroomID = ids.join("_");
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
            _messageController.setText('$ogText $newString');
          } else {
            _messageController.setText(result.recognizedWords);
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
      await _chatService.SendMessage(
        widget.receiverUid,
        textmessage,
      );
    }
  }

  Future getImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'jpg',
        'jpeg',
        'png',
      ],
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
      allowedExtensions: [
        'gif',
        'mp4',
        'mov',
        'avi',
      ],
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
      allowedExtensions: [
        'pdf',
      ],
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
      } catch (Except) {
        print(Except);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildMessageList()),
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
                                  Text(
                                    'Send Image',
                                    style: GoogleFonts.ptSansCaption(
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
                                  Text(
                                    'Send Video',
                                    style: GoogleFonts.ptSansCaption(
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
                                  Text(
                                    'Send Audio',
                                    style: GoogleFonts.ptSansCaption(
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
                                  Text(
                                    'Send PDF',
                                    style: GoogleFonts.ptSansCaption(
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
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Lottie.asset(
                                    'assets/mic.json',
                                    width: 100,
                                    height: 100,
                                  ),
                                  Text(
                                    'Speech to Text',
                                    style: GoogleFonts.ptSansCaption(
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
                    style: GoogleFonts.ptSansCaption(
                      color: Colors.white,
                    ),
                    cursorColor: Colors.teal,
                    decoration: InputDecoration(
                      hintText: ' Enter Message Here',
                      hintStyle: GoogleFonts.ptSansCaption(
                        color: Colors.grey.shade500,
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.white,
                        ),
                      ),
                      border: const UnderlineInputBorder(
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

  Widget _buildMessageList() {
    return StreamBuilder(
      stream: _chatService.getMessages(
        widget.receiverUid,
        _auth.currentUser!.uid,
      ),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text('Error${snapshot.error}');
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
              child: SingleChildScrollView(
            child: Column(
              children: [
                Lottie.asset('assets/startchat.json'),
                Text(
                  'Start Chatting.......',
                  style: GoogleFonts.ptSansCaption(
                    fontSize: 20,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ));
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        });
        return ListView(
          controller: _scrollController,
          children: snapshot.data!.docs
              .map(
                (document) => _buildMessageItem(document),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    var alignment = (data['senderId'] == _auth.currentUser!.uid)
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    return SizedBox(
      width: 100,
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
            child:
                Text(data['senderName'], style: const TextStyle(fontSize: 12)),
          ),
          data['type'] == 'text'
              ? data['senderId'] == _auth.currentUser!.uid
                  ? data['edit'] == true
                      ? GestureDetector(
                          onLongPress: () {
                            HapticFeedback.heavyImpact();
                            _showBottomSheetDetails(data, true, document);
                          },
                          child: ChatBubble(
                            value: data['edit'] ?? false,
                            message: data['message'],
                            document: document,
                          ))
                      : GestureDetector(
                          onLongPress: () {
                            HapticFeedback.heavyImpact();
                            _showBottomSheetDetails(data, true, document);
                          },
                          child: ChatBubble(
                            value: data['edit'] ?? false,
                            message: data['message'],
                            document: document,
                          ))
                  : GestureDetector(
                      onLongPress: () {
                        HapticFeedback.heavyImpact();
                        _showBottomSheetDetails(data, false, document);
                      },
                      child: ChatBubble(
                        value: data['edit'] ?? false,
                        message: data['message'],
                        document: document,
                      ))
              : data['type'] == null
                  ? ChatBubble(
                      value: data['edit'] ?? false,
                      message: data['message'],
                      document: document,
                    )
                  : Container(
                      padding: const EdgeInsets.all(10),
                      width: MediaQuery.of(context).size.width * 0.45,
                      decoration: BoxDecoration(
                        color: (data['senderId'] == _auth.currentUser!.uid)
                            ? Colors.teal.shade300
                            : Colors.grey.shade300,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(20),
                        ),
                      ),
                      child: GestureDetector(
                        onTap: () => _handleMediaTap(data),
                        onLongPress: () async {
                          HapticFeedback.heavyImpact();
                          if (_auth.currentUser!.uid == data['senderId']) {
                            _showBottomSheetDetails(data, true, document);
                          } else {
                            _showBottomSheetDetails(data, false, document);
                          }
                        },
                        child: data['type'] == 'Image'
                            ? Column(
                                crossAxisAlignment: alignment,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(20)),
                                    child: CachedNetworkImage(
                                      imageUrl: data['message'],
                                      placeholder: (context, url) =>
                                          const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    DateFormat('hh:mm a').format(
                                      data['timestamp'].toDate(),
                                    ),
                                    style: GoogleFonts.ptSans(
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              )
                            : data['message'] == ''
                                ? Container(
                                    padding: EdgeInsets.all(20),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : data['type'] == 'Video'
                                    ? Column(
                                        crossAxisAlignment: alignment,
                                        children: [
                                          Container(
                                            decoration: const BoxDecoration(
                                              color: Color.fromARGB(
                                                  255, 92, 2, 105),
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(20),
                                              ),
                                            ),
                                            padding: const EdgeInsets.all(20),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                Image.asset(
                                                  'assets/videoup.png',
                                                  width: 150,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            data['filename'],
                                            style: GoogleFonts.ptSans(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              fontSize: 15,
                                            ),
                                          ),
                                          Text(
                                            DateFormat('hh:mm a').format(
                                              data['timestamp'].toDate(),
                                            ),
                                            style: GoogleFonts.ptSans(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      )
                                    : data['type'] == 'Audio'
                                        ? Column(
                                            crossAxisAlignment: alignment,
                                            children: [
                                              Container(
                                                decoration: const BoxDecoration(
                                                  color: Color.fromARGB(
                                                      255, 190, 190, 6),
                                                  borderRadius:
                                                      BorderRadius.all(
                                                    Radius.circular(20),
                                                  ),
                                                ),
                                                padding:
                                                    const EdgeInsets.all(20),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                  children: [
                                                    Image.asset(
                                                      'assets/audioup.png',
                                                      width: 150,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                data['filename'],
                                                style: GoogleFonts.ptSans(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              Text(
                                                DateFormat('hh:mm a').format(
                                                  data['timestamp'].toDate(),
                                                ),
                                                style: GoogleFonts.ptSans(
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ],
                                          )
                                        : Column(
                                            crossAxisAlignment: alignment,
                                            children: [
                                              Container(
                                                alignment: Alignment.center,
                                                decoration: const BoxDecoration(
                                                  color: Color.fromARGB(
                                                      255, 155, 24, 24),
                                                  borderRadius:
                                                      BorderRadius.all(
                                                    Radius.circular(20),
                                                  ),
                                                ),
                                                padding:
                                                    const EdgeInsets.all(20),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Image.asset(
                                                      'assets/docup.png',
                                                      width: 150,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                data['filename'],
                                                style: GoogleFonts.ptSans(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              Text(
                                                DateFormat('hh:mm a').format(
                                                  data['timestamp'].toDate(),
                                                ),
                                                style: GoogleFonts.ptSans(
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ],
                                          ),
                      ),
                    ),
        ],
      ),
    );
  }

  void _handleMediaTap(Map<String, dynamic> data) {
    data['type'] == 'Image'
        ? Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ImagePage(data: data),
            ),
          )
        : data['type'] == 'Video' || data['type'] == 'Audio'
            ? Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => VideoPlayerView(data: data),
                ),
              )
            : Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => PDFViewer(data: data)),
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/mic.json',
                  width: 200,
                ),
                const SizedBox(
                  height: 30,
                ),
                Text(
                  'Listning......',
                  style: GoogleFonts.ptSansCaption(
                    color: Colors.white,
                  ),
                )
              ],
            ),
          );
        });
  }

  void _showBottomSheetDetails(Map<String, dynamic> data, bool value,
      DocumentSnapshot documentSnapshot) {
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
            height: data['type'] == 'text' ? 500 : 550,
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(40),
                topRight: Radius.circular(40),
              ),
            ),
            child: Column(
              children: [
                Container(
                  height: 2,
                  width: 100,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Details',
                      style: GoogleFonts.ptSans(
                        color: Colors.white,
                        fontSize: 40,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                data['type'] != 'text'
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info,
                            size: 50,
                            color: Colors.teal.shade400,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'File Name',
                                style: GoogleFonts.ptSans(
                                  fontSize: 25,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                data['filename'],
                                style: GoogleFonts.ptSans(
                                  fontSize: 18,
                                  color: Colors.teal.shade400,
                                ),
                              )
                            ],
                          ),
                        ],
                      )
                    : Container(),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.calendar_month,
                      size: 50,
                      color: Colors.teal.shade400,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('MMMM-dd').format(
                            data['timestamp'].toDate(),
                          ),
                          style: GoogleFonts.ptSans(
                            fontSize: 25,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          DateFormat('EEEE yyyy').format(
                            data['timestamp'].toDate(),
                          ),
                          style: GoogleFonts.ptSans(
                            fontSize: 18,
                            color: Colors.teal.shade400,
                          ),
                        )
                      ],
                    ),
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(
                      data['type'] == 'Image'
                          ? Icons.image
                          : data['type'] == 'Video'
                              ? Icons.videocam
                              : data['type'] == 'Audio'
                                  ? Icons.audio_file
                                  : Icons.textsms,
                      size: 50,
                      color: Colors.teal.shade400,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Type',
                          style: GoogleFonts.ptSans(
                            fontSize: 25,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          data['type'],
                          style: GoogleFonts.ptSans(
                            fontSize: 18,
                            color: Colors.teal.shade400,
                          ),
                        )
                      ],
                    ),
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                data['type'] == 'text'
                    ? Container()
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.backup,
                            size: 50,
                            color: Colors.teal.shade400,
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.only(
                                left: 10,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'BackUp URL',
                                    style: GoogleFonts.ptSans(
                                      fontSize: 25,
                                      color: Colors.white,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {},
                                    child: Text(
                                      data['message'],
                                      style: GoogleFonts.ptSans(
                                        fontSize: 18,
                                        color: Colors.teal.shade400,
                                      ),
                                      softWrap: true,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                const SizedBox(
                  height: 20,
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 5,
                    right: 5,
                    bottom: 10,
                  ),
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                data['type'] == 'text'
                    ? data['senderId'] == _auth.currentUser!.uid
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: () async {
                                      try {
                                        await FirebaseFirestore.instance
                                            .collection('chat_Rooms')
                                            .doc(ChatroomID)
                                            .collection('messages')
                                            .doc(documentSnapshot.id)
                                            .update({
                                          'message': 'Message Deleted',
                                          'type': null
                                        });
                                        Navigator.of(context).pop();
                                      } catch (e) {
                                        print(e);
                                      }
                                    },
                                    icon: Icon(
                                      Icons.delete,
                                      size: 40,
                                      color: Colors.teal.shade500,
                                    ),
                                  ),
                                  Text(
                                    "Delete?",
                                    style: GoogleFonts.ptSans(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  )
                                ],
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      showEditBox(documentSnapshot);
                                    },
                                    icon: Icon(
                                      Icons.edit,
                                      size: 40,
                                      color: Colors.teal.shade400,
                                    ),
                                  ),
                                  Text(
                                    "Edit?",
                                    style: GoogleFonts.ptSans(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  )
                                ],
                              )
                            ],
                          )
                        : Container()
                    : data['senderId'] == _auth.currentUser!.uid
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: () async {},
                                    icon: Icon(
                                      Icons.download,
                                      size: 40,
                                      color: Colors.teal.shade500,
                                    ),
                                  ),
                                  Text(
                                    "Save?",
                                    style: GoogleFonts.ptSans(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  )
                                ],
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('chat_Rooms')
                                          .doc(ChatroomID)
                                          .collection('messages')
                                          .doc(documentSnapshot.id)
                                          .update({
                                        'message': 'Message Deleted',
                                        'type': null
                                      });
                                      Navigator.of(context).pop();
                                    },
                                    icon: Icon(
                                      Icons.delete,
                                      size: 40,
                                      color: Colors.teal.shade500,
                                    ),
                                  ),
                                  Text(
                                    "Delete?",
                                    style: GoogleFonts.ptSans(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  )
                                ],
                              )
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: () {},
                                    icon: Icon(
                                      Icons.download,
                                      size: 40,
                                      color: Colors.teal.shade500,
                                    ),
                                  ),
                                  Text(
                                    "Save?",
                                    style: GoogleFonts.ptSans(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  )
                                ],
                              ),
                            ],
                          )
              ],
            ),
          );
        });
  }

  void showEditBox(DocumentSnapshot documentSnapshot) async {
    TextEditingController textEditingController = TextEditingController();
    (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey.shade900,
            title: Text(
              'Enter The New Message',
              style: GoogleFonts.ptSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            actions: <Widget>[
              TextFormField(
                controller: textEditingController,
                obscureText: false,
                style: GoogleFonts.ptSansCaption(
                  color: Colors.white,
                ),
                cursorColor: Colors.teal,
                decoration: InputDecoration(
                  hintText: ' Enter Message Here',
                  hintStyle: GoogleFonts.ptSansCaption(
                    color: Colors.grey.shade400,
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      if (textEditingController.text.isNotEmpty) {
                        Navigator.of(context).pop();
                        try {
                          await FirebaseFirestore.instance
                              .collection('chat_Rooms')
                              .doc(ChatroomID)
                              .collection('messages')
                              .doc(documentSnapshot.id)
                              .update({
                            'message': textEditingController.text,
                            'type': 'text',
                            'edit': true,
                          });
                        } catch (e) {
                          print(e);
                        }
                      }
                    },
                    child: Text(
                      'Done',
                      style: GoogleFonts.ptSans(
                        fontSize: 20,
                        color: Colors.teal.shade500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )) ??
        false;
  }
}
