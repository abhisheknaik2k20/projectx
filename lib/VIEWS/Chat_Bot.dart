import 'package:SwiftTalk/MODELS/Message.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';
import 'package:SwiftTalk/API_KEYS.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatGPTScreen extends StatefulWidget {
  final ValueNotifier<double> valueNotifier;
  const ChatGPTScreen({required this.valueNotifier, super.key});

  @override
  State<ChatGPTScreen> createState() => _ChatGPTScreenState();
}

class _ChatGPTScreenState extends State<ChatGPTScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatBotMessage> _messages = [];
  late final GenerativeModel _model;
  bool _isLoading = false;
  File? _imageFile;
  bool _showImagePreview = false;
  FilePickerResult? result;
  late AnimationController _fadeController;
  late AnimationController _dotAnimationController;
  late List<Animation<double>> _dotAnimations;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
        model: 'gemini-1.5-pro',
        apiKey: GEMINI_API,
        generationConfig:
            GenerationConfig(maxOutputTokens: 2048, temperature: 0.7));
    _messages.add(ChatBotMessage(
        text:
            "Hello! I'm your AI assistant powered by Google Gemini. How can I help you today?",
        isUser: false));
    _requestPermissions(); // Request permissions on startup
    _fadeController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);

    _dotAnimationController = AnimationController(
        duration: const Duration(milliseconds: 1800), vsync: this)
      ..repeat();
    _dotAnimations = List.generate(3, (index) {
      final beginTime = index * 0.2;
      return TweenSequence<double>([
        TweenSequenceItem(
            tween: Tween<double>(begin: 0.5, end: 1.0)
                .chain(CurveTween(curve: Curves.easeInOut)),
            weight: 50),
        TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 0.5)
                .chain(CurveTween(curve: Curves.easeInOut)),
            weight: 50),
      ]).animate(CurvedAnimation(
          parent: _dotAnimationController,
          curve: Interval(beginTime, beginTime + 0.6, curve: Curves.linear)));
    });
  }

  Future<void> _requestPermissions() async {
    // Create temp directory regardless of permissions
    try {
      final tempDir = await getTemporaryDirectory();
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }
    } catch (e) {
      print("Error creating temp directory: $e");
    }

    // We don't need to request permissions here as we'll do it when picking images
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _dotAnimationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<bool> _requestImagePermissions() async {
    // For Android 13+ (API level 33+), we need to request photos permission
    // For older versions, we use storage permission
    if (Platform.isAndroid) {
      // Check Android SDK version at runtime
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 33) {
        // For Android 13+
        final photos = await Permission.photos.request();
        return photos.isGranted;
      } else {
        // For Android 12 and below
        final storage = await Permission.storage.request();
        return storage.isGranted;
      }
    } else {
      // For iOS or other platforms
      final photos = await Permission.photos.request();
      return photos.isGranted;
    }
  }

  Future<void> _pickImage() async {
    try {
      final hasPermission = await _requestImagePermissions();

      if (hasPermission) {
        result = await FilePicker.platform.pickFiles(
            type: FileType.image,
            allowMultiple: false,
            allowCompression: false);

        if (result != null &&
            result!.files.isNotEmpty &&
            result!.files.single.path != null) {
          setState(() {
            _imageFile = File(result!.files.single.path!);
            _showImagePreview = true;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Permission is required to pick images")));

        // Guide the user to app settings
        await openAppSettings();
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error picking image: $e")));
    }
  }

  void _scrollToBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut);
        }
      });

  Future<void> _sendMessage() async {
    final String messageText = _messageController.text.trim();
    if (messageText.isEmpty && _imageFile == null) return;
    _messageController.clear();
    setState(() {
      if (messageText.isNotEmpty) {
        _messages.add(ChatBotMessage(text: messageText, isUser: true));
      }
      if (_imageFile != null) {
        _messages.add(ChatBotMessage(
            text: "Image uploaded", isUser: true, imageFile: _imageFile));
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
        try {
          final imageBytes = await _imageFile!.readAsBytes();
          parts.add(DataPart('image/jpeg', imageBytes));
        } catch (e) {
          print("Error reading image: $e");
          setState(() => _messages.add(ChatBotMessage(
              text: "Error processing image: $e", isUser: false)));
          _isLoading = false;
          _imageFile = null;
          return;
        }
      }
      final response = await chatSession.sendMessage(Content.multi(parts));
      setState(() {
        _messages.add(ChatBotMessage(
            text: response.text ?? "I'm not sure how to respond.",
            isUser: false));
        _isLoading = false;
        _imageFile = null;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatBotMessage(
            text: "Sorry, there was an error processing your request: $e",
            isUser: false));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
                  if (index < _messages.length) {
                    _fadeController.forward(from: 0.0);
                    return _buildMessageItem(_messages[index]);
                  } else {
                    return _buildLoadingIndicator();
                  }
                })),
        if (_imageFile != null && _showImagePreview) _buildImagePreview(),
        _buildMessageInput()
      ]));

  Widget _buildImagePreview() => Container(
      padding: const EdgeInsets.all(8),
      child: Row(children: [
        Image.file(_imageFile!, width: 100, height: 100, fit: BoxFit.cover),
        const SizedBox(width: 10),
        Text('Image ready to send', style: TextStyle(color: Colors.grey[700])),
        const Spacer(),
        IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => setState(() => _imageFile = null))
      ]));

  Widget _buildMessageItem(ChatBotMessage message) {
    final slideAnimation = Tween<Offset>(
            begin: Offset(message.isUser ? 0.1 : -0.1, 0.0), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    return Align(
        alignment:
            message.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: SlideTransition(
            position: slideAnimation,
            child: FadeTransition(
                opacity: fadeAnimation,
                child: Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                            Container(
                                width: double.infinity,
                                constraints: BoxConstraints(maxHeight: 200),
                                child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(message.imageFile!,
                                        fit: BoxFit.cover, errorBuilder:
                                            (context, error, stackTrace) {
                                      return Container(
                                          height: 100,
                                          color: Colors.grey.shade300,
                                          child: Center(
                                              child: Icon(Icons.broken_image,
                                                  size: 40,
                                                  color: Colors.grey)));
                                    }))),
                          MarkdownWidget(
                              data: message.text,
                              shrinkWrap: true,
                              config: MarkdownConfig(configs: [
                                CodeConfig(
                                    style: TextStyle(
                                        backgroundColor: Colors.grey.shade100,
                                        fontFamily: 'monospace'))
                              ]))
                        ])))));
  }

  Widget _buildLoadingIndicator() => Align(
      alignment: Alignment.centerLeft,
      child: FadeTransition(
        opacity: _fadeController..forward(),
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
            ])),
      ));

  Widget _buildDot(int index) => AnimatedBuilder(
      animation: _dotAnimations[index],
      builder: (context, child) {
        return Transform.scale(
            scale: _dotAnimations[index].value,
            child: Opacity(
                opacity: _dotAnimations[index].value,
                child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(4)))));
      });

  Widget _buildMessageInput() => ValueListenableBuilder(
      valueListenable: widget.valueNotifier,
      builder: (context, navbarheight, child) {
        return AnimatedContainer(
            height: 72 * navbarheight,
            duration: Duration(milliseconds: 100),
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
                      onPressed: _sendMessage))
            ]));
      });
}
