import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoPlayerView extends StatefulWidget {
  final Map<String, dynamic> data;
  const VideoPlayerView({Key? key, required this.data}) : super(key: key);

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  late VideoPlayerController _videoPlayerController;
  late ChewieController _chewieController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _auth = FirebaseAuth.instance;

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
    TextStyle style = GoogleFonts.ptSans(
      color: Colors.white,
      fontSize: 20,
    );
    var height = MediaQuery.of(context).size.height;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color.fromARGB(174, 66, 66, 66),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.data['filename'],
          style: GoogleFonts.ptSansCaption(
            color: Colors.white,
            fontSize: 30,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Details',
                  style: GoogleFonts.ptSans(
                    color: Colors.white,
                    fontSize: 40,
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
                    Text(
                      'File Name',
                      style: GoogleFonts.ptSans(
                        fontSize: 25,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      data['filename'],
                      style: GoogleFonts.ptSans(
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
                      style: GoogleFonts.ptSans(
                        fontSize: 25,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE yyyy').format(
                        data['timestamp'].toDate(),
                      ),
                      style: GoogleFonts.ptSans(
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
                    Text(
                      'Type',
                      style: GoogleFonts.ptSans(
                        fontSize: 25,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      data['type'],
                      style: GoogleFonts.ptSans(
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
                        Text(
                          'BackUp URL',
                          style: GoogleFonts.ptSans(
                            fontSize: 25,
                            color: Colors.white,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: Text(
                            data['message'],
                            style: GoogleFonts.ptSans(
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
                    Text(
                      "Save?",
                      style: GoogleFonts.ptSans(
                        color: Colors.white,
                        fontSize: 15,
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
