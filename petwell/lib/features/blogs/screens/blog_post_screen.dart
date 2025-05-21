import 'package:flutter/material.dart';
import 'dart:convert';

class BlogPostScreen extends StatelessWidget {
  final Map<String, dynamic> blogData;

  const BlogPostScreen({super.key, required this.blogData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          blogData['title'] ?? 'Blog Post',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFe74d3d),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFecdaca),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (blogData['imageBase64'] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      base64Decode(blogData['imageBase64']),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.book, color: Color(0xFFe74d3d), size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        blogData['title'] ?? 'No Title',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      color: Color(0xFFe74d3d),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'By ${blogData['authorName'] ?? 'Unknown Author'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFFe74d3d),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Color(0xFFe74d3d).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      blogData['content'] ?? 'No Content',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFF333333),
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
