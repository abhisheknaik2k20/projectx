import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool value;
  final DocumentSnapshot document;
  const ChatBubble({
    super.key,
    required this.message,
    required this.document,
    this.value = false,
  });

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    return Padding(
      padding: const EdgeInsets.only(left: 5.0, right: 5.0),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            color: (data['senderId'] == FirebaseAuth.instance.currentUser!.uid)
                ? Colors.teal.shade300
                : Colors.grey.shade300),
        child: Column(
          crossAxisAlignment:
              data['senderId'] == FirebaseAuth.instance.currentUser!.uid
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
          children: [
            value
                ? RichText(
                    text: TextSpan(
                      children: [
                        data['type'] == null
                            ? TextSpan(
                                text: '',
                                style: GoogleFonts.ptSansCaption(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              )
                            : TextSpan(
                                text: 'edited : ',
                                style: GoogleFonts.ptSansCaption(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                        TextSpan(
                          text: message,
                          style: GoogleFonts.ptSansCaption(
                            fontSize: 12,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  )
                : RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: message,
                          style: GoogleFonts.ptSansCaption(
                            fontSize: 12,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
            Text(
              DateFormat('hh:mm a').format(data['timestamp'].toDate()),
              style: GoogleFonts.ptSans(
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
