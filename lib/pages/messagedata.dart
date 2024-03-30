import 'package:flutter/material.dart';

@immutable
class MessageData {
  const MessageData({
    required this.sendname,
    required this.sendmessage,
  });
  final String sendname;
  final String sendmessage;
}
