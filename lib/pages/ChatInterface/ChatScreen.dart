import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:projectx/pages/ChatInterface/AppBar.dart';
import 'package:projectx/pages/ChatInterface/Widget_list.dart';
import 'package:projectx/pages/ChatInterface/chat_Service.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
            _messageController.text = (result.recognizedWords);
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
        S3UploadService().uploadAndSendImage(
            imageFile: imageFile!,
            receiverUid: widget.receiverUid,
            receiverEmail: widget.receiverEmail);
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
        S3UploadService().uploadAndSendVideo(
            videoFile: videoFile!,
            receiverUid: widget.receiverUid,
            receiverEmail: widget.receiverEmail);
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
        S3UploadService().uploadAndSendAudio(
            audioFile: audioFile!,
            receiverUid: widget.receiverUid,
            receiverEmail: widget.receiverEmail);
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
        S3UploadService().uploadAndSendPDF(
            pdfFile: docFile!,
            receiverUid: widget.receiverUid,
            receiverEmail: widget.receiverEmail);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
          child: WhatsAppMessageList(
              receiverUid: widget.receiverUid,
              scrollController: _scrollController,
              auth: _auth,
              chatService: _chatService,
              context: context,
              chatroomid: ChatroomID)),
      _buildMessageInput()
    ]);
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      color: Colors.grey.shade900,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            onPressed: () {
              showBottomSheet(
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20))),
                  context: context,
                  builder: (context) {
                    return Container(
                        padding:
                            const EdgeInsets.only(top: 20, left: 4, right: 4),
                        height: 325,
                        decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20))),
                        child: Column(children: [
                          // Bottom sheet content (same as previous implementation)
                          Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Container(
                                  height: 4,
                                  width: 50,
                                  decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(2)))),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                InkWell(
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      getImage();
                                    },
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          CircleAvatar(
                                            backgroundColor:
                                                Colors.green.shade100,
                                            radius: 40,
                                            child: Icon(Icons.image,
                                                color: Colors.green, size: 40),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text('Gallery',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20))
                                        ])),
                                InkWell(
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      getVideo();
                                    },
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          CircleAvatar(
                                            backgroundColor:
                                                Colors.purple.shade100,
                                            radius: 40,
                                            child: Icon(Icons.video_library,
                                                color: Colors.purple, size: 40),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text('Video',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20))
                                        ])),
                                InkWell(
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      getAudio();
                                    },
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          CircleAvatar(
                                            backgroundColor:
                                                Colors.orange.shade100,
                                            radius: 40,
                                            child: Icon(Icons.audiotrack,
                                                color: Colors.orange, size: 40),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text('Audio',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20))
                                        ])),
                              ]),
                          const SizedBox(height: 20),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                InkWell(
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      getDocs();
                                    },
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          CircleAvatar(
                                            backgroundColor:
                                                Colors.blue.shade100,
                                            radius: 40,
                                            child: Icon(Icons.file_present,
                                                color: Colors.blue, size: 40),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text('Document',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20))
                                        ])),
                                InkWell(
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      startListning();
                                    },
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          CircleAvatar(
                                            backgroundColor:
                                                Colors.pink.shade100,
                                            radius: 40,
                                            child: Icon(Icons.mic,
                                                color: Colors.pink, size: 40),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text('Audio',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20))
                                        ])),
                              ])
                        ]));
                  });
            },
            icon: const Icon(Icons.add, color: Colors.grey, size: 28),
          ),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 140),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
              ),
              child: isListning
                  ? Center(
                      child: Text(
                        'Listening...',
                        style: TextStyle(color: Colors.green[700]),
                      ),
                    )
                  : TextField(
                      controller: _messageController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 10),
                      ),
                      style: const TextStyle(color: Colors.black87),
                    ),
            ),
          ),

          // Send/Mic button
          Container(
            margin: const EdgeInsets.only(left: 8),
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
              onLongPressEnd: (_) {
                setState(() {
                  isListning = false;
                  stopListning();
                });
                Navigator.of(context).pop();
              },
              child: CircleAvatar(
                backgroundColor: Colors.teal,
                radius: 22,
                child: Icon(
                  isListning ? Icons.mic : Icons.send,
                  color: Colors.white,
                  size: 22,
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
                topLeft: Radius.circular(40), topRight: Radius.circular(40))),
        context: context,
        builder: (context) {
          return Container(
              padding: const EdgeInsets.all(20),
              height: 300,
              decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40))),
              child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mic, size: 60, color: Colors.white),
                    SizedBox(height: 30),
                    Text('Listning......',
                        style: TextStyle(color: Colors.white))
                  ]));
        });
  }
}
