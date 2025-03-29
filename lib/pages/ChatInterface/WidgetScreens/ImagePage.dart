import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  // Function to show details in a bottom sheet
  void _showDetailsBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.data['fileName'],
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow(
                      'Sender :', widget.data['senderName'] ?? 'Unknown'),
                  _buildDetailRow('Type', 'Image'),
                  _buildDetailRow(
                      "TimeStamp :",
                      DateFormat('yyyy-MM-dd HH:mm:ss')
                          .format(widget.data['timestamp'].toDate())),
                  const SizedBox(height: 20)
                ]));
      },
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  // Helper method to create detail rows
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
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
            widget.data['message'],
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
              onPressed: _showDetailsBottomSheet,
            ),
          ],
        ),
        body: GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.primaryDelta! > 5 || details.primaryDelta! < -5) {
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
