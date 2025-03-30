// ignore_for_file: deprecated_member_use

import 'package:SwiftTalk/MODELS/Message.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoPlayerView extends StatefulWidget {
  final FileMessage fileMessage;
  const VideoPlayerView({super.key, required this.fileMessage});
  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  late VideoPlayerController _videoPlayerController;
  late ChewieController _chewieController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    super.initState();
    _videoPlayerController =
        VideoPlayerController.network(widget.fileMessage.message);
    _chewieController = ChewieController(
        looping: true,
        showControls: true,
        videoPlayerController: _videoPlayerController);
    _videoPlayerController.initialize().then((_) => setState(() =>
        _chewieController = ChewieController(
            allowedScreenSleep: false,
            videoPlayerController: _videoPlayerController,
            aspectRatio: _videoPlayerController.value.aspectRatio)));
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color.fromARGB(174, 66, 66, 66),
        appBar: AppBar(
            centerTitle: true,
            title: Text(widget.fileMessage.filename,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontFamily: 'PTSansCaption')),
            actions: [
              IconButton(
                  onPressed: () =>
                      _showBottomSheetDetails(widget.fileMessage, context),
                  icon: const Icon(Icons.info, color: Colors.white, size: 30))
            ],
            leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_outlined,
                    color: Colors.white),
                onPressed: () => Navigator.of(context).pop())),
        body: Center(
            child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: Chewie(controller: _chewieController))));
  }

  Widget _detailItem(IconData icon, String title, String value) =>
      Row(mainAxisAlignment: MainAxisAlignment.start, children: [
        Icon(icon, size: 50, color: Colors.teal.shade400),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 25, color: Colors.white, fontFamily: 'PTSans')),
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.teal.shade400,
                  fontFamily: 'PTSans',
                  overflow:
                      title == 'BackUp URL' ? TextOverflow.ellipsis : null))
        ])
      ]);

  void _showBottomSheetDetails(FileMessage fileMessage, BuildContext context) {
    final borderRadius = const BorderRadius.vertical(top: Radius.circular(40));
    _scaffoldKey.currentState!.showBottomSheet(
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        (context) => Container(
            padding: const EdgeInsets.all(20),
            height: 550,
            decoration: BoxDecoration(
                color: Colors.grey.shade900, borderRadius: borderRadius),
            child: Column(children: [
              Container(height: 2, width: 100, color: Colors.white),
              const SizedBox(height: 20),
              const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Details',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontFamily: 'PTSans'))),
              const SizedBox(height: 20),
              _detailItem(Icons.info, 'File Name', fileMessage.filename),
              const SizedBox(height: 20),
              _detailItem(
                  Icons.calendar_month,
                  DateFormat('MMMM-dd').format(fileMessage.timestamp.toDate()),
                  DateFormat('EEEE yyyy')
                      .format(fileMessage.timestamp.toDate())),
              const SizedBox(height: 20),
              _detailItem(Icons.picture_as_pdf, 'Type', fileMessage.type),
              const SizedBox(height: 20),
              Row(children: [
                Icon(Icons.backup, size: 50, color: Colors.teal.shade400),
                const SizedBox(width: 8),
                Flexible(
                    child: Container(
                        padding: const EdgeInsets.only(left: 10),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('BackUp URL',
                                  style: TextStyle(
                                      fontSize: 25,
                                      color: Colors.white,
                                      fontFamily: 'PTSans')),
                              GestureDetector(
                                  onTap: () {},
                                  child: Text(fileMessage.message,
                                      style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.teal.shade400,
                                          fontFamily: 'PTSans'),
                                      softWrap: true,
                                      overflow: TextOverflow.ellipsis))
                            ])))
              ]),
              const SizedBox(height: 20),
              Padding(
                  padding: const EdgeInsets.only(left: 5, right: 5, bottom: 10),
                  child: Container(
                      height: 2,
                      decoration: BoxDecoration(color: Colors.grey.shade700))),
              const SizedBox(height: 20),
              IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.download,
                      size: 40, color: Colors.teal.shade500)),
              const Text("Save?",
                  style: TextStyle(
                      color: Colors.white, fontSize: 15, fontFamily: 'PTSans'))
            ])));
  }
}
