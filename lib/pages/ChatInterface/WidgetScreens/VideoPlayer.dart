// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoPlayerView extends StatefulWidget {
  final Map<String, dynamic> data;
  const VideoPlayerView({super.key, required this.data});

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
        VideoPlayerController.network(widget.data['message']);
    _chewieController = ChewieController(
      looping: true,
      showControls: true,
      videoPlayerController: _videoPlayerController,
    );

    _videoPlayerController.initialize().then(
          (_) => setState(
            () => _chewieController = ChewieController(
              allowedScreenSleep: false,
              videoPlayerController: _videoPlayerController,
              aspectRatio: _videoPlayerController.value.aspectRatio,
            ),
          ),
        );
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color.fromARGB(174, 66, 66, 66),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.data['fileName'],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontFamily: 'PTSansCaption',
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _showBottomSheetDetails(widget.data, context);
            },
            icon: const Icon(
              Icons.info,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined,
              color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SizedBox(
          height: height * 0.75,
          child: Chewie(controller: _chewieController),
        ),
      ),
    );
  }

  void _showBottomSheetDetails(
      Map<String, dynamic> data, BuildContext context) {
    _scaffoldKey.currentState!.showBottomSheet(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
        ), (context) {
      return Container(
        padding: const EdgeInsets.all(
          20,
        ),
        height: 550,
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
                    fontFamily: 'PTSans',
                  ),
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
                        fontFamily: 'PTSans',
                      ),
                    ),
                    Text(
                      data['filename'],
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.teal.shade400,
                        fontFamily: 'PTSans',
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
                        fontFamily: 'PTSans',
                      ),
                    ),
                    Text(
                      DateFormat('EEEE yyyy').format(
                        data['timestamp'].toDate(),
                      ),
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.teal.shade400,
                        fontFamily: 'PTSans',
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
                  Icons.picture_as_pdf,
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
                        fontFamily: 'PTSans',
                      ),
                    ),
                    Text(
                      data['type'],
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.teal.shade400,
                        fontFamily: 'PTSans',
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
                            fontFamily: 'PTSans',
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: Text(
                            data['message'],
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.teal.shade400,
                              fontFamily: 'PTSans',
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
            Row(
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
                        fontFamily: 'PTSans',
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
}
