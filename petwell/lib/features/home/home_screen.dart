import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../pets_profile/screens/add_pet_dialog.dart';
import '../blogs/screens/blog_list_screen.dart';
import '../blogs/screens/blog_post_screen.dart';
import '../pets_profile/models/pet_model.dart';
import '../pets_profile/screens/pet_details_screen.dart';
import 'profile_screen.dart';

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final PageController _pageController = PageController(initialPage: 0);
  late Timer _timer;
  int _currentPage = 0;
  String? _userName;
  int _postCount = 0;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  bool _isRecordsPanelVisible = false;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_postCount == 0) return;
      if (_currentPage < (_postCount - 1)) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      }
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userName = user.displayName ?? user.email?.split('@')[0] ?? 'Friend';
      });
      try {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        if (userDoc.exists) {
          final data = userDoc.data();
          setState(() {
            _userName = data?['name'] ?? _userName;
          });
        }
      } catch (e) {
        print('Error fetching user name from Firestore: $e');
      }
    }
  }

  Future<void> _fetchEvents() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final records =
          await FirebaseFirestore.instance
              .collection('records')
              .where('userId', isEqualTo: user.uid)
              .get();
      final recordsWithPetNames = await _getPetNames(records.docs);

      final newEvents = _buildEvents(recordsWithPetNames);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _events = newEvents;
            print('Updated events: ${_events.length} dates with events');
          });
        }
      });
    } catch (e) {
      print('Error fetching events: $e');
    }
  }

  Map<DateTime, List<Map<String, dynamic>>> _buildEvents(
    List<Map<String, dynamic>> records,
  ) {
    Map<DateTime, List<Map<String, dynamic>>> events = {};
    for (var record in records) {
      final date = (record['date'] as Timestamp?)?.toDate();
      if (date != null) {
        final dateOnly = DateTime(date.year, date.month, date.day);
        events[dateOnly] ??= [];
        events[dateOnly]!.add(record);
      }
    }
    return events;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 1:
        _showCalendarDialog();
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BlogListScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        break;
    }
  }

  void _toggleRecordsPanel() {
    setState(() {
      _isRecordsPanelVisible = !_isRecordsPanelVisible;
      if (_isRecordsPanelVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _showCalendarDialog() {
    _fetchEvents(); // Fetch events when calendar is clicked
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      pageBuilder:
          (context, animation, secondaryAnimation) => ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            child: CalendarDialog(events: _events),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PetWell', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFe74d3d),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: _toggleRecordsPanel,
          ),
        ],
      ),
      backgroundColor: const Color(0xFFecdaca),
      body: Stack(
        children: [
          user == null
              ? const Center(child: Text('Please sign in'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Section
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFe74d3d), Color(0xFFf1948a)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.pets, color: Colors.white, size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Welcome back,',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  _userName ?? 'Friend',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 30,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // My Pets Section
                    const Text(
                      'My Pets',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 180,
                      child: StreamBuilder<QuerySnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('pets')
                                .where('userId', isEqualTo: user.uid)
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const Text('Error loading pets');
                          }
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final pets =
                              snapshot.data!.docs
                                  .map(
                                    (doc) => Pet.fromFirestore(
                                      doc.data() as Map<String, dynamic>,
                                      doc.id,
                                    ),
                                  )
                                  .toList();

                          if (pets.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('No pets added yet'),
                            );
                          }

                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                            ),
                            itemCount: pets.length + 1,
                            itemBuilder: (context, index) {
                              if (index == pets.length) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder:
                                            (context) => const AddPetDialog(),
                                      );
                                    },
                                    child: Container(
                                      width: 150,
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(
                                            0xFFe74d3d,
                                          ).withOpacity(0.3),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.2),
                                            spreadRadius: 1,
                                            blurRadius: 5,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.add,
                                          color: Color(0xFFe74d3d),
                                          size: 40,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }

                              final pet = pets[index];
                              final petType =
                                  pet.species.toLowerCase() ?? 'unknown';

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              PetDetailsScreen(petId: pet.id),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 150,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                    vertical: 8.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        index % 2 == 0
                                            ? Colors.black
                                            : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.3),
                                        spreadRadius: 2,
                                        blurRadius: 5,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 25,
                                                  backgroundImage:
                                                      (pet.imageUrl != null &&
                                                              pet
                                                                  .imageUrl!
                                                                  .isNotEmpty)
                                                          ? MemoryImage(
                                                                base64Decode(
                                                                  pet.imageUrl!,
                                                                ),
                                                              )
                                                              as ImageProvider
                                                          : const AssetImage(
                                                                'assets/default.jpg',
                                                              )
                                                              as ImageProvider,
                                                  backgroundColor:
                                                      Colors.grey[300],
                                                  onBackgroundImageError:
                                                      (_, __) => const Icon(
                                                        Icons.error,
                                                      ),
                                                ),
                                                const Spacer(),
                                                Icon(
                                                  Icons.pets,
                                                  color:
                                                      index % 2 == 0
                                                          ? Colors.white
                                                          : Colors.black,
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              pet.name,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    index % 2 == 0
                                                        ? Colors.white
                                                        : Colors.black,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              pet.breed ??
                                                  StringExtension(
                                                    petType,
                                                  ).capitalize(),
                                              style: TextStyle(
                                                fontSize: 14,
                                                color:
                                                    index % 2 == 0
                                                        ? Colors.white
                                                            .withOpacity(0.7)
                                                        : Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Featured Posts Section
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
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
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.pets,
                                  color: Color(0xFFe74d3d),
                                  size: 28,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Featured Posts',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 280,
                            child: StreamBuilder<QuerySnapshot>(
                              stream:
                                  FirebaseFirestore.instance
                                      .collection('blogs')
                                      .orderBy('createdAt', descending: true)
                                      .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return const Text(
                                    'Error loading featured posts',
                                  );
                                }
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                final featuredPosts = snapshot.data!.docs;
                                _postCount = featuredPosts.length;
                                if (featuredPosts.isEmpty) {
                                  return const Text('No featured posts yet');
                                }
                                return PageView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  controller: _pageController,
                                  itemCount: featuredPosts.length,
                                  itemBuilder: (
                                    BuildContext context,
                                    int index,
                                  ) {
                                    final post = featuredPosts[index];
                                    final data =
                                        post.data() as Map<String, dynamic>;
                                    return InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => BlogPostScreen(
                                                  blogData: data,
                                                ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 16.0,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(
                                                0xFFecdaca,
                                              ).withOpacity(0.9),
                                              Colors.white,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Color(
                                              0xFFe74d3d,
                                            ).withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.book,
                                                    color: Color(0xFFe74d3d),
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      data['title'],
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 20,
                                                        color: Color(
                                                          0xFF333333,
                                                        ),
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Expanded(
                                                child:
                                                    (data['imageBase64'] !=
                                                                null &&
                                                            data['imageBase64']
                                                                .isNotEmpty)
                                                        ? ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          child: Image.memory(
                                                            base64Decode(
                                                              data['imageBase64'],
                                                            ),
                                                            fit: BoxFit.cover,
                                                            width:
                                                                double.infinity,
                                                            errorBuilder:
                                                                (
                                                                  context,
                                                                  error,
                                                                  stackTrace,
                                                                ) => const Icon(
                                                                  Icons.error,
                                                                  size: 50,
                                                                  color:
                                                                      Colors
                                                                          .grey,
                                                                ),
                                                          ),
                                                        )
                                                        : Container(
                                                          decoration: BoxDecoration(
                                                            color:
                                                                Colors
                                                                    .grey[200],
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                          ),
                                                          child: const Center(
                                                            child: Icon(
                                                              Icons
                                                                  .image_not_supported,
                                                              size: 50,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                          ),
                                                        ),
                                              ),
                                              const SizedBox(height: 10),
                                              Row(
                                                children: [
                                                  Text(
                                                    data['authorName'] ??
                                                        'Unknown',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Color(0xFFe74d3d),
                                                      fontStyle:
                                                          FontStyle.italic,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Icon(
                                                    Icons.pets,
                                                    color: Color(0xFFe74d3d),
                                                    size: 16,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                data['content'] ??
                                                    'No content available',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey,
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
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _postCount,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3.0,
                                ),
                                width: 8.0,
                                height: 8.0,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      _currentPage == index
                                          ? Color(0xFFe74d3d)
                                          : Colors.grey.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Upcoming Reminders Section
                    const Text(
                      'Upcoming Reminders',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('records')
                              .where('userId', isEqualTo: user.uid)
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          print('Error loading reminders: ${snapshot.error}');
                          return const Text('Error loading reminders');
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final records = snapshot.data!.docs;
                        return FutureBuilder<List<Map<String, dynamic>>>(
                          future: _getPetNames(records),
                          builder: (context, petNamesSnapshot) {
                            if (petNamesSnapshot.connectionState !=
                                ConnectionState.done) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (petNamesSnapshot.hasError) {
                              return Text(
                                'Error loading pet names: ${petNamesSnapshot.error}',
                              );
                            }
                            List<Map<String, dynamic>> recordsWithPetNames =
                                petNamesSnapshot.data ?? [];
                            recordsWithPetNames.sort((a, b) {
                              final dateA = (a['date'] as Timestamp?)?.toDate();
                              final dateB = (b['date'] as Timestamp?)?.toDate();
                              if (dateA == null && dateB == null) return 0;
                              if (dateA == null) return 1;
                              if (dateB == null) return -1;
                              return dateA.compareTo(dateB);
                            });
                            if (recordsWithPetNames.isEmpty) {
                              return const Text('No reminders found');
                            }
                            return Column(
                              children:
                                  recordsWithPetNames.map((record) {
                                    return Card(
                                      elevation: 3,
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      color: Colors.white,
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          radius: 25,
                                          backgroundImage:
                                              (record['petImageUrl'] != null &&
                                                      record['petImageUrl']
                                                          .isNotEmpty)
                                                  ? MemoryImage(
                                                        base64Decode(
                                                          record['petImageUrl'],
                                                        ),
                                                      )
                                                      as ImageProvider
                                                  : const AssetImage(
                                                        'assets/default.jpg',
                                                      )
                                                      as ImageProvider,
                                          backgroundColor: Colors.grey[300],
                                          onBackgroundImageError:
                                              (_, __) =>
                                                  const Icon(Icons.error),
                                        ),
                                        title: Text(
                                          "${record['petName'] ?? 'Unknown Pet'} - ${record['type'] ?? 'No Type'}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${record['details'] ?? 'No Details'} on ${(record['date'] as Timestamp?)?.toDate().toString().substring(0, 10) ?? 'No Date'}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Color(0xFFe74d3d),
                                          ),
                                          onPressed:
                                              () =>
                                                  _showDeleteConfirmationDialog(
                                                    context,
                                                    record['recordId'],
                                                  ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
          if (_isRecordsPanelVisible)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.5,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Reminders',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Color(0xFFe74d3d),
                              ),
                              onPressed: _toggleRecordsPanel,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream:
                              FirebaseFirestore.instance
                                  .collection('records')
                                  .where('userId', isEqualTo: user!.uid)
                                  .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return const Text('Error loading records');
                            }
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            final records = snapshot.data!.docs;
                            return FutureBuilder<List<Map<String, dynamic>>>(
                              future: _getPetNames(records),
                              builder: (context, petNamesSnapshot) {
                                if (petNamesSnapshot.connectionState !=
                                    ConnectionState.done) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                if (petNamesSnapshot.hasError) {
                                  return Text(
                                    'Error: ${petNamesSnapshot.error}',
                                  );
                                }
                                List<Map<String, dynamic>> recordsWithPetNames =
                                    petNamesSnapshot.data ?? [];
                                recordsWithPetNames.sort((a, b) {
                                  final dateA =
                                      (a['date'] as Timestamp?)?.toDate();
                                  final dateB =
                                      (b['date'] as Timestamp?)?.toDate();
                                  if (dateA == null && dateB == null) return 0;
                                  if (dateA == null) return 1;
                                  if (dateB == null) return -1;
                                  return dateA.compareTo(dateB);
                                });
                                if (recordsWithPetNames.isEmpty) {
                                  return const Center(
                                    child: Text('No reminders found'),
                                  );
                                }
                                return ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  itemCount: recordsWithPetNames.length,
                                  itemBuilder: (context, index) {
                                    final record = recordsWithPetNames[index];
                                    return Card(
                                      elevation: 2,
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          radius: 30,
                                          backgroundImage:
                                              (record['petImageUrl'] != null &&
                                                      record['petImageUrl']
                                                          .isNotEmpty)
                                                  ? MemoryImage(
                                                        base64Decode(
                                                          record['petImageUrl'],
                                                        ),
                                                      )
                                                      as ImageProvider
                                                  : const AssetImage(
                                                        'assets/default.jpg',
                                                      )
                                                      as ImageProvider,
                                          backgroundColor: Colors.grey[300],
                                          onBackgroundImageError:
                                              (_, __) =>
                                                  const Icon(Icons.error),
                                        ),
                                        title: Text(
                                          "${record['petName'] ?? 'Unknown Pet'} - ${record['type'] ?? 'No Type'}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${record['details'] ?? 'No Details'} on ${(record['date'] as Timestamp?)?.toDate().toString().substring(0, 10) ?? 'No Date'}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Color(0xFFe74d3d),
                                          ),
                                          onPressed:
                                              () =>
                                                  _showDeleteConfirmationDialog(
                                                    context,
                                                    record['recordId'],
                                                  ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Blog'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFFe74d3d),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getPetNames(
    List<QueryDocumentSnapshot> records,
  ) async {
    List<Map<String, dynamic>> recordsWithPetNames = [];
    for (var doc in records) {
      final data = doc.data() as Map<String, dynamic>;
      final petId = data['petId'] as String?;
      String petName = 'Unknown Pet';
      String? petImageUrl;
      if (petId != null) {
        try {
          DocumentSnapshot petSnapshot =
              await FirebaseFirestore.instance
                  .collection('pets')
                  .doc(petId)
                  .get();
          if (petSnapshot.exists) {
            final petData = petSnapshot.data() as Map<String, dynamic>?;
            petName = petData?['name'] as String? ?? 'Unknown Pet';
            petImageUrl = petData?['imageUrl'] as String?;
          }
        } catch (e) {
          print('Error fetching pet name for petId $petId: $e');
        }
      }
      recordsWithPetNames.add({
        ...data,
        'petName': petName,
        'petImageUrl': petImageUrl,
        'recordId': doc.id,
      });
    }
    return recordsWithPetNames;
  }

  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    String recordId,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete this reminder?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Delete',
                style: TextStyle(color: Color(0xFFe74d3d)),
              ),
              onPressed: () {
                _deleteRecord(recordId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteRecord(String recordId) async {
    try {
      await FirebaseFirestore.instance
          .collection('records')
          .doc(recordId)
          .delete();
      print('Record deleted successfully!');
    } catch (e) {
      print('Error deleting record: $e');
    }
  }
}

class CalendarDialog extends StatefulWidget {
  final Map<DateTime, List<Map<String, dynamic>>> events;

  const CalendarDialog({super.key, required this.events});

  @override
  _CalendarDialogState createState() => _CalendarDialogState();
}

class _CalendarDialogState extends State<CalendarDialog> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _showChatbox = false;
  Offset _chatboxPosition = const Offset(50, 50);
  List<Map<String, dynamic>> _chatboxRecords = [];
  Timer? _chatboxTimer;

  @override
  void initState() {
    super.initState();
    print(
      'CalendarDialog initialized with ${widget.events.length} event dates',
    );
  }

  @override
  void dispose() {
    _chatboxTimer?.cancel();
    super.dispose();
  }

  void _showChatboxForDate(
    DateTime date,
    List<Map<String, dynamic>> records,
    Offset tapPosition,
    BoxConstraints dialogConstraints,
  ) {
    final chatboxWidth = 180.0;
    final chatboxHeight = 100.0;
    double adjustedDx = tapPosition.dx;
    double adjustedDy = tapPosition.dy;

    adjustedDx = adjustedDx.clamp(
      0.0,
      dialogConstraints.maxWidth - chatboxWidth,
    );
    adjustedDy = adjustedDy.clamp(
      0.0,
      dialogConstraints.maxHeight - chatboxHeight,
    );

    print(
      'Showing chatbox for date: $date, records: ${records.length}, position: ($adjustedDx, $adjustedDy)',
    );

    setState(() {
      _showChatbox = true;
      _chatboxRecords = records;
      _chatboxPosition = Offset(adjustedDx, adjustedDy);
    });

    _chatboxTimer?.cancel();
    _chatboxTimer = Timer(
      const Duration(seconds: 5),
      () => setState(() {
        _showChatbox = false;
        print('Chatbox auto-dismissed');
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(12.0),
                height: MediaQuery.of(context).size.height * 0.6,
                width: MediaQuery.of(context).size.width * 0.8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFecdaca).withOpacity(0.95), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Calendar',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFe74d3d),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Color(0xFFe74d3d),
                                size: 20,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        Expanded(
                          child: TableCalendar(
                            firstDay: DateTime.utc(2020, 1, 1),
                            lastDay: DateTime.utc(2030, 12, 31),
                            focusedDay: _focusedDay,
                            selectedDayPredicate:
                                (day) => isSameDay(_selectedDay, day),
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                                _showChatbox = false;
                              });
                            },
                            calendarStyle: CalendarStyle(
                              cellMargin: const EdgeInsets.all(2.0),
                              todayDecoration: const BoxDecoration(
                                color: Color(0xFFf1948a),
                                shape: BoxShape.circle,
                              ),
                              selectedDecoration: const BoxDecoration(
                                color: Color(0xFFe74d3d),
                                shape: BoxShape.circle,
                              ),
                              markerDecoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              defaultTextStyle: const TextStyle(
                                color: Color(0xFF333333),
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                              weekendTextStyle: TextStyle(
                                color: const Color(0xFFe74d3d).withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                              outsideTextStyle: TextStyle(
                                color: Colors.grey.withOpacity(0.5),
                                fontSize: 14,
                              ),
                            ),
                            headerStyle: const HeaderStyle(
                              formatButtonVisible: false,
                              titleTextStyle: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                              leftChevronIcon: Icon(
                                Icons.chevron_left,
                                color: Color(0xFFe74d3d),
                                size: 20,
                              ),
                              rightChevronIcon: Icon(
                                Icons.chevron_right,
                                color: Color(0xFFe74d3d),
                                size: 20,
                              ),
                            ),
                            eventLoader: (day) {
                              final dateOnly = DateTime(
                                day.year,
                                day.month,
                                day.day,
                              );
                              final events = widget.events[dateOnly] ?? [];
                              print(
                                'EventLoader for $dateOnly: ${events.length} events',
                              );
                              return events;
                            },
                            calendarBuilders: CalendarBuilders(
                              markerBuilder: (context, date, events) {
                                if (events.isNotEmpty) {
                                  print(
                                    'Marker for $date: ${events.length} events',
                                  );
                                  return Positioned(
                                    right: 2,
                                    bottom: 2,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                      ),
                                      width: 5.0,
                                      height: 5.0,
                                    ),
                                  );
                                }
                                return null;
                              },
                              defaultBuilder: (context, day, focusedDay) {
                                final dateOnly = DateTime(
                                  day.year,
                                  day.month,
                                  day.day,
                                );
                                final events = widget.events[dateOnly] ?? [];
                                if (events.isNotEmpty) {
                                  print(
                                    'Building event day: $dateOnly with ${events.length} events',
                                  );
                                  return GestureDetector(
                                    onTap: () {
                                      final RenderBox box =
                                          context.findRenderObject()
                                              as RenderBox;
                                      final RenderBox dialogBox =
                                          context
                                              .findAncestorRenderObjectOfType<
                                                RenderBox
                                              >()!;
                                      final dialogPosition = dialogBox
                                          .localToGlobal(Offset.zero);
                                      final position = box.localToGlobal(
                                        Offset.zero,
                                      );
                                      final relativePosition = Offset(
                                        position.dx - dialogPosition.dx + 20,
                                        position.dy - dialogPosition.dy + 20,
                                      );
                                      _showChatboxForDate(
                                        dateOnly,
                                        events,
                                        relativePosition,
                                        constraints,
                                      );
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.all(2.0),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFe74d3d,
                                        ).withOpacity(0.8),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${day.day}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                return null;
                              },
                            ),
                            onPageChanged: (focusedDay) {
                              _focusedDay = focusedDay;
                            },
                          ),
                        ),
                      ],
                    ),
                    if (_showChatbox)
                      Positioned(
                        left: _chatboxPosition.dx,
                        top: _chatboxPosition.dy,
                        child: GestureDetector(
                          onTap:
                              () => setState(() {
                                _showChatbox = false;
                                _chatboxTimer?.cancel();
                                print('Chatbox dismissed by tap');
                              }),
                          child: Material(
                            color: Colors.transparent,
                            child: Stack(
                              children: [
                                Container(
                                  width: 180,
                                  constraints: const BoxConstraints(
                                    maxHeight: 200,
                                  ),
                                  padding: const EdgeInsets.all(10.0),
                                  margin: const EdgeInsets.only(bottom: 8.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFe74d3d),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.2),
                                        spreadRadius: 1,
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child:
                                      _chatboxRecords.isEmpty
                                          ? Text(
                                            'No records available',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          )
                                          : SingleChildScrollView(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children:
                                                  _chatboxRecords.asMap().entries.map((
                                                    entry,
                                                  ) {
                                                    final index = entry.key;
                                                    final record = entry.value;
                                                    return Padding(
                                                      padding: EdgeInsets.only(
                                                        bottom:
                                                            index <
                                                                    _chatboxRecords
                                                                            .length -
                                                                        1
                                                                ? 6.0
                                                                : 0,
                                                      ),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            'Pet: ${record['petName'] ?? 'Unknown'}',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 13,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Color(
                                                                    0xFF333333,
                                                                  ),
                                                                ),
                                                          ),
                                                          Text(
                                                            'Type: ${record['type'] ?? 'No Type'}',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 12,
                                                                  color: Color(
                                                                    0xFFe74d3d,
                                                                  ),
                                                                ),
                                                          ),
                                                          Text(
                                                            'Details: ${record['details'] ?? 'No Details'}',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color:
                                                                  Colors
                                                                      .grey[600],
                                                            ),
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }).toList(),
                                            ),
                                          ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 20,
                                  child: CustomPaint(
                                    size: Size(10, 6),
                                    painter: _CloudTailPainter(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CloudTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFFe74d3d)
          ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
