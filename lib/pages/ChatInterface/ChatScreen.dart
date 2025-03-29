import 'dart:io';
import 'package:SwiftTalk/pages/CallScreen/Call_Provider.dart';
import 'package:SwiftTalk/pages/CallScreen/Call_Screen.dart';
import 'package:SwiftTalk/pages/ChatInterface/WidgetScreens/ImagePage.dart';
import 'package:SwiftTalk/pages/ChatInterface/WidgetScreens/VideoPlayer.dart';
import 'package:SwiftTalk/pages/Profile.dart';
import 'package:SwiftTalk/pages/Web_RTX_CALL_SCREEN/Screen1.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:SwiftTalk/pages/ChatInterface/Chat_Service.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class WhatsAppChatAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String receiverUid;
  final String receiverName;
  final String chatroomID;

  const WhatsAppChatAppBar(
      {super.key,
      required this.receiverUid,
      required this.receiverName,
      required this.chatroomID});

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + 10);

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance;
    final db = FirebaseFirestore.instance;
    final currentUserId = auth.currentUser!.uid;
    final ids = [currentUserId, receiverUid]..sort();
    final chatRoomId = ids.join("_");
    void initiateCall() async {
      await db
          .collection('users')
          .doc(receiverUid)
          .collection('call_info')
          .doc(receiverUid)
          .set({
        'key': chatRoomId,
        'reciving_Call': true,
        'sending_Call': false,
        'caller_Name': auth.currentUser?.displayName
      });
      await db
          .collection('users')
          .doc(currentUserId)
          .collection('call_info')
          .doc(currentUserId)
          .set({
        'key': chatRoomId,
        'reciving_Call': false,
        'sending_Call': true
      });
      await db.collection('users').doc(receiverUid).update({'isCall': true});
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => MyHomePage()));
    }

    void viewProfile() => Navigator.push(context,
        MaterialPageRoute(builder: (_) => ProfilePage(UserUID: receiverUid)));
    return AppBar(
        backgroundColor: Colors.teal,
        leadingWidth: 30,
        leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop()),
        title: StreamBuilder<DocumentSnapshot>(
            stream: db.collection('users').doc(receiverUid).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Text(receiverName, overflow: TextOverflow.ellipsis);
              }

              final userData = snapshot.data!;
              final isOnline = userData['status'] == 'Online';

              return GestureDetector(
                  onTap: viewProfile,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    CircleAvatar(
                        backgroundImage: NetworkImage(userData['photoURL'] ??
                            'https://default-avatar-url.com/avatar.jpg'),
                        radius: 20),
                    SizedBox(width: 10),
                    Flexible(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                          Text(receiverName,
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis),
                          Text(userData['status'] ?? 'Offline',
                              style: TextStyle(
                                fontSize: 12,
                                color: isOnline ? Colors.blue : Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis)
                        ]))
                  ]));
            }),
        actions: [
          IconButton(
              icon: Icon(Icons.video_call, color: Colors.white),
              onPressed: initiateCall),
          IconButton(
              icon: Icon(Icons.call, color: Colors.white), onPressed: () {}),
          PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.white),
              onSelected: (choice) {
                if (choice == 'View Contact') viewProfile();
              },
              itemBuilder: (_) => [
                    PopupMenuItem(
                        value: 'View Contact', child: Text('View Contact')),
                    PopupMenuItem(value: 'Media', child: Text('Media')),
                    PopupMenuItem(value: 'Search', child: Text('Search'))
                  ])
        ]);
  }
}

class ChatPage extends StatelessWidget {
  final String receiverUid;
  final String receiverName;
  const ChatPage({
    super.key,
    required this.receiverUid,
    required this.receiverName,
  });
  @override
  Widget build(BuildContext context) {
    final callStatusProvider = context.watch<CallStatusProvider>();
    if (callStatusProvider.isCallActive) {
      return const CallScreen();
    }
    return Scaffold(
        appBar: WhatsAppChatAppBar(
            receiverUid: receiverUid,
            receiverName: receiverName,
            chatroomID: ([FirebaseAuth.instance.currentUser!.uid, receiverUid]
                  ..sort())
                .join("_")),
        body: ChatPageContent(
          receiverUid: receiverUid,
          receiverName: receiverName,
        ));
  }
}

class ChatPageContent extends StatefulWidget {
  final String receiverUid;
  final String receiverName;

  const ChatPageContent({
    super.key,
    required this.receiverUid,
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
      await _chatService.SendMessage(
          reciverId: widget.receiverUid, message: textmessage);
    }
  }

  Future getImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif']);
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
        );
      } else {
        print("Unsupported file type");
      }
    }
  }

  Future getVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['gif', 'mp4', 'mov', 'avi']);
    if (result != null) {
      File file = File(result.files.single.path!);
      if (result.files.single.extension?.toLowerCase() == 'mp4' ||
          result.files.single.extension?.toLowerCase() == 'mov' ||
          result.files.single.extension?.toLowerCase() == 'avi') {
        videoFile = file;
        S3UploadService().uploadAndSendVideo(
          videoFile: videoFile!,
          receiverUid: widget.receiverUid,
        );
      }
    }
  }

  Future getAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'opus', 'aac']);
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
        );
      }
    }
  }

  Future getDocs() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null) {
      File file = File(result.files.single.path!);
      print(result.files.single.name);
      if (result.files.single.extension?.toLowerCase() == 'pdf') {
        docFile = file;
        S3UploadService().uploadAndSendPDF(
          pdfFile: docFile!,
          receiverUid: widget.receiverUid,
        );
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
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          IconButton(
            onPressed: _showAttachmentOptions,
            icon: const Icon(Icons.add, color: Colors.grey, size: 28),
          ),
          Expanded(
              child: Container(
                  constraints: const BoxConstraints(maxHeight: 140),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5)),
                  child: isListning
                      ? Center(
                          child: Text('Listening...',
                              style: TextStyle(color: Colors.green[700])))
                      : TextField(
                          controller: _messageController,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                              hintText: 'Type a message',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 10)),
                          style: const TextStyle(color: Colors.black87)))),
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
                      child: Icon(isListning ? Icons.mic : Icons.send,
                          color: Colors.white, size: 22))))
        ]));
  }

  void _showAttachmentOptions() {
    showBottomSheet(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        context: context,
        builder: (context) => _buildAttachmentSheet());
  }

  Widget _buildAttachmentSheet() {
    return Container(
        padding: const EdgeInsets.only(top: 20, left: 4, right: 4),
        height: 325,
        decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        child: Column(children: [
          Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Container(
                  height: 4,
                  width: 50,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2)))),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _buildOptionTile(
                icon: Icons.image,
                label: 'Gallery',
                color: Colors.green,
                onTap: getImage),
            _buildOptionTile(
                icon: Icons.video_library,
                label: 'Video',
                color: Colors.purple,
                onTap: getVideo),
            _buildOptionTile(
                icon: Icons.audiotrack,
                label: 'Audio',
                color: Colors.orange,
                onTap: getAudio)
          ]),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _buildOptionTile(
                icon: Icons.file_present,
                label: 'Document',
                color: Colors.blue,
                onTap: getDocs),
            _buildOptionTile(
                icon: Icons.mic,
                label: 'Audio',
                color: Colors.pink,
                onTap: startListning)
          ])
        ]));
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
        onTap: () {
          Navigator.of(context).pop();
          onTap();
        },
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              radius: 40,
              child: Icon(icon, color: color, size: 40)),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20))
        ]));
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

class WhatsAppMessageList extends StatelessWidget {
  final String receiverUid, chatroomid;
  final ScrollController _scrollController;
  final FirebaseAuth _auth;
  final ChatService _chatService;
  final BuildContext context;
  const WhatsAppMessageList(
      {super.key,
      required this.receiverUid,
      required ScrollController scrollController,
      required FirebaseAuth auth,
      required ChatService chatService,
      required this.context,
      required this.chatroomid})
      : _scrollController = scrollController,
        _auth = auth,
        _chatService = chatService;

  @override
  Widget build(BuildContext context) => StreamBuilder(
      stream: _chatService.getMessages(receiverUid, _auth.currentUser!.uid),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                Icon(Icons.chat, size: 100, color: Colors.teal[300]),
                const SizedBox(height: 20),
                Text('No messages yet',
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold)),
                Text('Start a conversation',
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold))
              ]));
        }
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollController
            .jumpTo(_scrollController.position.maxScrollExtent));
        return ListView.builder(
            controller: _scrollController,
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) =>
                _buildMessageItem(snapshot.data!.docs[index]));
      });

  Widget _buildMessageItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    bool isCurrentUser = data['senderId'] == _auth.currentUser!.uid;
    String formattedTime =
        DateFormat('hh:mm a').format((data['timestamp'] as Timestamp).toDate());
    return GestureDetector(
        onTap: () => _handleMediaTap(data),
        onLongPress: () {
          HapticFeedback.heavyImpact();
          _showBottomSheetDetails(data, isCurrentUser, document);
        },
        child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            alignment:
                isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Column(
                crossAxisAlignment: isCurrentUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.5),
                      decoration: BoxDecoration(
                          color: isCurrentUser
                              ? Colors.green.shade100
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.grey.shade300,
                                blurRadius: 2,
                                offset: const Offset(1, 1))
                          ]),
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isCurrentUser)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(data['senderName'],
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade800,
                                        fontSize: 12)),
                              ),
                            _getMessageContent(data),
                            const SizedBox(height: 4),
                            Align(
                                alignment: Alignment.bottomRight,
                                child: Text(formattedTime,
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600)))
                          ]))
                ])));
  }

  Widget _getMessageContent(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'text':
        return Text(data['message'], style: const TextStyle(fontSize: 16));
      case 'Image':
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 175,
              height: 175,
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(10)),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                      imageUrl: data['message'],
                      placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(color: Colors.teal)),
                      errorWidget: (context, url, error) =>
                          const Center(child: Icon(Icons.error)),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity)))
        ]);
      case 'Video':
      case 'Audio':
      case 'PDF':
        final Map<String, List> mediaConfig = {
          'Video': [
            Icons.play_circle_fill,
            Colors.purple,
            'Video',
            Colors.purple.shade100
          ],
          'Audio': [
            Icons.audiotrack,
            Colors.orange,
            'Audio',
            Colors.yellow.shade100
          ],
          'PDF': [
            Icons.picture_as_pdf,
            Colors.red,
            'PDF Document',
            Colors.red.shade100
          ]
        };
        final config = mediaConfig[data['type']]!;
        return Container(
            decoration: BoxDecoration(
                color: config[3], borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.all(10),
            child: Row(children: [
              Icon(config[0], color: config[1], size: 50),
              const SizedBox(width: 10),
              Flexible(
                  child: Text(config[2],
                      style: TextStyle(
                          color: data['type'] == 'Video'
                              ? Colors.purple
                              : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 30),
                      overflow: TextOverflow.ellipsis))
            ]));
      default:
        return Text(data['message'] ?? 'Unsupported message type',
            style: const TextStyle(fontSize: 16));
    }
  }

  void _handleMediaTap(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'Image':
        Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => ImagePage(data: data)));
        break;
      case 'Video':
      case 'Audio':
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => VideoPlayerView(data: data)));
        break;
      case 'PDF':
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => SfPdfViewer.network(data['message'])));
        break;
    }
  }

  void _showBottomSheetDetails(Map<String, dynamic> data, bool isCurrentUser,
      DocumentSnapshot document) {
    showBottomSheet(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40), topRight: Radius.circular(40))),
        context: context,
        builder: (context) => Container(
            padding: const EdgeInsets.all(20),
            height: data['type'] == 'text' ? 500 : 550,
            decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40))),
            child: Column(children: [
              Container(
                  height: 2,
                  width: 100,
                  decoration: const BoxDecoration(color: Colors.white)),
              const SizedBox(height: 20),
              const Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                Text('Details',
                    style: TextStyle(color: Colors.white, fontSize: 40))
              ]),
              const SizedBox(height: 20),
              if (data['type'] != 'text')
                _infoRow(Icons.info, 'File Name', data['fileName']),
              const SizedBox(height: 20),
              _infoRow(
                  Icons.calendar_month,
                  DateFormat('MMMM-dd').format(data['timestamp'].toDate()),
                  DateFormat('EEEE yyyy').format(data['timestamp'].toDate())),
              const SizedBox(height: 20),
              _infoRow(_getTypeIcon(data['type']), 'Type',
                  data['type'] ?? 'Unknown'),
              const SizedBox(height: 20),
              if (data['type'] != 'text')
                _infoRow(Icons.backup, 'BackUp URL', data['message'], true),
              const SizedBox(height: 20),
              Padding(
                  padding: const EdgeInsets.only(left: 5, right: 5, bottom: 10),
                  child: Container(
                      height: 2,
                      decoration: BoxDecoration(color: Colors.grey.shade700))),
              const SizedBox(height: 20),
              _buildButtons(data, isCurrentUser, document)
            ])));
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'Image':
        return Icons.image;
      case 'Video':
        return Icons.videocam;
      case 'Audio':
        return Icons.audio_file;
      default:
        return Icons.textsms;
    }
  }

  Widget _infoRow(IconData icon, String title, String value,
          [bool isUrl = false]) =>
      Row(mainAxisAlignment: MainAxisAlignment.start, children: [
        Icon(icon, size: 50, color: Colors.teal.shade400),
        const SizedBox(width: 10),
        Flexible(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(fontSize: 25, color: Colors.white)),
          isUrl
              ? GestureDetector(
                  onTap: () {},
                  child: Text(value,
                      style:
                          TextStyle(fontSize: 18, color: Colors.teal.shade400),
                      softWrap: true,
                      overflow: TextOverflow.ellipsis))
              : Text(value,
                  style: TextStyle(fontSize: 18, color: Colors.teal.shade400))
        ]))
      ]);

  Widget _buildButtons(Map<String, dynamic> data, bool isCurrentUser,
      DocumentSnapshot document) {
    if (data['type'] == 'text' && isCurrentUser) {
      return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _actionButton(Icons.delete, "Delete?", () => _deleteMessage(document)),
        _actionButton(Icons.edit, "Edit?", () {
          Navigator.of(context).pop();
          showEditBox(document);
        })
      ]);
    } else if (data['type'] != 'text') {
      return isCurrentUser
          ? Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _actionButton(Icons.download, "Save?", () {}),
              _actionButton(
                  Icons.delete, "Delete?", () => _deleteMessage(document)),
            ])
          : Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _actionButton(Icons.download, "Save?", () {}),
            ]);
    }
    return Container();
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onPressed) =>
      Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(
            onPressed: onPressed,
            icon: Icon(icon, size: 40, color: Colors.teal.shade500)),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 15))
      ]);

  Future<void> _deleteMessage(DocumentSnapshot document) async {
    try {
      await FirebaseFirestore.instance
          .collection('chat_Rooms')
          .doc(chatroomid)
          .collection('messages')
          .doc(document.id)
          .update({'message': 'Message Deleted', 'type': null});
      Navigator.of(context).pop();
    } catch (e) {
      print(e);
    }
  }

  void showEditBox(DocumentSnapshot document) async {
    TextEditingController textController = TextEditingController();
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
                backgroundColor: Colors.grey.shade900,
                title: const Text('Enter The New Message',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                actions: <Widget>[
                  TextFormField(
                      controller: textController,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: Colors.teal,
                      decoration: InputDecoration(
                          hintText: ' Enter Message Here',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white)))),
                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    ElevatedButton(
                        onPressed: () async {
                          if (textController.text.isNotEmpty) {
                            Navigator.of(context).pop();
                            try {
                              await FirebaseFirestore.instance
                                  .collection('chat_Rooms')
                                  .doc(chatroomid)
                                  .collection('messages')
                                  .doc(document.id)
                                  .update({
                                'message': textController.text,
                                'type': 'text',
                                'edit': true
                              });
                            } catch (e) {
                              print(e);
                            }
                          }
                        },
                        child: Text('Done',
                            style: TextStyle(
                                fontSize: 20, color: Colors.teal.shade500)))
                  ])
                ]));
  }
}
