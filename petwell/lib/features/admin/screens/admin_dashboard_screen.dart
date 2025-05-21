import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _blogTitleController = TextEditingController();
  final _blogContentController = TextEditingController();
  String? _selectedImageBase64; // Changed from File/Uint8List
  bool _isUploading = false;

  @override
  void dispose() {
    _blogTitleController.dispose();
    _blogContentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      Uint8List? imageBytes;
      if (kIsWeb) {
        imageBytes = await pickedFile.readAsBytes();
      } else {
        imageBytes = await File(pickedFile.path).readAsBytes();
      }
      String base64Image = base64Encode(imageBytes);
      setState(() {
        _selectedImageBase64 = base64Image;
      });
    }
  }

  void _addBlogPost() async {
    if (_blogTitleController.text.isEmpty ||
        _blogContentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        await FirebaseFirestore.instance.collection('blogs').add({
          'title': _blogTitleController.text.trim(),
          'content': _blogContentController.text.trim(),
          'authorId': user.uid,
          'authorName': userDoc.data()?['name'] ?? 'Admin',
          'createdAt': FieldValue.serverTimestamp(),
          'imageBase64': _selectedImageBase64, // Store Base64 string
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Blog post added successfully')),
        );
        _blogTitleController.clear();
        _blogContentController.clear();
        setState(() {
          _selectedImageBase64 = null;
          _isUploading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add blog post: $e')));
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _deleteUser(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete user: $e')));
    }
  }

  void _deletePet(String petId) async {
    try {
      await FirebaseFirestore.instance.collection('pets').doc(petId).delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pet deleted successfully')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete pet: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Users'), Tab(text: 'Pets'), Tab(text: 'Blogs')],
          ),
        ),
        body: TabBarView(
          children: [
            // Users Tab
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading users'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final users = snapshot.data!.docs;
                if (users.isEmpty) {
                  return const Center(child: Text('No users found'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final data = user.data() as Map<String, dynamic>;
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(data['name'] ?? 'No Name'),
                        subtitle: Text(data['email']),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteUser(user.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // Pets Tab
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('pets').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading pets'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final pets = snapshot.data!.docs;
                if (pets.isEmpty) {
                  return const Center(child: Text('No pets found'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pets.length,
                  itemBuilder: (context, index) {
                    final pet = pets[index];
                    final data = pet.data() as Map<String, dynamic>;
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(data['name']),
                        subtitle: Text(
                          '${data['species']}${data['breed'] != null ? ' (${data['breed']})' : ''}, ${data['age']} years',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deletePet(pet.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // Blogs Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create Blog Post',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _blogTitleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_isUploading,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _blogContentController,
                    decoration: const InputDecoration(
                      labelText: 'Content',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                    enabled: !_isUploading,
                  ),
                  const SizedBox(height: 16),
                  _selectedImageBase64 != null
                      ? Column(
                        children: [
                          Image.memory(
                            base64Decode(_selectedImageBase64!),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed:
                                _isUploading
                                    ? null
                                    : () {
                                      setState(() {
                                        _selectedImageBase64 = null;
                                      });
                                    },
                            child: const Text(
                              'Remove Image',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      )
                      : ElevatedButton.icon(
                        onPressed: _isUploading ? null : _pickImage,
                        icon: const Icon(Icons.image),
                        label: const Text('Pick Image'),
                      ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isUploading ? null : _addBlogPost,
                    child:
                        _isUploading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text('Add Blog Post'),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Blog Posts',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('blogs')
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Text('Error loading blogs');
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      final blogs = snapshot.data!.docs;
                      if (blogs.isEmpty) {
                        return const Text('No blog posts yet');
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: blogs.length,
                        itemBuilder: (context, index) {
                          final blog = blogs[index];
                          final data = blog.data() as Map<String, dynamic>;
                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text(data['title']),
                              subtitle: Text(
                                '${data['authorName']} - ${data['createdAt']?.toDate().toString().substring(0, 10) ?? 'Unknown'}',
                              ),
                              leading:
                                  data['imageBase64'] != null
                                      ? Image.memory(
                                        base64Decode(data['imageBase64']),
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(Icons.error),
                                      )
                                      : const Icon(Icons.image_not_supported),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
