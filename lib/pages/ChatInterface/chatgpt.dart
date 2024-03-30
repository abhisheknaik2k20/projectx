import 'dart:convert';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:projectx/pages/ChatInterface/api+key.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatGPTScreen extends StatefulWidget {
  const ChatGPTScreen({super.key});

  @override
  _ChatGPTScreenState createState() => _ChatGPTScreenState();
}

class _ChatGPTScreenState extends State<ChatGPTScreen> {
  bool isLoading = false;
  final List<Message> _messages = [];
  final TextEditingController _textEditingController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  ConnectivityResult _connectivityResult = ConnectivityResult.none;

  @override
  void initState() {
    super.initState();
    checkConnectivity();
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _connectivityResult = result;
      });
    });
  }

  Future<void> checkConnectivity() async {
    ConnectivityResult result = await Connectivity().checkConnectivity();
    setState(() {
      _connectivityResult = result;
    });

    if (result == ConnectivityResult.none) {
      _showErrorSnackbar("You're Offline", context);
    }
  }

  void onSendMessage() async {
    Message message = Message(text: _textEditingController.text, isMe: true);

    _textEditingController.clear();

    setState(() {
      isLoading = true;
      _messages.insert(0, message);
    });

    String response = await sendMessageToChatGpt(message.text);

    Message chatGpt = Message(text: response, isMe: false);

    setState(() {
      isLoading = false;
      _messages.insert(0, chatGpt);
    });
  }

  Future<String> sendMessageToChatGpt(String message) async {
    Uri uri = Uri.parse("https://api.openai.com/v1/chat/completions");

    Map<String, dynamic> body = {
      "model": "gpt-3.5-turbo",
      "messages": [
        {"role": "user", "content": message}
      ],
      "max_tokens": 500,
    };

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${APIKey.apiKey}",
      },
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> parsedResponse = json.decode(response.body);
      String reply = parsedResponse['choices'][0]['message']['content'];
      return reply;
    } else if (response.statusCode == 429) {
      _showErrorSnackbar(
          'Rate limit exceeded. Please wait and try again later.', context);
      return "Rate limit exceeded. Please wait and try again later.";
    } else {
      print("Error: ${response.statusCode}");
      _showErrorSnackbar(response.statusCode.toString(), context);
      return "Error processing message";
    }
  }

  Widget _buildMessage(Message message, bool isLast) {
    return Container(
      child: Column(
        crossAxisAlignment:
            message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
              width: 20,
              child: message.isMe
                  ? const Icon(Icons.account_box_rounded, color: Colors.white)
                  : Image.asset(
                      'assets/chatgpt.png',
                      color: Colors.white,
                    )),
          Text(
            message.isMe ? 'You' : 'GPT',
            style: GoogleFonts.ptSans(
                fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: message.isMe
                ? BoxDecoration(
                    border: Border.all(color: Colors.grey.shade600),
                    borderRadius: const BorderRadius.all(Radius.circular(20)))
                : null,
            child: isLast && isLoading
                ? SizedBox(
                    width: 100, child: Lottie.asset('assets/loading3.json'))
                : (message.isMe
                    ? Text(
                        message.text,
                        style: GoogleFonts.ptSans(color: Colors.white),
                      )
                    : Text(message.text,
                        style: GoogleFonts.quantico(color: Colors.white))),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    List<Widget> widgets = [];

    for (int i = _messages.length - 1; i >= 0; i--) {
      bool isLast = i == 0;

      widgets.add(_buildMessage(_messages[i], isLast));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: widgets),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: const Color.fromARGB(255, 72, 72, 72),
          border: Border.all(color: const Color.fromARGB(255, 72, 72, 72))),
      child: Column(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: Colors.grey.shade600))),
            child: SizedBox(
              height: 75,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                          color: Color.fromARGB(255, 0, 166, 126),
                          borderRadius: BorderRadius.all(Radius.circular(20))),
                      width: 50,
                      child: Image.asset(
                        'assets/chatgpt.png',
                        color: Colors.white,
                      )),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        if (await canLaunch('https://chat.openai.com/')) {
                          await launch('https://chat.openai.com/');
                        } else {
                          _showErrorSnackbar("Something went wrong", context);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          "ChatGPT 3.5",
                          style: GoogleFonts.openSans(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              controller: _scrollController,
              children: [
                _buildMessageList(),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: const Color.fromARGB(220, 34, 29, 29),
                border: Border.all(
                  color: const Color.fromARGB(220, 34, 29, 29),
                )),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(right: 10),
                    child: TextField(
                      cursorColor: Colors.white,
                      style: GoogleFonts.ptSans(color: Colors.white),
                      controller: _textEditingController,
                      decoration: InputDecoration(
                        hintStyle: GoogleFonts.ptSans(color: Colors.white),
                        contentPadding: const EdgeInsets.all(10.0),
                        hintText: 'Message ChatGPT...',
                        border: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.transparent)),
                        focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white)),
                        enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.transparent)),
                      ),
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: Ink(
                    decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 0, 166, 126),
                        borderRadius: const BorderRadius.all(Radius.circular(5)),
                        border: Border.all(color: Colors.white, width: 2)),
                    child: InkWell(
                      borderRadius: const BorderRadius.all(Radius.circular(5)),
                      onTap: () {
                        if (_connectivityResult == ConnectivityResult.none) {
                          _showErrorSnackbar("You're Offline", context);
                        } else {
                          if (_textEditingController.text.isNotEmpty) {
                            onSendMessage();
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        child: const Icon(
                          Icons.send,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(height: 85, child: Lottie.asset('assets/error2.json')),
            const SizedBox(width: 8.0),
            Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ],
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
}

class Message {
  final String text;
  final bool isMe;

  Message({required this.text, required this.isMe});
}
