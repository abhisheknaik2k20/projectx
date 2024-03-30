import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:projectx/pages/contact_CallScreen.dart';
import 'package:riverpod/riverpod.dart';

final searchtextProvider = Provider<TextEditingController>(
  (ref) {
    return TextEditingController();
  },
);

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  bool isMounted = false;
  Iterable<Contact> contacts = [];
  Iterable<Contact> foundUsers = [];
  bool isLoading = true;
  bool isSearchVisible = false;

  late final TextEditingController searchtext = TextEditingController();

  void getContacts() async {
    Iterable<Contact> contactList = await ContactsService.getContacts();
    if (isMounted) {
      setState(() {
        contacts = contactList;
        foundUsers = contactList;
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    isMounted = true;
    super.initState();
    getContacts();
    foundUsers = contacts;
  }

  @override
  void dispose() {
    isMounted = false;
    searchtext.dispose();
    super.dispose();
  }

  void runfilter(String enteredKeyword) {
    Iterable<Contact> results = [];

    if (enteredKeyword.isEmpty || searchtext.text.isEmpty) {
      results = contacts;
    } else {
      results = contacts.where((contact) {
        return contact.displayName
                ?.toLowerCase()
                .contains(enteredKeyword.toLowerCase()) ??
            false ||
                (contact.phones?.isNotEmpty == true &&
                    contact.phones!.any((phone) =>
                        phone.value
                            ?.toLowerCase()
                            .contains(enteredKeyword.toLowerCase()) ??
                        false));
      });
    }
    setState(() {
      foundUsers = results;
    });
  }

  Future<bool> _onWillPop() async {
    if (isSearchVisible) {
      setState(() {
        isSearchVisible = false;
      });
      return false;
    }
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Are you sure?'),
            content: const Text('Do you want to exit an App'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Column(
        children: [
          Container(
            height: 75,
            decoration: BoxDecoration(color: Colors.teal.shade500),
            child: Row(
              children: [
                isSearchVisible
                    ? Expanded(
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.menu,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            Expanded(
                              child: TextFormField(
                                cursorColor: Colors.white,
                                controller: searchtext,
                                onChanged: (value) => runfilter(value),
                                decoration: const InputDecoration(
                                  hintText: 'Search.....',
                                  hintStyle: TextStyle(color: Colors.white),
                                  border: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.white)),
                                  focusedBorder: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.white)),
                                  enabledBorder: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.white)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Expanded(
                        child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.menu,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          Padding(
                              padding: const EdgeInsets.only(left: 20),
                              child: Text(
                                "Contacts",
                                style: GoogleFonts.anton(
                                    color: Colors.white,
                                    fontSize: 30,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      )
                                    ]),
                              )),
                        ],
                      )),
                IconButton(
                    onPressed: () {
                      setState(() {
                        isSearchVisible = !isSearchVisible;
                      });
                    },
                    icon: const Icon(
                      Icons.search,
                      size: 40,
                      color: Colors.white,
                    )),
              ],
            ),
          ),
          isLoading
              ? Expanded(
                  child: SingleChildScrollView(
                      child: Lottie.asset('assets/loading1.json')),
                )
              : Expanded(
                  child: ListView.builder(
                    itemCount: foundUsers.length,
                    itemBuilder: (context, index) {
                      Contact contact = foundUsers.elementAt(index);
                      return Container(
                        height: 65,
                        decoration: BoxDecoration(
                            border: Border(
                                bottom: BorderSide(
                                    color: Colors.grey.shade700, width: 0.1))),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    call_Screen(contact: contact),
                              ),
                            );
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom:
                                    BorderSide(color: Colors.grey, width: 0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: (contact.avatar != null &&
                                          contact.avatar!.isNotEmpty)
                                      ? CircleAvatar(
                                          backgroundImage:
                                              MemoryImage(contact.avatar!))
                                      : const CircleAvatar(
                                          backgroundColor: Colors.teal,
                                          child: Icon(Icons.account_circle,
                                              size: 40),
                                        ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 10.0),
                                        child: Text(
                                          contact.displayName ?? '',
                                          style: GoogleFonts.ptSans(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17),
                                        ),
                                      ),
                                      Text(
                                        contact.phones?.isNotEmpty == true
                                            ? contact.phones!.first.value ?? ''
                                            : 'No phone number',
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}
