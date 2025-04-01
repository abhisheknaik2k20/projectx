import 'dart:io';
import 'package:SwiftTalk/CONTROLLER/Call_Provider.dart';
import 'package:SwiftTalk/VIEWS/Call_Screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ProfilePage extends StatefulWidget {
  final String UserUID;
  final bool isMe;
  const ProfilePage({required this.isMe, super.key, required this.UserUID});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with AutomaticKeepAliveClientMixin {
  Map<String, dynamic>? data;
  String? formattedDateTime;
  List<File> mediaFiles = [];
  bool isLoadingMedia = true;
  final _auth = FirebaseAuth.instance;
  String? chatroomId;

  @override
  bool get wantKeepAlive => true;

  void getDetails() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.UserUID)
          .get();

      setState(() {
        data = snapshot.data() as Map<String, dynamic>?;
        if (data?['createdAt'] is Timestamp) {
          Timestamp timestamp = data?['createdAt'] as Timestamp;
          formattedDateTime =
              DateFormat('dd MMM yyyy').format(timestamp.toDate());
        } else if (data?['createdAt'] is String) {
          formattedDateTime = data?['createdAt'];
        } else {
          formattedDateTime = 'Not available';
        }
      });

      if (!widget.isMe) {
        // Create a sorted chatroom ID to ensure consistency
        List<String> ids = [widget.UserUID, _auth.currentUser?.uid ?? ""];
        ids.sort(); // Sort to ensure consistent chatroom ID regardless of who initiated
        chatroomId = ids.join("_");

        loadSharedMedia(chatroomId!);
      }
    } catch (e) {
      print('Error fetching user details: $e');
      setState(() {
        formattedDateTime = 'Error loading date';
      });
    }
  }

  Future<void> loadSharedMedia(String chatRoomID) async {
    setState(() {
      isLoadingMedia = true;
    });

    try {
      List<File> files = [];
      // Update to match your actual media type folder names
      List<String> mediaTypes = ['Image', 'Video', 'PDF'];

      for (String type in mediaTypes) {
        Directory? appDir;
        if (Platform.isAndroid) {
          try {
            appDir = await getExternalStorageDirectory();
            if (appDir != null) {
              String mediaPath = "${appDir.path}/$chatRoomID/$type";
              print("Checking for media in: $mediaPath");

              Directory mediaDir = Directory(mediaPath);
              if (await mediaDir.exists()) {
                print("Directory exists: $mediaPath");
                List<FileSystemEntity> entities =
                    await mediaDir.list().toList();
                print("Found ${entities.length} items in $mediaPath");

                for (var entity in entities) {
                  if (entity is File) {
                    print("Added file: ${entity.path}");
                    files.add(entity);
                  }
                }
              } else {
                print("Directory does not exist: $mediaPath");
              }
            }
          } catch (e) {
            print("Failed to get media files from Android: $e");
          }
        } else {
          // iOS path handling
          try {
            appDir = await getApplicationDocumentsDirectory();
            String mediaPath = "${appDir.path}/$chatRoomID/$type";
            print("Checking for media in: $mediaPath");

            Directory mediaDir = Directory(mediaPath);
            if (await mediaDir.exists()) {
              print("Directory exists: $mediaPath");
              List<FileSystemEntity> entities = await mediaDir.list().toList();
              print("Found ${entities.length} items in $mediaPath");

              for (var entity in entities) {
                if (entity is File) {
                  print("Added file: ${entity.path}");
                  files.add(entity);
                }
              }
            } else {
              print("Directory does not exist: $mediaPath");
            }
          } catch (e) {
            print("Failed to get media files from iOS: $e");
          }
        }
      }

      // If we didn't find any files, check if any files exist in parent directory
      if (files.isEmpty) {
        try {
          Directory? appDir = Platform.isAndroid
              ? await getExternalStorageDirectory()
              : await getApplicationDocumentsDirectory();

          if (appDir != null) {
            print("Checking parent directory: ${appDir.path}/$chatRoomID");
            Directory parentDir = Directory("${appDir.path}/$chatRoomID");

            if (await parentDir.exists()) {
              await _recursiveFindMedia(parentDir, files);
            }
          }
        } catch (e) {
          print("Failed to search parent directory: $e");
        }
      }

      setState(() {
        mediaFiles = files;
        isLoadingMedia = false;
      });

      print("Found total ${mediaFiles.length} media files");
    } catch (e) {
      print("Error loading shared media: $e");
      setState(() {
        isLoadingMedia = false;
      });
    }
  }

  // Helper method to recursively find media files
  Future<void> _recursiveFindMedia(Directory dir, List<File> files,
      {int depth = 0}) async {
    if (depth > 3) return; // Limit recursion depth to avoid infinite loops

    try {
      List<FileSystemEntity> entities = await dir.list().toList();
      print("Searching in ${dir.path}, found ${entities.length} items");

      for (var entity in entities) {
        if (entity is File) {
          String ext = path.extension(entity.path).toLowerCase();
          if ([
            '.jpg',
            '.jpeg',
            '.png',
            '.gif',
            '.mp4',
            '.mov',
            '.avi',
            '.pdf',
            '.doc',
            '.docx'
          ].contains(ext)) {
            print("Found media file: ${entity.path}");
            files.add(entity);
          }
        } else if (entity is Directory) {
          await _recursiveFindMedia(entity, files, depth: depth + 1);
        }
      }
    } catch (e) {
      print("Error in recursive search: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    getDetails();
  }

  Widget _buildMediaThumbnail(File file) {
    final fileExt = path.extension(file.path).toLowerCase();
    final isImage =
        ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(fileExt);
    final isVideo = ['.mp4', '.mov', '.avi', '.mkv'].contains(fileExt);
    final isPdf = ['.pdf'].contains(fileExt);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isImage)
            Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print("Error loading image: $error");
                return const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.grey,
                  ),
                );
              },
            )
          else if (isVideo)
            Container(
              color: Colors.black,
              child: const Center(
                child: Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            )
          else if (isPdf)
            Container(
              color: Colors.red.shade50,
              child: const Center(
                child: Icon(
                  Icons.picture_as_pdf,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            )
          else
            Container(
              color: Colors.blue.shade50,
              child: const Center(
                child: Icon(
                  Icons.insert_drive_file,
                  color: Colors.blue,
                  size: 40,
                ),
              ),
            ),

          // File name overlay at the bottom for non-image files
          if (!isImage)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                color: Colors.black.withOpacity(0.5),
                child: Text(
                  path.basename(file.path),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final callStatusProvider = context.watch<CallStatusProvider>();
    if (callStatusProvider.isCallActive) {
      return const CallScreen();
    }
    if (data == null) {
      return Scaffold(
          backgroundColor: Colors.white,
          body: const Center(
              child: CircularProgressIndicator(color: Color(0xFF075E54))));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF075E54),
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: data?['photoURL'] != null
                  ? Image.network(
                      data!['photoURL'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFF128C7E),
                          child: const Icon(
                            Icons.account_circle,
                            size: 100,
                            color: Colors.white,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: const Color(0xFF128C7E),
                      child: const Icon(
                        Icons.account_circle,
                        size: 100,
                        color: Colors.white,
                      ),
                    ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              if (widget.isMe)
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () {},
                ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),

          // Profile Info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    data!['name'] ?? 'No Name',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Phone number
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 20, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(
                        data?['phone'] != "null"
                            ? '+91 ${data?['phone']}'
                            : 'Not available',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Email
                  Row(
                    children: [
                      const Icon(Icons.email, size: 20, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          data?['email'] ?? 'No email',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Divider
          const SliverToBoxAdapter(
            child: Divider(thickness: 1, height: 0),
          ),

          // About section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "About",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data?['bio'] ?? "Hey there, I'm using SwiftTalk!",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Divider
          const SliverToBoxAdapter(
            child: Divider(thickness: 8, height: 8, color: Color(0xFFECE5DD)),
          ),

          // Joined Date
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 20, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text(
                    "Joined $formattedDateTime",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Media, Links, Docs section for non-self profiles
          if (!widget.isMe) ...[
            const SliverToBoxAdapter(
              child: Divider(thickness: 8, height: 8, color: Color(0xFFECE5DD)),
            ),

            // Media section header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Media, Links, and Docs",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    if (mediaFiles.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          // Show all media in full screen gallery
                          _showFullMediaGallery(context, mediaFiles);
                        },
                        child: const Row(
                          children: [
                            Text(
                              "SEE ALL",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF075E54),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward,
                              size: 16,
                              color: Color(0xFF075E54),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Debug information when loading
            if (isLoadingMedia)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: CircularProgressIndicator(
                            color: Color(0xFF075E54),
                          ),
                        ),
                      ),
                      Text("Looking for media in chatroom: $chatroomId"),
                    ],
                  ),
                ),
              )
            // Display when no media found
            else if (mediaFiles.isEmpty)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        "No media shared",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    // Retry button
                    ElevatedButton.icon(
                      onPressed: () {
                        if (chatroomId != null) {
                          loadSharedMedia(chatroomId!);
                        }
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text("Retry"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF075E54),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
            // Media grid
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    childAspectRatio: 1.0,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= mediaFiles.length) return null;
                      final file = mediaFiles[index];

                      return GestureDetector(
                        onTap: () {
                          _openMediaFile(context, file);
                        },
                        child: _buildMediaThumbnail(file),
                      );
                    },
                    childCount: mediaFiles.length,
                  ),
                ),
              ),
          ],

          // Additional options when viewing own profile
          if (widget.isMe) ...[
            const SliverToBoxAdapter(
              child: Divider(thickness: 8, height: 8, color: Color(0xFFECE5DD)),
            ),

            // Settings option
            SliverToBoxAdapter(
              child: ListTile(
                leading: const Icon(Icons.settings, color: Colors.grey),
                title: const Text(
                  "Settings",
                  style: TextStyle(fontSize: 16),
                ),
                onTap: () {
                  // Navigate to settings
                },
              ),
            ),

            // Notifications option
            SliverToBoxAdapter(
              child: ListTile(
                leading: const Icon(Icons.notifications, color: Colors.grey),
                title: const Text(
                  "Notifications",
                  style: TextStyle(fontSize: 16),
                ),
                onTap: () {
                  // Navigate to notifications settings
                },
              ),
            ),

            // Help option
            SliverToBoxAdapter(
              child: ListTile(
                leading: const Icon(Icons.help_outline, color: Colors.grey),
                title: const Text(
                  "Help",
                  style: TextStyle(fontSize: 16),
                ),
                onTap: () {
                  // Navigate to help
                },
              ),
            ),
          ],

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 50),
          ),
        ],
      ),
    );
  }

  // Function to open media file
  void _openMediaFile(BuildContext context, File file) async {
    try {
      // Get the file path and create a URI
      final filePath = file.path;
      final uri = Uri.file(filePath);

      // Use OpenFile package to open the file with the default system viewer
      // First, make sure to add the open_file package to your pubspec.yaml:
      // open_file: ^latest_version

      // Import the package in your file:
      // import 'package:open_file/open_file.dart';

      final result = await OpenFile.open(filePath);

      // Handle result if needed
      if (result.type != ResultType.done) {
        // If opening with system viewer fails, show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to open ${path.basename(filePath)}: ${result.message}'),
            action: SnackBarAction(
              label: 'Share',
              onPressed: () {
                // Implement sharing functionality here
                // You can use Share.shareFiles([filePath]) from share package
              },
            ),
          ),
        );
      }
    } catch (e) {
      // Handle exceptions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening ${path.basename(file.path)}: $e'),
          action: SnackBarAction(
            label: 'Share',
            onPressed: () {
              // Implement sharing functionality here
            },
          ),
        ),
      );
    }
  }

  // Function to show full media gallery
  void _showFullMediaGallery(BuildContext context, List<File> files) {
    // Sort files by creation date
    files.sort((a, b) {
      final aStats = a.statSync();
      final bStats = b.statSync();
      return bStats.modified.compareTo(aStats.modified); // Newest first
    });

    // Group files by date (using date string as key)
    final Map<String, List<File>> groupedFiles = {};
    for (final file in files) {
      final fileDate = file.statSync().modified;
      final dateString = DateFormat('MMMM d, yyyy').format(fileDate);

      if (!groupedFiles.containsKey(dateString)) {
        groupedFiles[dateString] = [];
      }
      groupedFiles[dateString]!.add(file);
    }

    // Get sorted date keys (newest first)
    final dateGroups = groupedFiles.keys.toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.teal,
            title: const Text('Shared Media',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: ListView.builder(
            itemCount: dateGroups.length,
            itemBuilder: (context, groupIndex) {
              final date = dateGroups[groupIndex];
              final dateFiles = groupedFiles[date]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      date,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  // Grid of files for this date
                  GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: dateFiles.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _openMediaFile(context, dateFiles[index]),
                        child: _buildMediaThumbnail(dateFiles[index]),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
