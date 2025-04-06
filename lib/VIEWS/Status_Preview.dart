import 'package:SwiftTalk/CONTROLLER/User_Repository.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:SwiftTalk/MODELS/User.dart';

class StatusPreviewScreen extends StatefulWidget {
  final UserModel user;
  const StatusPreviewScreen({super.key, required this.user});

  @override
  State<StatusPreviewScreen> createState() => _StatusPreviewScreenState();
}

class _StatusPreviewScreenState extends State<StatusPreviewScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  int _currentIndex = 0;
  final UserRepository _userRepository = UserRepository();
  late List<String> _statusImages;
  bool _isDeleting = false; // Flag to track deletion in progress

  @override
  void initState() {
    super.initState();
    // Create a local copy of the status images to manage deletions
    _statusImages = List<String>.from(widget.user.statusImages ?? []);

    _pageController = PageController();
    _animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 5));

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reset();

        if (_currentIndex + 1 < _statusImages.length) {
          setState(() {
            _currentIndex += 1;
            _pageController.animateToPage(_currentIndex,
                duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
          });
          _animationController.forward();
        } else {
          // Only pop if we're not in the middle of a deletion
          if (!_isDeleting) {
            Navigator.of(context).pop();
          }
        }
      }
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Function to handle image deletion
  Future<void> _deleteCurrentImage() async {
    if (_statusImages.isEmpty ||
        _currentIndex < 0 ||
        _currentIndex >= _statusImages.length) {
      return;
    }

    // Set deleting flag
    setState(() {
      _isDeleting = true;
    });

    // Pause animation while deleting
    _animationController.stop();

    final String imageToDelete = _statusImages[_currentIndex];
    final int currentIndexBackup = _currentIndex;

    // Delete from repository
    final success =
        await _userRepository.deleteUserStatusImageByUrl(imageToDelete);

    if (success) {
      // Handle UI updates only if the widget is still mounted
      if (mounted) {
        setState(() {
          // Remove the image from our local list
          _statusImages.removeAt(currentIndexBackup);

          // Handle the case where we've deleted all images
          if (_statusImages.isEmpty) {
            // Reset flag before navigating
            _isDeleting = false;
            Navigator.of(context).pop();
            return;
          }

          // Adjust current index if needed
          if (currentIndexBackup >= _statusImages.length) {
            _currentIndex = _statusImages.length - 1;
          } else {
            // Stay at the same position (which now shows the next image)
            _currentIndex = currentIndexBackup;
            if (_currentIndex >= _statusImages.length) {
              _currentIndex = _statusImages.length - 1;
            }
          }

          // Reset page controller to current index
          _pageController.jumpToPage(_currentIndex);

          // Restart animation
          _animationController.reset();
          _animationController.forward();

          // Reset deleting flag
          _isDeleting = false;
        });
      }
    } else {
      if (mounted) {
        // Show error if deletion failed
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete status image')));

        // Reset deleting flag
        setState(() {
          _isDeleting = false;
        });

        // Resume animation
        _animationController.forward();
      }
    }
  }

  // Handle tap zones in a way that doesn't conflict with buttons
  void _handleTapZone(TapDownDetails details) {
    // Don't process taps if we're deleting
    if (_isDeleting) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final tapX = details.globalPosition.dx;

    // Define a smaller tap zone for left/right navigation
    // This leaves more space in the center and around the edges for UI buttons
    if (tapX < screenWidth / 4) {
      // Left 25% of screen
      if (_currentIndex > 0) {
        setState(() {
          _currentIndex -= 1;
          _pageController.animateToPage(_currentIndex,
              duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
          _animationController.reset();
          _animationController.forward();
        });
      }
    } else if (tapX > 3 * screenWidth / 4) {
      // Right 25% of screen
      if (_currentIndex + 1 < _statusImages.length) {
        setState(() {
          _currentIndex += 1;
          _pageController.animateToPage(
            _currentIndex,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          _animationController.reset();
          _animationController.forward();
        });
      } else if (!_isDeleting) {
        Navigator.of(context).pop();
      }
    } else {
      // Center tap - pause/play animation
      if (_animationController.isAnimating) {
        _animationController.stop();
      } else {
        _animationController.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main gesture detector for the content area
          GestureDetector(
            onTapDown: _handleTapZone,
            child: PageView.builder(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _statusImages.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  final String imageUrl = _statusImages[index];
                  return Stack(alignment: Alignment.center, children: [
                    if (imageUrl.startsWith('http'))
                      CachedNetworkImage(
                          imageUrl: imageUrl,
                          imageBuilder: (context, imageProvider) => Container(
                              decoration: BoxDecoration(
                                  image: DecorationImage(
                                      image: imageProvider,
                                      fit: BoxFit.cover))),
                          placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.teal)),
                          errorWidget: (context, url, error) => const Center(
                              child: Icon(Icons.error, color: Colors.red)))
                    else
                      Image.asset(imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          frameBuilder: (BuildContext context, Widget child,
                              int? frame, bool wasSynchronouslyLoaded) {
                            if (wasSynchronouslyLoaded) return child;
                            return AnimatedOpacity(
                                opacity: frame == null ? 0 : 1,
                                duration: const Duration(milliseconds: 300),
                                child: child);
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                                  child: Icon(Icons.error, color: Colors.red)))
                  ]);
                }),
          ),

          // Status bar indicators
          SafeArea(
              child: SizedBox(
                  height: 2,
                  child: Row(
                      children: List.generate(
                          _statusImages.length,
                          (index) => Expanded(
                              child: Container(
                                  margin: EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                    color: index < _currentIndex
                                        ? Colors.white
                                        : index == _currentIndex
                                            ? Colors.grey.withOpacity(0.5)
                                            : Colors.white.withOpacity(0.2),
                                  ),
                                  child: index == _currentIndex
                                      ? AnimatedBuilder(
                                          animation: _animationController,
                                          builder: (context, child) {
                                            return FractionallySizedBox(
                                                widthFactor:
                                                    _animationController.value,
                                                alignment: Alignment.centerLeft,
                                                child: Container(
                                                    color: Colors.white));
                                          })
                                      : null)))))),
          SafeArea(
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(children: [
                    CircleAvatar(
                        backgroundImage: widget.user.photoURL.startsWith('http')
                            ? NetworkImage(widget.user.photoURL)
                                as ImageProvider
                            : AssetImage(widget.user.photoURL),
                        radius: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.user.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {}, // Empty to just block propagation
                      child: IconButton(
                        icon: Icon(
                            _isDeleting ? Icons.hourglass_top : Icons.delete,
                            color: Colors.white),
                        onPressed: _isDeleting
                            ? null
                            : () {
                                print("DELETE TAPPED");
                                _deleteCurrentImage();
                              },
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {},
                      child: IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    )
                  ]))),

          // Loading indicator during deletion
          if (_isDeleting)
            Center(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      'Deleting...',
                      style: TextStyle(color: Colors.white),
                    )
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }
}
