import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:the_wall_social_media_app/helper/helper_methods.dart';
import 'package:the_wall_social_media_app/widgets/widget_export.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  final usersCollection = FirebaseFirestore.instance.collection('Users');

  Future<void> editField(String field) async {
    String newValue = '';
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          "Edit $field",
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter new $field",
            hintStyle: const TextStyle(color: Colors.grey),
          ),
          onChanged: (value) {
            newValue = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(newValue),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newValue.trim().isNotEmpty) {
      await usersCollection.doc(currentUser!.uid).update({field: newValue});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Profile Page'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: usersCollection.doc(currentUser!.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('User data not found'),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>?;

          if (userData == null) {
            return const Center(
              child: Text('User data is null'),
            );
          }

          return ListView(
            children: [
              const SizedBox(height: 50),
              const Icon(Icons.person, size: 72),
              const SizedBox(height: 10),
              Text(
                currentUser!.email!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 50),
              Padding(
                padding: const EdgeInsets.only(left: 25.0),
                child: Text(
                  'My Details',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              MyTextBox(
                text: userData['username'] ?? 'No username',
                sectionName: 'username',
                onPressed: () => editField('username'),
              ),
              MyTextBox(
                text: userData['bio'] ?? 'No bio',
                sectionName: 'bio',
                onPressed: () => editField('bio'),
              ),
              const SizedBox(height: 50),
              Padding(
                padding: const EdgeInsets.only(left: 25.0),
                child: Text(
                  'My Posts',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('User Posts')
                    .where('UserEmail', isEqualTo: currentUser!.email)
                    .snapshots(),
                builder: (context, postSnapshot) {
                  if (postSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (postSnapshot.hasError) {
                    return Center(
                      child: Text('Error: ${postSnapshot.error}'),
                    );
                  }
                  if (!postSnapshot.hasData || postSnapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No posts found'),
                    );
                  }

                  final posts = postSnapshot.data!.docs;

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      return WallPost(
                        message: post['Message'],
                        user: post['UserEmail'],
                        postId: post.id,
                        likes: List<String>.from(post['Likes'] ?? []),
                        time: formatDate(post['TimeStamp']),
                      );
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
