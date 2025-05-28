import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

// Record class to handle Firestore data
class Record {
  final String id;
  final String userId;
  final DateTime date;
  final String _searchQuery = '';

  Record({required this.id, required this.userId, required this.date});

  static Record fromFirestore(Map<String, dynamic> data, String id) {
    return Record(
      id: id,
      userId: data['userId'] as String? ?? '',
      date:
          (data['date'] is Timestamp)
              ? (data['date'] as Timestamp).toDate()
              : (data['date'] is DateTime)
              ? data['date'] as DateTime
              : DateTime.now(),
    );
  }
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  String _searchQuery = '';
  String _petSearchQuery = '';
  final _blogTitleController = TextEditingController();
  final _blogContentController = TextEditingController();
  String? _selectedImageBase64;
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

  Future<void> _addBlogPost() async {
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
          'imageBase64': _selectedImageBase64,
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

  Future<void> _deleteUser(String userId) async {
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

  Future<void> _deletePet(String petId) async {
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

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/signin', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
    }
  }

  Future<Map<String, dynamic>> _fetchAnalytics() async {
    try {
      // User count
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      final userCount = usersSnapshot.docs.length;

      // Pet count
      final petsSnapshot =
          await FirebaseFirestore.instance.collection('pets').get();
      final petCount = petsSnapshot.docs.length;

      // Records analysis
      final recordsSnapshot =
          await FirebaseFirestore.instance.collection('records').get();
      double averageHour = 0;
      int validRecords = 0;
      Map<String, int> timePeriodCounts = {
        'Morning': 0, // 6 AM - 12 PM
        'Afternoon': 0, // 12 PM - 6 PM
        'Evening': 0, // 6 PM - 12 AM
        'Night': 0, // 12 AM - 6 AM
      };
      Map<String, int> remindersPerUser = {};
      Map<String, int> recordTypeCount = {};

      for (var doc in recordsSnapshot.docs) {
        try {
          final data = doc.data();
          // Extract fields safely
          final userId = data['userId'] as String? ?? '';
          final recordType = data['type'] as String? ?? 'Unknown';

          // Handle date field
          DateTime recordDate;
          if (data['date'] is Timestamp) {
            recordDate = (data['date'] as Timestamp).toDate();
          } else if (data['date'] is DateTime) {
            recordDate = data['date'] as DateTime;
          } else {
            continue;
          }

          // Count records per user
          remindersPerUser[userId] = (remindersPerUser[userId] ?? 0) + 1;

          // Count record types
          recordTypeCount[recordType] = (recordTypeCount[recordType] ?? 0) + 1;

          // Calculate average hour
          final hour = recordDate.hour + recordDate.minute / 60.0;
          averageHour += hour;
          validRecords++;

          // Categorize by time period
          if (recordDate.hour >= 6 && recordDate.hour < 12) {
            timePeriodCounts['Morning'] = timePeriodCounts['Morning']! + 1;
          } else if (recordDate.hour >= 12 && recordDate.hour < 18) {
            timePeriodCounts['Afternoon'] = timePeriodCounts['Afternoon']! + 1;
          } else if (recordDate.hour >= 18 && recordDate.hour < 24) {
            timePeriodCounts['Evening'] = timePeriodCounts['Evening']! + 1;
          } else {
            timePeriodCounts['Night'] = timePeriodCounts['Night']! + 1;
          }
        } catch (e) {
          print('Error processing record ${doc.id}: $e');
          continue;
        }
      }

      averageHour = validRecords > 0 ? averageHour / validRecords : 0;

      // Average records per user
      double averageRecordsPerUser = 0;
      if (userCount > 0) {
        final totalRecords = remindersPerUser.values.fold(
          0,
          (sum, count) => sum + count,
        );
        averageRecordsPerUser = totalRecords / userCount;
      }

      // Most active time period
      final mostActiveTimePeriod = timePeriodCounts.entries
          .fold<MapEntry<String, int>?>(null, (prev, entry) {
            if (prev == null || entry.value > prev.value) return entry;
            return prev;
          });

      // Most common record type
      final mostCommonRecordType = recordTypeCount.entries
          .fold<MapEntry<String, int>?>(null, (prev, entry) {
            if (prev == null || entry.value > prev.value) return entry;
            return prev;
          });

      // Most common pet species
      Map<String, int> speciesCount = {};
      for (var pet in petsSnapshot.docs) {
        final data = pet.data();
        final species = data['species'] as String? ?? 'Unknown';
        speciesCount[species] = (speciesCount[species] ?? 0) + 1;
      }

      final mostCommonSpecies = speciesCount.entries
          .fold<MapEntry<String, int>?>(null, (prev, entry) {
            if (prev == null || entry.value > prev.value) return entry;
            return prev;
          });

      return {
        'userCount': userCount,
        'petCount': petCount,
        'totalRecords': recordsSnapshot.docs.length,
        'averageReminderHour': averageHour,
        'averageRecordsPerUser': averageRecordsPerUser,
        'mostCommonSpecies': mostCommonSpecies?.key,
        'mostCommonSpeciesCount': mostCommonSpecies?.value ?? 0,
        'mostActiveTimePeriod': mostActiveTimePeriod?.key,
        'mostActiveTimePeriodCount': mostActiveTimePeriod?.value ?? 0,
        'mostCommonRecordType': mostCommonRecordType?.key,
        'mostCommonRecordTypeCount': mostCommonRecordType?.value ?? 0,
      };
    } catch (e) {
      print('Error fetching analytics: $e');
      return {
        'userCount': 0,
        'petCount': 0,
        'totalRecords': 0,
        'averageReminderHour': 0.0,
        'averageRecordsPerUser': 0.0,
        'mostCommonSpecies': null,
        'mostCommonSpeciesCount': 0,
        'mostActiveTimePeriod': null,
        'mostActiveTimePeriodCount': 0,
        'mostCommonRecordType': null,
        'mostCommonRecordTypeCount': 0,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildUsersTab(),
      _buildPetsTab(),
      _buildBlogsTab(),
      _buildAnalyticsTab(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 4) {
            _logout();
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        backgroundColor: const Color.fromARGB(255, 234, 231, 231),
        selectedItemColor: const Color(0xFFFF8C42),
        unselectedItemColor: const Color(0xFFFF8C42),
        selectedFontSize: 12,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Users"),
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: "Pets"),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_document),
            label: "Blogs",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: "Analytics",
          ),
        ],
      ),
    );
  }

  // --- TAB BUILDERS ---

  Widget _buildPetsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pets',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search pet by name...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              setState(() {
                _petSearchQuery = value.toLowerCase();
              });
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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

                // Filter pets based on search query
                final List<DocumentSnapshot> filteredPets =
                    _petSearchQuery.isEmpty
                        ? pets
                        : pets.where((pet) {
                          final data = pet.data() as Map<String, dynamic>;
                          final name =
                              (data['name'] ?? '').toString().toLowerCase();
                          return name.contains(_petSearchQuery);
                        }).toList();

                // Sort and group pets alphabetically
                final Map<String, List<DocumentSnapshot>> groupedPets = {};

                for (var pet in filteredPets) {
                  final data = pet.data() as Map<String, dynamic>;
                  final name = data['name'] ?? 'Unknown';
                  final firstLetter =
                      name.isNotEmpty ? name[0].toUpperCase() : '?';

                  groupedPets.putIfAbsent(firstLetter, () => []).add(pet);
                }

                final sortedKeys = groupedPets.keys.toList()..sort();

                return ListView.builder(
                  itemCount: groupedPets.length * 2,
                  itemBuilder: (context, index) {
                    final int groupIndex = index ~/ 2;
                    final bool isHeader = index % 2 == 0;

                    if (isHeader && groupIndex < sortedKeys.length) {
                      final letter = sortedKeys[groupIndex];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          letter,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF8C42),
                          ),
                        ),
                      );
                    } else {
                      final letter = sortedKeys[groupIndex];
                      final petList = groupedPets[letter]!;
                      return Column(
                        children:
                            petList.map((pet) {
                              final data = pet.data() as Map<String, dynamic>;
                              return Card(
                                elevation: 5,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: ListTile(
                                  leading: _buildImageWidget(
                                    data['imageBase64'],
                                  ),
                                  title: Text(
                                    data['name'] ?? 'Unknown Pet',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${data['species']}${data['breed'] != null ? ' (${data['breed']})' : ''}, ${data['age'] ?? 'N/A'} years',
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Color(0xFFFF8C42),
                                    ),
                                    onPressed: () => _deletePet(pet.id),
                                  ),
                                ),
                              );
                            }).toList(),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Users',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Color(0xFFFF8C42)),
                onPressed: _logout,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search user by name...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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

                // Filter users based on search query
                final List<DocumentSnapshot> filteredUsers =
                    _searchQuery.isEmpty
                        ? users
                        : users.where((user) {
                          final data = user.data() as Map<String, dynamic>;
                          final name =
                              (data['name'] ?? '').toString().toLowerCase();
                          return name.contains(_searchQuery);
                        }).toList();

                // Sort and group users alphabetically
                final Map<String, List<DocumentSnapshot>> groupedUsers = {};

                for (var user in filteredUsers) {
                  final data = user.data() as Map<String, dynamic>;
                  final name = data['name'] ?? 'Unknown';
                  final firstLetter =
                      name.isNotEmpty ? name[0].toUpperCase() : '?';

                  groupedUsers.putIfAbsent(firstLetter, () => []).add(user);
                }

                final sortedKeys = groupedUsers.keys.toList()..sort();

                return ListView.builder(
                  itemCount: groupedUsers.length * 2,
                  itemBuilder: (context, index) {
                    final int groupIndex = index ~/ 2;
                    final bool isHeader = index % 2 == 0;

                    if (isHeader && groupIndex < sortedKeys.length) {
                      final letter = sortedKeys[groupIndex];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          letter,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF8C42),
                          ),
                        ),
                      );
                    } else {
                      final letter = sortedKeys[groupIndex];
                      final userList = groupedUsers[letter]!;
                      return Column(
                        children:
                            userList.map((user) {
                              final data = user.data() as Map<String, dynamic>;
                              return Card(
                                elevation: 5,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: ExpansionTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFFFF8C42),
                                    child: Text(
                                      data['name']
                                              ?.substring(0, 1)
                                              .toUpperCase() ??
                                          'U',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    data['name'] ?? 'No Name',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(data['email'] ?? 'No Email'),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.email,
                                                color: Color(0xFFFF8C42),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Email: ${data['email'] ?? 'N/A'}',
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.calendar_today,
                                                color: Color(0xFFFF8C42),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Joined: ${(data['createdAt'] as Timestamp?)?.toDate().toString().substring(0, 10) ?? 'N/A'}',
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          const Text(
                                            'Pets',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF333333),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          StreamBuilder<QuerySnapshot>(
                                            stream:
                                                FirebaseFirestore.instance
                                                    .collection('pets')
                                                    .where(
                                                      'userId',
                                                      isEqualTo: user.id,
                                                    )
                                                    .snapshots(),
                                            builder: (context, petSnapshot) {
                                              if (petSnapshot.hasError) {
                                                return const Text(
                                                  'Error loading pets',
                                                );
                                              }
                                              if (petSnapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return const CircularProgressIndicator();
                                              }
                                              final pets =
                                                  petSnapshot.data!.docs;
                                              if (pets.isEmpty) {
                                                return const Text(
                                                  'No pets found for this user',
                                                );
                                              }
                                              return ListView.builder(
                                                shrinkWrap: true,
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                itemCount: pets.length,
                                                itemBuilder: (
                                                  context,
                                                  petIndex,
                                                ) {
                                                  final pet = pets[petIndex];
                                                  final petData =
                                                      pet.data()
                                                          as Map<
                                                            String,
                                                            dynamic
                                                          >;
                                                  return ListTile(
                                                    leading: _buildImageWidget(
                                                      petData['imageBase64'],
                                                    ),
                                                    title: Text(
                                                      petData['name'] ??
                                                          'Unknown Pet',
                                                    ),
                                                    subtitle: Text(
                                                      '${petData['species']}${petData['breed'] != null ? ' (${petData['breed']})' : ''}',
                                                    ),
                                                    trailing: IconButton(
                                                      icon: const Icon(
                                                        Icons.delete,
                                                        color: Color(0xFFFF8C42),
                                                      ),
                                                      onPressed:
                                                          () => _deletePet(
                                                            pet.id,
                                                          ),
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 16),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton.icon(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Color(0xFFFF8C42),
                                              ),
                                              label: const Text(
                                                'Delete User',
                                                style: TextStyle(
                                                  color:Color(0xFFFF8C42),
                                                ),
                                              ),
                                              onPressed:
                                                  () => _deleteUser(user.id),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlogsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Blogs',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create Blog Post',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Title Field
                  TextField(
                    controller: _blogTitleController,
                    decoration: InputDecoration(
                      labelText: 'Blog Title',
                      hintText: 'Enter title here',
                      prefixIcon: const Icon(
                        Icons.title,
                        color: Color(0xFFFF8C42),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: const Color(0xFFFF8C42)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    enabled: !_isUploading,
                  ),
                  const SizedBox(height: 16),
                  // Content Field
                  TextField(
                    controller: _blogContentController,
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: 'Blog Content',
                      hintText: 'Write something...',
                      prefixIcon: const Icon(
                        Icons.article,
                        color: Color(0xFFFF8C42),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: const Color(0xFFFF8C42)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    enabled: !_isUploading,
                  ),
                  const SizedBox(height: 16),
                  // Image Upload Section
                  if (_selectedImageBase64 == null)
                    ElevatedButton.icon(
                      onPressed: _isUploading ? null : _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Pick Image'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8C42),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            base64Decode(_selectedImageBase64!),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => const Icon(Icons.error),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed:
                              _isUploading
                                  ? null
                                  : () {
                                    setState(() {
                                      _selectedImageBase64 = null;
                                    });
                                  },
                          icon: const Icon(Icons.delete, color: Color(0xFFFF8C42)),
                          label: const Text(
                            'Remove Image',
                            style: TextStyle(color: Color(0xFFFF8C42)),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _addBlogPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8C42),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      child:
                          _isUploading
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text("Add Blog Post"),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Published Blogs',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
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
                return const Center(child: CircularProgressIndicator());
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
                    elevation: 5,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      leading: _buildImageWidget(data['imageBase64']),
                      title: Text(
                        data['title'] ?? 'No Title',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${data['authorName'] ?? 'Unknown'} - ${(data['createdAt'] as Timestamp?)?.toDate().toString().substring(0, 10) ?? 'Unknown'}',
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analytics',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _fetchAnalytics(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error loading analytics: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final analytics = snapshot.data!;
                final userCount = analytics['userCount'] as int;
                final petCount = analytics['petCount'] as int;
                final totalRecords = analytics['totalRecords'] as int;
                final averageReminderHour =
                    analytics['averageReminderHour'] as double;
                final averageRecordsPerUser =
                    analytics['averageRecordsPerUser'] as double;
                final mostCommonSpecies =
                    analytics['mostCommonSpecies'] as String?;
                final mostCommonSpeciesCount =
                    analytics['mostCommonSpeciesCount'] as int;
                final mostActiveTimePeriod =
                    analytics['mostActiveTimePeriod'] as String?;
                final mostCommonRecordType =
                    analytics['mostCommonRecordType'] as String?;
                final mostCommonRecordTypeCount =
                    analytics['mostCommonRecordTypeCount'] as int;

                // Convert average hour to time format
                final hours = averageReminderHour.floor();
                final minutes = ((averageReminderHour - hours) * 60).round();
                final averageTime =
                    '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      // Overview Cards Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildAnalyticsCard(
                              title: 'Total Users',
                              value: '$userCount',
                              icon: Icons.people,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildAnalyticsCard(
                              title: 'Total Pets',
                              value: '$petCount',
                              icon: Icons.pets,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Records Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildAnalyticsCard(
                              title: 'Total Records',
                              value: '$totalRecords',
                              icon: Icons.list_alt,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildAnalyticsCard(
                              title: 'Avg Records/User',
                              value: averageRecordsPerUser.toStringAsFixed(1),
                              icon: Icons.trending_up,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Average Reminder Time Card
                      Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Average Record Time',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 40,
                                    color: Color(0xFFFF8C42),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    averageTime,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Most Common Species Card
                      Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Most Common Pet Species',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.pets,
                                    size: 40,
                                    color: Color(0xFFFF8C42),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mostCommonSpecies ?? 'N/A',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF333333),
                                        ),
                                      ),
                                      Text(
                                        'Count: $mostCommonSpeciesCount',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Activity Insights
                      Row(
                        children: [
                          Expanded(
                            child: Card(
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Most Active Time',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF333333),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      mostActiveTimePeriod ?? 'N/A',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Color(0xFFFF8C42),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Card(
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Common Record Type',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF333333),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      mostCommonRecordType ?? 'N/A',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Color(0xFFFF8C42),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Count: $mostCommonRecordTypeCount',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: const Color(0xFFFF8C42)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String? imageBase64) {
    if (imageBase64 == null || imageBase64.isEmpty) {
      return const CircleAvatar(
        backgroundImage: AssetImage('assets/default.jpg'),
        radius: 25,
      );
    }
    try {
      return CircleAvatar(
        backgroundImage: MemoryImage(base64Decode(imageBase64)),
        radius: 25,
        onBackgroundImageError: (_, __) => const Icon(Icons.error),
      );
    } catch (e) {
      return const CircleAvatar(
        backgroundImage: AssetImage('assets/default.jpg'),
        radius: 25,
      );
    }
  }
}
