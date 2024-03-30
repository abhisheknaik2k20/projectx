import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:projectx/pages/Profile.dart';

class DrawerSlide extends StatefulWidget {
  const DrawerSlide({super.key});

  @override
  State<DrawerSlide> createState() => _DrawerSlideState();
  static void showSlideDrawer(BuildContext context) {
    Scaffold.of(context).openDrawer();
  }
}

class _DrawerSlideState extends State<DrawerSlide> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.teal.shade500),
              accountName: const Text("HELLO !"),
              accountEmail: Text(user?.displayName ?? "test@gmail.com")),
          ListTile(
            selectedColor: Colors.grey,
            leading: const Icon(
              Icons.account_circle,
              size: 35,
            ),
            title: const Text("Profile Page"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ProfilePage(
                          UserUID: FirebaseAuth.instance.currentUser!.uid,
                        )),
              );
            },
          ),
          ListTile(
            selectedColor: Colors.grey,
            leading: const Icon(
              Icons.settings,
              size: 35,
            ),
            title: const Text("Settings"),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout, size: 35),
            title: const Text("Logout?"),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Logout Confirmation',
                        style: GoogleFonts.roboto(fontSize: 25)),
                    content: Text('Are you sure you want to logout?',
                        style: GoogleFonts.ptSans(fontSize: 17)),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Yes'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('No'),
                      ),
                    ],
                  );
                },
              );
            },
          )
        ],
      ),
    );
  }
}
