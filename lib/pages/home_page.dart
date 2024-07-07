import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:the_wall_social_media_app/helper/helper_methods.dart';
import 'package:the_wall_social_media_app/pages/page_exports.dart';
import 'package:the_wall_social_media_app/widgets/widget_export.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final textController = TextEditingController();
  int _selectedIndex = 0;

  void signOut() {
    FirebaseAuth.instance.signOut();
  }

  Future<void> postMessage() async {
    if (textController.text.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('User Posts').add({
          "UserEmail": currentUser.email,
          "Message": textController.text,
          "TimeStamp": Timestamp.now(),
          "Likes": [],
        });
        setState(() {
          textController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Message posted!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post message: $e')),
        );
      }
    }
  }

  void goToProfilePage() {
    //Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        // Home
        break;
      case 1:
        // Profile
        goToProfilePage();
        break;
      case 2:
        // Sign out
        signOut();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Home'),
      ),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('User Posts')
                    .orderBy("TimeStamp", descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final post = snapshot.data!.docs[index];
                        return WallPost(
                          message: post['Message'],
                          user: post['UserEmail'],
                          postId: post.id,
                          likes: List<String>.from(post['Likes'] ?? []),
                          time: formatDate(post['TimeStamp']),
                        );
                      },
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  Expanded(
                    child: MyTextField(
                      controller: textController,
                      hintText: 'Say something...',
                      obscureText: false,
                    ),
                  ),
                  IconButton(
                    onPressed: postMessage,
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Text("Logged in as: ${currentUser.email}"),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Sign Out',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}
