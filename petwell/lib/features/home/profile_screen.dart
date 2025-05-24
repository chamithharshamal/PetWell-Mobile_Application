import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../pets_profile/models/pet_model.dart';
import '../pets_profile/screens/pet_details_screen.dart';
import '../pets_profile/screens/add_pet_dialog.dart';

// String extension to add capitalize method
extension StringCasingExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _userName;
  String? _userEmail;
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = true;

  // App color scheme
  final Color primaryColor = const Color(0xFFe74d3d);
  final Color secondaryColor = const Color(0xFFf1948a);
  final Color backgroundColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserDetails() async {
    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userName = user.displayName ?? user.email?.split('@')[0] ?? 'Friend';
        _userEmail = user.email ?? 'No Email';
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
        print('Error fetching user details from Firestore: $e');
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _updateUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': _nameController.text,
        }, SetOptions(merge: true));
        await user.updateDisplayName(_nameController.text);
        setState(() {
          _userName = _nameController.text;
        });
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Name updated successfully!'),
            backgroundColor: primaryColor,
          ),
        );
      } catch (e) {
        print('Error updating user name: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating name: $e')));
      }
    }
  }

  Future<void> _showUpdateNameDialog() async {
    _nameController.text = _userName ?? '';
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Update Name', style: TextStyle(color: primaryColor)),
          content: TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _updateUserName,
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updatePet(Pet pet) async {
    final TextEditingController nameController = TextEditingController(
      text: pet.name,
    );
    final TextEditingController breedController = TextEditingController(
      text: pet.breed,
    );
    final TextEditingController speciesController = TextEditingController(
      text: pet.species,
    );

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Update Pet Details',
            style: TextStyle(color: primaryColor),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Pet Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: breedController,
                  decoration: InputDecoration(
                    labelText: 'Breed',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: speciesController,
                  decoration: InputDecoration(
                    labelText: 'Species',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                ),
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Update'),
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('pets')
                      .doc(pet.id)
                      .update({
                        'name': nameController.text,
                        'breed': breedController.text,
                        'species': speciesController.text,
                      });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Pet details updated successfully!'),
                      backgroundColor: primaryColor,
                    ),
                  );
                  setState(() {}); // Refresh pet list
                } catch (e) {
                  print('Error updating pet: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating pet: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showHelpAndSupportDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Help & Support', style: TextStyle(color: primaryColor)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How can we help?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),
                Text(
                  'If you need assistance with your account or have questions about our services, please reach out to our support team:',
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.email, color: primaryColor),
                  title: Text('Email Support'),
                  subtitle: Text('support@petapp.com'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.phone, color: primaryColor),
                  title: Text('Phone Support'),
                  subtitle: Text('(555) 123-4567'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.chat_bubble_outline, color: primaryColor),
                  title: Text('Live Chat'),
                  subtitle: Text('Available Monday-Friday, 9am-5pm'),
                ),
                const SizedBox(height: 16),
                Text(
                  'FAQ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  '• How do I add a new pet to my profile?\n'
                  '• How can I update my pet\'s information?\n'
                  '• Is my data secure and private?\n'
                  '• How do I reset my password?\n',
                ),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showTermsAndConditionsDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Terms & Conditions',
            style: TextStyle(color: primaryColor),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Terms of Service',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Last Updated: May 10, 2025\n\n'
                  'Please read these Terms of Service carefully before using our app. By accessing or using our app, you agree to be bound by these Terms.\n\n'
                  '1. ACCEPTANCE OF TERMS\n\n'
                  'By creating an account or accessing or using our services, you acknowledge that you have read, understood, and agree to be bound by these Terms.\n\n'
                  '2. PRIVACY POLICY\n\n'
                  'Your use of our services is also subject to our Privacy Policy, which is incorporated by reference into these Terms.\n\n'
                  '3. USER ACCOUNTS\n\n'
                  'To use certain features of our services, you may be required to create an account. You are responsible for maintaining the confidentiality of your account credentials.\n\n'
                  '4. USER CONTENT\n\n'
                  'You retain all rights to your content that you upload, post, or otherwise make available through our services.',
                ),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPrivacyPolicyDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Privacy Policy', style: TextStyle(color: primaryColor)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Policy',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Last Updated: May 10, 2025\n\n'
                  'This Privacy Policy describes how we collect, use, and share your personal information when you use our app.\n\n'
                  '1. INFORMATION WE COLLECT\n\n'
                  'We collect information that you provide directly to us, such as when you create an account, update your profile, or add information about your pets.\n\n'
                  '2. HOW WE USE YOUR INFORMATION\n\n'
                  'We use the information we collect to provide, maintain, and improve our services, to communicate with you, and to personalize your experience.\n\n'
                  '3. INFORMATION SHARING\n\n'
                  'We do not share your personal information with third parties except as described in this Privacy Policy.\n\n'
                  '4. DATA SECURITY\n\n'
                  'We take reasonable measures to help protect your personal information from loss, theft, misuse, and unauthorized access.',
                ),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAboutAppDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('About the App', style: TextStyle(color: primaryColor)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Icon(Icons.pets, size: 64, color: primaryColor)),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Pet Care App',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Version 1.2.0',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'About Us',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pet Care App is designed to help pet owners manage their pets\' health, schedule, and care needs. Our mission is to improve the well-being of pets by providing owners with the tools they need to provide the best care possible.\n\n'
                  'Developed with love by pet enthusiasts for pet owners worldwide.',
                ),
                const SizedBox(height: 16),
                Text(
                  'Contact Us',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Email: info@petapp.com\n'
                  'Website: www.petapp.com\n'
                  'Phone: (555) 987-6543',
                ),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigate to login screen and remove all previous routes
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/signin', (route) => false);
    } catch (e) {
      print('Error during logout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: backgroundColor,
      body:
          user == null
              ? Center(
                child: Text(
                  'Please sign in',
                  style: TextStyle(color: primaryColor, fontSize: 18),
                ),
              )
              : _isLoading
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 120,
                    backgroundColor: backgroundColor,
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        'My Profile',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      centerTitle: false,
                      titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User profile card
                          Container(
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundColor: secondaryColor.withOpacity(
                                      0.2,
                                    ),
                                    child: Text(
                                      _userName
                                              ?.substring(0, 1)
                                              .toUpperCase() ??
                                          'U',
                                      style: TextStyle(
                                        fontSize: 30,
                                        color: primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _userName ?? 'User',
                                                style: const TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.edit,
                                                color: primaryColor,
                                                size: 20,
                                              ),
                                              onPressed: _showUpdateNameDialog,
                                              constraints:
                                                  const BoxConstraints(),
                                              padding: EdgeInsets.zero,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _userEmail ?? 'No email',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // My Pets section
                          Text(
                            'My Pets',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Pet cards section
                          StreamBuilder<QuerySnapshot>(
                            stream:
                                FirebaseFirestore.instance
                                    .collection('pets')
                                    .where('userId', isEqualTo: user.uid)
                                    .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Text(
                                  'Error loading pets',
                                  style: TextStyle(color: Colors.grey[600]),
                                );
                              }

                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return SizedBox(
                                  height: 220,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: primaryColor,
                                    ),
                                  ),
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
                                return Container(
                                  height: 200,
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.pets,
                                        size: 60,
                                        color: secondaryColor.withOpacity(0.7),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No pets added yet',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryColor,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 12,
                                          ),
                                        ),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder:
                                                (context) =>
                                                    const AddPetDialog(),
                                          );
                                        },
                                        child: const Text('Add a Pet'),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              // Horizontal scrolling pet cards
                              return SizedBox(
                                height: 220,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount:
                                      pets.length +
                                      1, // +1 for the "Add Pet" card
                                  itemBuilder: (context, index) {
                                    // Last card is "Add Pet"
                                    if (index == pets.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 16,
                                        ),
                                        child: GestureDetector(
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder:
                                                  (context) =>
                                                      const AddPetDialog(),
                                            );
                                          },
                                          child: Container(
                                            width: 160,
                                            margin: const EdgeInsets.only(
                                              right: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                              border: Border.all(
                                                color: secondaryColor
                                                    .withOpacity(0.3),
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey
                                                      .withOpacity(0.1),
                                                  spreadRadius: 1,
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                CircleAvatar(
                                                  radius: 28,
                                                  backgroundColor:
                                                      secondaryColor
                                                          .withOpacity(0.2),
                                                  child: Icon(
                                                    Icons.add,
                                                    size: 30,
                                                    color: primaryColor,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  'Add Pet',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: primaryColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    // Pet cards
                                    final pet = pets[index];

                                    return Padding(
                                      padding: const EdgeInsets.only(right: 16),
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) => PetDetailsScreen(
                                                    petId: pet.id,
                                                  ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          width: 160,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey.withOpacity(
                                                  0.1,
                                                ),
                                                spreadRadius: 1,
                                                blurRadius: 10,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Pet image
                                              Expanded(
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        const BorderRadius.only(
                                                          topLeft:
                                                              Radius.circular(
                                                                24,
                                                              ),
                                                          topRight:
                                                              Radius.circular(
                                                                24,
                                                              ),
                                                        ),
                                                    image: DecorationImage(
                                                      image:
                                                          (pet.imageUrl !=
                                                                      null &&
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
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              // Pet info
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            pet.name,
                                                            style: const TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        ),
                                                        GestureDetector(
                                                          onTap:
                                                              () => _updatePet(
                                                                pet,
                                                              ),
                                                          child: Icon(
                                                            Icons.edit_outlined,
                                                            color: primaryColor,
                                                            size: 16,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '${pet.species} · ${pet.breed ?? 'Unknown'}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
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
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 32),

                          // Settings section
                          Text(
                            'Settings',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Settings options
                          Container(
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: Icon(
                                    Icons.help_outline,
                                    color: primaryColor,
                                  ),
                                  title: const Text('Help & Support'),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.grey[400],
                                  ),
                                  onTap: _showHelpAndSupportDialog,
                                ),
                                Divider(height: 1, color: Colors.grey[200]),
                                ListTile(
                                  leading: Icon(
                                    Icons.description_outlined,
                                    color: primaryColor,
                                  ),
                                  title: const Text('Terms & Conditions'),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.grey[400],
                                  ),
                                  onTap: _showTermsAndConditionsDialog,
                                ),
                                Divider(height: 1, color: Colors.grey[200]),
                                ListTile(
                                  leading: Icon(
                                    Icons.privacy_tip_outlined,
                                    color: primaryColor,
                                  ),
                                  title: const Text('Privacy Policy'),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.grey[400],
                                  ),
                                  onTap: _showPrivacyPolicyDialog,
                                ),
                                Divider(height: 1, color: Colors.grey[200]),
                                ListTile(
                                  leading: Icon(
                                    Icons.info_outline,
                                    color: primaryColor,
                                  ),
                                  title: const Text('About the App'),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.grey[400],
                                  ),
                                  onTap: _showAboutAppDialog,
                                ),

                                Divider(height: 1, color: Colors.grey[200]),
                                ListTile(
                                  leading: Icon(
                                    Icons.logout,
                                    color: primaryColor,
                                  ),
                                  title: const Text('Logout'),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.grey[400],
                                  ),
                                  onTap: _logout,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
