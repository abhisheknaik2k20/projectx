import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:SwiftTalk/API_KEYS.dart';

class ChatGPTScreen extends StatefulWidget {
  final ValueNotifier<double> valueNotifier;
  const ChatGPTScreen({required this.valueNotifier, super.key});

  @override
  State<ChatGPTScreen> createState() => _ChatGPTScreenState();
}

class _ChatGPTScreenState extends State<ChatGPTScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final ImagePicker _picker = ImagePicker();

  late final GenerativeModel _model;
  bool _isLoading = false;
  File? _imageFile;
  bool _showImagePreview = false;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
        model: 'gemini-1.5-pro',
        apiKey: GEMINI_API,
        generationConfig:
            GenerationConfig(maxOutputTokens: 2048, temperature: 0.7));
    _messages.add(ChatMessage(
        text:
            "Hello! I'm your AI assistant powered by Google Gemini. How can I help you today?",
        isUser: false));
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _showImagePreview = true;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _sendMessage() async {
    final String messageText = _messageController.text.trim();
    if (messageText.isEmpty && _imageFile == null) return;
    _messageController.clear();
    setState(() {
      if (messageText.isNotEmpty) {
        _messages.add(ChatMessage(text: messageText, isUser: true));
      }
      if (_imageFile != null) {
        _messages.add(ChatMessage(
          text: "Image uploaded",
          isUser: true,
          imageFile: _imageFile,
        ));
      }
      _isLoading = true;
      _showImagePreview = false;
    });
    _scrollToBottom();
    try {
      final chatSession = _model.startChat();
      List<Part> parts = [];

      if (messageText.isNotEmpty) parts.add(TextPart(messageText));
      if (_imageFile != null) {
        final imageBytes = await _imageFile!.readAsBytes();
        parts.add(DataPart('image/jpeg', imageBytes));
      }
      final response = await chatSession.sendMessage(Content.multi(parts));
      setState(() {
        _messages.add(ChatMessage(
          text: response.text ?? "I'm not sure how to respond.",
          isUser: false,
        ));
        _isLoading = false;
        _imageFile = null;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
            text: "Sorry, there was an error processing your request: $e",
            isUser: false));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Row(children: [
              const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.smart_toy_outlined, color: Colors.teal)),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('CHATBOT',
                    style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
                Text('Online',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[200],
                        fontWeight: FontWeight.bold))
              ])
            ]),
            actions: [
              IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () {})
            ]),
        body: Column(children: [
          Expanded(
              child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    return index < _messages.length
                        ? _buildMessageItem(_messages[index])
                        : _buildLoadingIndicator();
                  })),
          if (_imageFile != null && _showImagePreview) _buildImagePreview(),
          _buildMessageInput()
        ]));
  }

  Widget _buildImagePreview() {
    return Container(
        padding: const EdgeInsets.all(8),
        child: Row(children: [
          Image.file(_imageFile!, width: 100, height: 100, fit: BoxFit.cover),
          const SizedBox(width: 10),
          Text('Image ready to send',
              style: TextStyle(color: Colors.grey[700])),
          const Spacer(),
          IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => setState(() => _imageFile = null))
        ]));
  }

  Widget _buildMessageItem(ChatMessage message) {
    return Align(
        alignment:
            message.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                padding: const EdgeInsets.all(12),
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75),
                decoration: BoxDecoration(
                    color: message.isUser
                        ? Colors.teal.shade100
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: message.isUser
                            ? const Radius.circular(16)
                            : Radius.zero,
                        bottomRight: message.isUser
                            ? Radius.zero
                            : const Radius.circular(16))),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.imageFile != null)
                        Image.file(message.imageFile!,
                            width: double.infinity, fit: BoxFit.cover),
                      MarkdownWidget(
                          data: message.text,
                          shrinkWrap: true,
                          config: MarkdownConfig(configs: [
                            CodeConfig(
                                style: TextStyle(
                                    backgroundColor: Colors.grey.shade100,
                                    fontFamily: 'monospace'))
                          ]))
                    ]))
            .animate()
            .fade()
            .slideX(begin: message.isUser ? 0.1 : -0.1, duration: 300.ms));
  }

  Widget _buildLoadingIndicator() {
    return Align(
        alignment: Alignment.centerLeft,
        child: Animate(
            effects: [FadeEffect(duration: 400.ms)],
            child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  _buildDot(0),
                  const SizedBox(width: 4),
                  _buildDot(1),
                  const SizedBox(width: 4),
                  _buildDot(2)
                ]))));
  }

  Widget _buildDot(int index) => Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
              color: Colors.teal, borderRadius: BorderRadius.circular(4)))
      .animate(
          onPlay: (controller) => controller.repeat(),
          effects: [
            ScaleEffect(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1.0, 1.0),
                duration: 600.ms,
                curve: Curves.easeInOut),
            FadeEffect(
                begin: 0.5, end: 1.0, duration: 600.ms, curve: Curves.easeInOut)
          ],
          delay: Duration(milliseconds: index * 200));

  Widget _buildMessageInput() {
    return ValueListenableBuilder(
        valueListenable: widget.valueNotifier,
        builder: (context, navbarheight, child) {
          return AnimatedContainer(
              height: 75 * navbarheight,
              duration: Duration(microseconds: 100),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              color: Colors.grey[300],
              child: Row(children: [
                Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5)),
                    child: IconButton(
                        icon: const Icon(Icons.image, color: Colors.teal),
                        onPressed: _pickImage)),
                SizedBox(width: 5),
                Expanded(
                    child: Container(
                        decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(5)),
                        child: TextField(
                            controller: _messageController,
                            maxLines: null,
                            decoration: InputDecoration(
                              hintText: 'Type your message...',
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                            )))),
                SizedBox(width: 5),
                Container(
                    decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(5)),
                    child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage)),
              ]));
        });
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final File? imageFile;

  ChatMessage({required this.text, required this.isUser, this.imageFile});
}
