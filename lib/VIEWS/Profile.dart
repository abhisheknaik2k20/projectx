import 'dart:io';
import 'package:SwiftTalk/CONTROLLER/Call_Provider.dart';
import 'package:SwiftTalk/CONTROLLER/Chat_Service.dart';
import 'package:SwiftTalk/CONTROLLER/User_Repository.dart';
import 'package:SwiftTalk/MODELS/User.dart';
import 'package:SwiftTalk/VIEWS/Call_Screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  String? formattedDateTime;
  UserModel? user;
  List<File> mediaFiles = [];
  bool isLoadingMedia = true;
  final _auth = FirebaseAuth.instance;
  String? chatroomId;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  bool get wantKeepAlive => true;

  void getDetails() async {
    try {
      UserModel? local = await UserRepository().getUserById(widget.UserUID);
      setState(() {
        user = local;
        if (user?.status is Timestamp) {
          Timestamp timestamp = user?.createdAt as Timestamp;
          formattedDateTime =
              DateFormat('dd MMM yyyy hh:mm a').format(timestamp.toDate());
        } else if (user?.status is String) {
          formattedDateTime = user?.status;
        } else {
          formattedDateTime = 'Not available';
        }
      });

      // Start animations after data is loaded
      _animationController.forward();

      if (!widget.isMe) {
        List<String> ids = [widget.UserUID, _auth.currentUser?.uid ?? ""];
        ids.sort();
        chatroomId = ids.join("_");
        loadSharedMedia(chatroomId!);
      }
    } catch (e) {
      print('Error fetching user details: $e');
      setState(() => formattedDateTime = 'Error loading date');
    }
  }

  Future<void> loadSharedMedia(String chatRoomID) async {
    setState(() => isLoadingMedia = true);
    try {
      List<File> files = [];
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

  Future<void> _recursiveFindMedia(Directory dir, List<File> files,
      {int depth = 0}) async {
    if (depth > 3) return;
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

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );

    getDetails();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildHeroImage(String? imageUrl) {
    return Hero(
        tag: 'profile-${widget.UserUID}',
        child: CachedNetworkImage(imageUrl: imageUrl ?? '', fit: BoxFit.cover));
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
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(fit: StackFit.expand, children: [
          if (isImage)
            Image.file(file, fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
              print("Error loading image: $error");
              return const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey));
            })
          else if (isVideo)
            Container(
                color: Colors.black,
                child: const Center(
                    child: Icon(Icons.play_circle_outline,
                        color: Colors.white, size: 40)))
          else if (isPdf)
            Container(
                color: Colors.red.shade50,
                child: const Center(
                    child: Icon(Icons.picture_as_pdf,
                        color: Colors.red, size: 40)))
          else
            Container(
                color: Colors.blue.shade50,
                child: const Center(
                    child: Icon(Icons.insert_drive_file,
                        color: Colors.blue, size: 40))),
          if (!isImage)
            Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    color: Colors.black.withOpacity(0.6),
                    child: Text(path.basename(file.path),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)))
        ]));
  }

  Widget _buildSectionHeader(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF128C7E),
              letterSpacing: 0.2,
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildAnimatedSection(Widget child, {double delay = 0.0}) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final callStatusProvider = context.watch<CallStatusProvider>();

    if (callStatusProvider.isCallActive) {
      return const CallScreen();
    }

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
            child: CircularProgressIndicator(color: Color(0xFF075E54))),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String? imageUrl;
        String userName = "Loading...";
        String userEmail = user?.email ?? '';
        String userDescription = "Hey there, I'm using SwiftTalk!";

        if (snapshot.hasData && snapshot.data?.exists == true) {
          imageUrl = snapshot.data!.get('photoURL') as String?;
          userName = snapshot.data!.get('name') as String? ?? 'No Name';
          userEmail = snapshot.data!.get('email') as String? ?? 'No email';
        } else {
          userName = user?.name ?? 'No Name';
          userEmail = user?.email ?? 'No email';
        }

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 230,
                backgroundColor: Colors.transparent,
                pinned: true,
                stretch: true,
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: [StretchMode.zoomBackground],
                  background: _buildHeroImage(imageUrl),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  if (widget.isMe)
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () async {
                        // Show a cool animation when edit is tapped
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Select profile image"),
                            backgroundColor: Colors.grey[900],
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );

                        final ImagePicker picker = ImagePicker();
                        try {
                          final XFile? pickedImage = await picker.pickImage(
                              source: ImageSource.gallery, imageQuality: 85);

                          if (pickedImage != null) {
                            File imageFile = File(pickedImage.path);
                            String? imageURL = await S3UploadService()
                                .uploadFileToS3(
                                    reciverId: widget.UserUID,
                                    file: imageFile,
                                    fileType: "Image",
                                    sendNotification: false);

                            UserRepository().updateUserProfile(
                                _auth.currentUser!.uid, imageURL ?? '');
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Error picking image: $e'),
                            backgroundColor: Colors.red,
                          ));
                        }
                      },
                    ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) {
                      // Handle menu item selection
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Selected: $value')));
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'share',
                        child: Text('Share profile'),
                      ),
                      if (widget.isMe)
                        const PopupMenuItem(
                          value: 'logout',
                          child: Text('Log out'),
                        ),
                      if (!widget.isMe)
                        const PopupMenuItem(
                          value: 'block',
                          child: Text('Block user'),
                        ),
                      if (!widget.isMe)
                        const PopupMenuItem(
                          value: 'report',
                          child: Text('Report'),
                        ),
                    ],
                  ),
                ],
              ),

              // Profile Info
              SliverToBoxAdapter(
                child: _buildAnimatedSection(
                  Card(
                    margin: const EdgeInsets.all(8.0),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name with verification badge
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  userName,
                                  style: const TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                              if (widget.isMe)
                                const Icon(
                                  Icons.verified,
                                  color: Color(0xFF25D366),
                                  size: 20,
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Email with animation on tap
                          GestureDetector(
                            onTap: () {
                              // Add a ripple effect
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Email: $userEmail')));
                            },
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.email,
                                  size: 22,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    userEmail,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              user?.status == "Online"
                                  ? Icon(
                                      Icons.circle,
                                      color: Colors.green,
                                    )
                                  : Icon(
                                      Icons.circle,
                                      color: Colors.grey,
                                    ),
                              const SizedBox(width: 8),
                              Text(
                                user?.status ?? "",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // About Section
              SliverToBoxAdapter(
                child: _buildAnimatedSection(
                  Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(
                              "About",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF075E54),
                              ),
                            ),
                            Spacer(),
                            widget.isMe
                                ? IconButton(
                                    onPressed: () {}, icon: Icon(Icons.edit))
                                : SizedBox.shrink()
                          ]),
                          const SizedBox(height: 8),
                          Text(
                            userDescription,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  delay: 0.1,
                ),
              ),
              if (!widget.isMe) ...[
                SliverToBoxAdapter(
                  child: _buildAnimatedSection(
                    Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            "Media, Links, and Docs",
                            trailing: mediaFiles.isNotEmpty
                                ? TextButton.icon(
                                    onPressed: () => _showFullMediaGallery(
                                        context, mediaFiles),
                                    icon: Text(
                                      "SEE ALL",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal,
                                      ),
                                    ),
                                    label: Icon(
                                      Icons.arrow_forward,
                                      size: 16,
                                      color: Colors.teal,
                                    ),
                                  )
                                : null,
                          ),
                          if (isLoadingMedia)
                            Center(
                              child: Column(
                                children: [
                                  CircularProgressIndicator(
                                    color: Color(0xFF075E54),
                                    strokeWidth: 3,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    "Looking for media...",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (mediaFiles.isEmpty)
                            Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.image_not_supported,
                                      size: 64,
                                      color: Colors.grey.shade400,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      "No media shared",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        if (chatroomId == null) return;
                                        loadSharedMedia(chatroomId!);
                                      },
                                      icon: const Icon(Icons.refresh),
                                      label: const Text("Retry"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF075E54),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 3,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: 1.0,
                                ),
                                itemCount: mediaFiles.length > 6
                                    ? 6
                                    : mediaFiles.length,
                                itemBuilder: (context, index) {
                                  final file = mediaFiles[index];
                                  return Hero(
                                    tag: 'media-${file.path}',
                                    child: GestureDetector(
                                      onTap: () =>
                                          _openMediaFile(context, file),
                                      child: _buildMediaThumbnail(file),
                                    ),
                                  );
                                },
                              ),
                            ),
                          SizedBox(height: 8),
                        ],
                      ),
                    ),
                    delay: 0.2,
                  ),
                ),
              ],

              // Settings or Contact Actions
              SliverToBoxAdapter(
                child: _buildAnimatedSection(
                  Card(
                    margin: const EdgeInsets.all(8.0),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: widget.isMe
                          ? [
                              // My profile options
                              _buildListTile(
                                icon: Icons.settings,
                                title: "Settings",
                                subtitle: "Privacy, security, and more",
                                onTap: () {},
                              ),
                              _buildDivider(),
                              _buildListTile(
                                icon: Icons.notifications,
                                title: "Notifications",
                                subtitle: "Message, group & call tones",
                                onTap: () {},
                              ),
                              _buildDivider(),
                              _buildListTile(
                                icon: Icons.help_outline,
                                title: "Help",
                                subtitle:
                                    "Help center, contact us, privacy policy",
                                onTap: () {},
                              ),
                              _buildDivider(),
                              _buildListTile(
                                icon: Icons.group,
                                title: "Invite Friends",
                                subtitle: "Share SwiftTalk with friends",
                                onTap: () {},
                              ),
                            ]
                          : [
                              // Other user actions
                              _buildListTile(
                                icon: Icons.message,
                                title: "Message",
                                color: Color(0xFF075E54),
                                onTap: () {
                                  Navigator.pop(context);
                                },
                              ),
                              _buildDivider(),
                              _buildListTile(
                                icon: Icons.call,
                                title: "Voice Call",
                                color: Color(0xFF075E54),
                                onTap: () {
                                  // Start voice call animation
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('Starting voice call...')));
                                },
                              ),
                              _buildDivider(),
                              _buildListTile(
                                icon: Icons.videocam,
                                title: "Video Call",
                                color: Color(0xFF075E54),
                                onTap: () {
                                  // Start video call animation
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('Starting video call...')));
                                },
                              ),
                              _buildDivider(),
                              _buildListTile(
                                icon: Icons.person_off,
                                title: "Block",
                                color: Colors.red,
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text("Block this contact?"),
                                      content: Text(
                                          "Blocked contacts will no longer be able to call you or send you messages."),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text("CANCEL"),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                                    content: Text(
                                                        'Contact blocked')));
                                          },
                                          child: Text("BLOCK",
                                              style:
                                                  TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                    ),
                  ),
                  delay: 0.3,
                ),
              ),

              // Footer space
              SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 72,
      color: Colors.grey.withOpacity(0.3),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color ?? Colors.grey.shade700,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: color ?? Colors.black87,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            )
          : null,
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey.shade400,
      ),
      onTap: onTap,
    );
  }

  void _openMediaFile(BuildContext context, File file) =>
      OpenFile.open(file.path);

  void _showFullMediaGallery(BuildContext context, List<File> files) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MediaGalleryPage(files: files),
      ),
    );
  }
}

class MediaGalleryPage extends StatelessWidget {
  final List<File> files;

  const MediaGalleryPage({super.key, required this.files});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Media Gallery",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back, color: Colors.white)),
        backgroundColor: Colors.teal,
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          final fileExt = path.extension(file.path).toLowerCase();
          final isImage =
              ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(fileExt);
          final isVideo = ['.mp4', '.mov', '.avi', '.mkv'].contains(fileExt);
          final isPdf = ['.pdf'].contains(fileExt);

          return Hero(
            tag: 'media-${file.path}',
            child: GestureDetector(
              onTap: () {
                if (isImage) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                        backgroundColor: Colors.black,
                        appBar: AppBar(
                          backgroundColor: Colors.black,
                          iconTheme: IconThemeData(color: Colors.white),
                        ),
                        body: Center(
                          child: InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 3.0,
                            child: Image.file(file),
                          ),
                        ),
                      ),
                    ),
                  );
                } else {
                  OpenFile.open(file.path);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
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
                          return Center(
                            child: Icon(Icons.broken_image, color: Colors.grey),
                          );
                        },
                      )
                    else if (isVideo)
                      Container(
                        color: Colors.black,
                        child: Center(
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
                        child: Center(
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
                        child: Center(
                          child: Icon(
                            Icons.insert_drive_file,
                            color: Colors.blue,
                            size: 40,
                          ),
                        ),
                      ),
                    if (!isImage)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          color: Colors.black.withOpacity(0.6),
                          child: Text(
                            path.basename(file.path),
                            style: TextStyle(color: Colors.white, fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
