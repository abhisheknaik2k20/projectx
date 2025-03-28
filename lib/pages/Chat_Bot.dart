import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:projectx/API_KEYS.dart';

class ChatGPTScreen extends StatefulWidget {
  const ChatGPTScreen({super.key});

  @override
  State<ChatGPTScreen> createState() => _ChatGPTScreenState();
}

class _ChatGPTScreenState extends State<ChatGPTScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  File? _imageFile;

  // Replace with your actual Google AI API key
  late final GenerativeModel _model;
  final ImagePicker _picker = ImagePicker();
  bool _showImagePreview = false;

  @override
  void initState() {
    super.initState();

    _model = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: GEMINI_API,
      generationConfig: GenerationConfig(
        maxOutputTokens: 2048,
        temperature: 0.7,
      ),
    );

    _addInitialMessage();
  }

  void _addInitialMessage() {
    _messages.add(
      ChatMessage(
        text:
            "Hello! I'm your AI assistant powered by Google Gemini. How can I help you today?",
        isUser: false,
      ),
    );
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

  Future<void> _sendMessage() async {
    final String messageText = _messageController.text.trim();

    // Check if there's no text and no image
    if (messageText.isEmpty && _imageFile == null) return;

    // Clear input and show loading
    _messageController.clear();
    setState(() {
      // Add user's text message
      if (messageText.isNotEmpty) {
        _messages.add(ChatMessage(text: messageText, isUser: true));
      }

      // Add image if present
      if (_imageFile != null) {
        _messages.add(ChatMessage(
          text: "Image uploaded",
          isUser: true,
          imageFile: _imageFile,
        ));
      }

      _isLoading = true;
    });

    // Scroll to bottom
    _scrollToBottom();

    try {
      final chatSession = _model.startChat();

      List<Part> parts = [];

      if (messageText.isNotEmpty) {
        parts.add(TextPart(messageText));
      }

      if (_imageFile != null) {
        final imageBytes = await _imageFile!.readAsBytes();
        parts.add(DataPart('image/jpeg', imageBytes));
      }
      final response = await chatSession.sendMessage(Content.multi(parts));

      setState(() {
        _messages.add(
          ChatMessage(
            text: response.text ?? "I'm not sure how to respond.",
            isUser: false,
          ),
        );
        _isLoading = false;

        _imageFile = null;
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: "Sorry, there was an error processing your request: $e",
            isUser: false,
          ),
        );
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.smart_toy_outlined, color: Colors.teal),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CHATBOT',
                  style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  'Online',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[200],
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  return _buildMessageItem(_messages[index]);
                } else {
                  // Loading indicator
                  return _buildLoadingIndicator();
                }
              },
            ),
          ),
          if (_imageFile != null && _showImagePreview) _buildImagePreview(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Image.file(
            _imageFile!,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
          const SizedBox(width: 10),
          Text('Image ready to send',
              style: TextStyle(color: Colors.grey[700])),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () {
              setState(() {
                _imageFile = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.teal.shade100 : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
                message.isUser ? const Radius.circular(16) : Radius.zero,
            bottomRight:
                message.isUser ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Display image if present
            if (message.imageFile != null)
              Image.file(
                message.imageFile!,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            // Display text
            MarkdownWidget(
              data: message.text,
              shrinkWrap: true,
              config: MarkdownConfig(
                configs: [
                  CodeConfig(
                    style: TextStyle(
                      backgroundColor: Colors.grey.shade100,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fade().slideX(
            begin: message.isUser ? 0.1 : -0.1,
            duration: 300.ms,
          ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        child: const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
        ),
      ).animate().fade().scale(),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.image, color: Colors.teal),
            onPressed: _pickImage,
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send, color: Colors.teal),
                    onPressed: () {
                      setState(() => _showImagePreview = false);
                      _sendMessage();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final File? imageFile;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.imageFile,
  });
}
