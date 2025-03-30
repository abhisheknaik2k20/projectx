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
        vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showDetailsBottomSheet() {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.data['fileName'],
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const SizedBox(height: 20),
                  _buildDetailRow(
                      'Sender :', widget.data['senderName'] ?? 'Unknown'),
                  _buildDetailRow('Type', 'Image'),
                  _buildDetailRow(
                      "TimeStamp :",
                      DateFormat('yyyy-MM-dd HH:mm:ss')
                          .format(widget.data['timestamp'].toDate())),
                  const SizedBox(height: 20)
                ])));
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
          Text(value,
              style: const TextStyle(fontSize: 16, color: Colors.black54))
        ]));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          _animationController.reverse();
          await Future.delayed(const Duration(milliseconds: 300));
          return true;
        },
        child: Scaffold(
            backgroundColor: const Color.fromARGB(255, 42, 41, 41),
            appBar: AppBar(
                leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context)),
                centerTitle: true,
                title: Text(widget.data['fileName'],
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontFamily: 'PT Sans Caption')),
                actions: [
                  IconButton(
                      icon: const Icon(Icons.info, color: Colors.white),
                      onPressed: _showDetailsBottomSheet)
                ]),
            body: GestureDetector(
                onVerticalDragUpdate: (details) {
                  if (details.primaryDelta! > 5 || details.primaryDelta! < -5) {
                    Navigator.pop(context);
                  }
                },
                child: PhotoViewGallery.builder(
                    itemCount: 1,
                    builder: (_, __) => PhotoViewGalleryPageOptions(
                        imageProvider:
                            CachedNetworkImageProvider(widget.data['message']),
                        minScale: PhotoViewComputedScale.contained,
                        maxScale: PhotoViewComputedScale.covered * 2),
                    backgroundDecoration:
                        const BoxDecoration(color: Colors.black),
                    scrollPhysics: const BouncingScrollPhysics()))));
  }
}
