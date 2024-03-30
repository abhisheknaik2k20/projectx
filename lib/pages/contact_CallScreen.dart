import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';

class call_Screen extends StatefulWidget {
  final Contact contact;
  const call_Screen({super.key, required this.contact});

  @override
  State<call_Screen> createState() => _call_Screen();
}

class _call_Screen extends State<call_Screen> {
  @override
  Widget build(BuildContext context) {
    Contact contact = widget.contact;
    return Scaffold(
        backgroundColor: Colors.grey.shade900,
        appBar: AppBar(
          elevation: 4,
          shadowColor: Colors.black12,
          leading: Padding(
            padding: const EdgeInsets.only(bottom: 15, left: 8, top: 5),
            child: IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.arrow_back_ios_new, size: 35)),
          ),
          title: Center(
            child: Text(
              contact.displayName!,
              style: GoogleFonts.ubuntu(color: Colors.black, fontSize: 25),
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              (contact.avatar != null && contact.avatar!.isNotEmpty)
                  ? CircleAvatar(
                      backgroundImage: MemoryImage(contact.avatar!),
                      radius: 50,
                    )
                  : const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.teal,
                        child: Icon(Icons.account_circle, size: 100),
                      ),
                    ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  contact.phones!.first.value!,
                  style: GoogleFonts.ptSans(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(50))),
                    width: 100,
                    child: InkWell(
                      onTap: () async {
                        Uri uri = Uri(
                            scheme: 'tel', path: contact.phones!.first.value);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        } else {
                          print('cannot Launch');
                        }
                      },
                      child: Lottie.asset('assets/call.json'),
                    ),
                  ),
                  const SizedBox(width: 50),
                  Container(
                    decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(50))),
                    width: 100,
                    child: InkWell(
                      onTap: () async {
                        Uri uri = Uri(
                            scheme: 'SMS', path: contact.phones!.first.value);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        } else {
                          print('cannot Launch');
                        }
                      },
                      child: Lottie.asset('assets/message.json'),
                    ),
                  )
                ],
              )
            ],
          ),
        ));
  }
}
