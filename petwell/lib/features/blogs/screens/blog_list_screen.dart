import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'blog_post_screen.dart';

class BlogListScreen extends StatelessWidget {
  const BlogListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PetCare Blog'),
        backgroundColor: const Color(0xFFe74d3d),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFecdaca),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('blogs')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading blog posts: ${snapshot.error}'));
          }

          final blogs = snapshot.data?.docs ?? [];

          if (blogs.isEmpty) {
            return const Center(child: Text('No blog posts yet'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: blogs.length,
            itemBuilder: (context, index) {
              final blogData = blogs[index].data() as Map<String, dynamic>;

              final title = blogData['title'] as String? ?? 'Untitled';
              final content = blogData['content']?.toString() ?? '';
              final excerpt = content.length > 100 ? '${content.substring(0, 100)}...' : content;
              final imageBase64 = blogData['imageBase64'] as String?;
              final authorName = blogData['authorName'] as String? ?? 'Unknown Author';
              final createdAt = (blogData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlogPostScreen(blogData: blogData),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: imageBase64 != null && imageBase64.isNotEmpty
                              ? Image.memory(
                                  base64Decode(imageBase64),
                                  width: 80, // Reduced width to free up space
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey,
                                      size: 30,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.pets,
                                    color: Colors.grey,
                                    size: 30,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 10), // Reduced spacing
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.book, color: Color(0xFFe74d3d), size: 20), // Reduced icon size
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 16, // Reduced font size
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF333333),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(Icons.person, color: Color(0xFFe74d3d), size: 16), // Reduced icon size
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'By $authorName',
                                      style: const TextStyle(
                                        fontSize: 14, // Reduced font size
                                        fontStyle: FontStyle.italic,
                                        color: Color(0xFFe74d3d),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                excerpt,
                                style: const TextStyle(
                                  fontSize: 12, // Reduced font size
                                  color: Colors.black54,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                                style: const TextStyle(
                                  fontSize: 10, // Reduced font size
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}