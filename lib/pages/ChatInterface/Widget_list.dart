import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:SwiftTalk/pages/ChatInterface/WidgetScreens/ImagePage.dart';
import 'package:SwiftTalk/pages/ChatInterface/WidgetScreens/VideoPlayer.dart';
import 'package:SwiftTalk/pages/ChatInterface/Chat_Service.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class WhatsAppMessageList extends StatelessWidget {
  final String receiverUid;
  final ScrollController _scrollController;
  final FirebaseAuth _auth;
  final ChatService _chatService;
  final BuildContext context;
  final String chatroomid;

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

  Widget _buildMessageList() {
    return StreamBuilder(
      stream: _chatService.getMessages(
        receiverUid,
        _auth.currentUser!.uid,
      ),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat,
                  size: 100,
                  color: Colors.teal[300],
                ),
                const SizedBox(height: 20),
                Text(
                  'No messages yet',
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  'Start a conversation',
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }

        // Scroll to bottom after rendering
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        });

        return ListView.builder(
          controller: _scrollController,
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            return _buildMessageItem(snapshot.data!.docs[index]);
          },
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    bool isCurrentUser = data['senderId'] == _auth.currentUser!.uid;
    Color bubbleColor = isCurrentUser ? Colors.green.shade100 : Colors.white;
    String formattedTime = DateFormat('hh:mm a').format(
      (data['timestamp'] as Timestamp).toDate(),
    );
    Widget messageContent;
    switch (data['type']) {
      case 'text':
        messageContent = Text(
          data['message'],
          style: const TextStyle(fontSize: 16),
        );
        break;
      case 'Image':
        messageContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: data['message'],
                placeholder: (context, url) =>
                    const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const Icon(Icons.error),
                width: 250,
                height: 250,
                fit: BoxFit.cover,
              ),
            ),
          ],
        );
        break;
      case 'Video':
        messageContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  const Icon(
                    Icons.play_circle_fill,
                    color: Colors.purple,
                    size: 50,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Video',
                      style: const TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                          fontSize: 30),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        break;
      case 'Audio':
        messageContent = Container(
          decoration: BoxDecoration(
            color: Colors.yellow.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              const Icon(
                Icons.audiotrack,
                color: Colors.orange,
                size: 50,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Audio',
                  style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 30),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
        break;
      case 'PDF':
        messageContent = Container(
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              const Icon(
                Icons.picture_as_pdf,
                color: Colors.red,
                size: 50,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'PDF Document',
                  style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 30),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
        break;
      default:
        messageContent = Text(
          data['message'] ?? 'Unsupported message type',
          style: const TextStyle(fontSize: 16),
        );
    }

    return GestureDetector(
      onTap: () => _handleMediaTap(data),
      onLongPress: () async {
        HapticFeedback.heavyImpact();
        if (_auth.currentUser!.uid == data['senderId']) {
          _showBottomSheetDetails(data, true, document);
        } else {
          _showBottomSheetDetails(data, false, document);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 2,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isCurrentUser)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        data['senderName'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  messageContent,
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
            : data['type'] == "PDF"
                ? Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          SfPdfViewer.network(data['message']),
                    ),
                  )
                : Container();
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
                const Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Details',
                      style: TextStyle(
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
                              const Text(
                                'File Name',
                                style: TextStyle(
                                  fontSize: 25,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                data['filename'],
                                style: TextStyle(
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
                          style: const TextStyle(
                            fontSize: 25,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          DateFormat('EEEE yyyy').format(
                            data['timestamp'].toDate(),
                          ),
                          style: TextStyle(
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
                        const Text(
                          'Type',
                          style: TextStyle(
                            fontSize: 25,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          data['type'],
                          style: TextStyle(
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
                                  const Text(
                                    'BackUp URL',
                                    style: TextStyle(
                                      fontSize: 25,
                                      color: Colors.white,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {},
                                    child: Text(
                                      data['message'],
                                      style: TextStyle(
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
                                            .doc(chatroomid)
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
                                  const Text(
                                    "Delete?",
                                    style: TextStyle(
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
                                  const Text(
                                    "Edit?",
                                    style: TextStyle(
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
                                  const Text(
                                    "Save?",
                                    style: TextStyle(
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
                                          .doc(chatroomid)
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
                                  const Text(
                                    "Delete?",
                                    style: TextStyle(
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
                                  const Text(
                                    "Save?",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.normal,
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
            title: const Text(
              'Enter The New Message',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            actions: <Widget>[
              TextFormField(
                controller: textEditingController,
                obscureText: false,
                style: const TextStyle(
                  color: Colors.white,
                ),
                cursorColor: Colors.teal,
                decoration: InputDecoration(
                  hintText: ' Enter Message Here',
                  hintStyle: TextStyle(
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
                              .doc(chatroomid)
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
                      style: TextStyle(
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

  @override
  Widget build(BuildContext context) {
    return _buildMessageList();
  }
}
