import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ImagePage extends StatefulWidget {
  final Map data;

  const ImagePage({super.key, required this.data});

  @override
  State<ImagePage> createState() => _ImagePageState();
}

class _ImagePageState extends State<ImagePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _animatePageDown() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    Future<bool> onWillPop() async {
      _animatePageDown();
      await Future.delayed(const Duration(milliseconds: 300));
      Navigator.of(context).pop();
      return false;
    }

    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 42, 41, 41),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          centerTitle: true,
          title: Text(
            widget.data['filename'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontFamily: 'PT Sans Caption',
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.info,
                color: Colors.white,
              ),
              onPressed: () {},
            ),
          ],
        ),
        body: GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.primaryDelta! > 5) {
              Navigator.of(context).pop();
            }
            if (details.primaryDelta! < -5) {
              Navigator.of(context).pop();
            }
          },
          child: Center(
            child: PhotoViewGallery.builder(
              itemCount: 1,
              builder: (context, index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider:
                      CachedNetworkImageProvider(widget.data['message']),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                );
              },
              backgroundDecoration: const BoxDecoration(
                color: Colors.black,
              ),
              scrollPhysics: const BouncingScrollPhysics(),
              pageController: PageController(),
              onPageChanged: (index) {},
            ),
          ),
        ),
      ),
    );
  }
}
