import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:projectx/pages/messagedata.dart';

class ChatScreen extends StatelessWidget {
  static Route route(MessageData data) => MaterialPageRoute(
        builder: (context) => ChatScreen(
          messageData: data,
        ),
      );
  const ChatScreen({
    Key? key,
    required this.messageData,
  }) : super(key: key);
  final MessageData messageData;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        shadowColor: Colors.amber.shade900,
        leading: Padding(
          padding: const EdgeInsets.only(bottom: 15, left: 8, top: 5),
          child: IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.arrow_back_ios_new, size: 35)),
        ),
        title: Center(
            child: Text(
          messageData.sendname,
          style: GoogleFonts.ubuntu(color: Colors.black, fontSize: 25),
        )),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.call, size: 35))
        ],
      ),
      backgroundColor: Colors.amber.shade600,
    );
  }
}
