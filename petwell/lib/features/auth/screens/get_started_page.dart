import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'signin_screen.dart';

class GetStartedPage extends StatefulWidget {
  const GetStartedPage({super.key});

  @override
  _GetStartedPageState createState() => _GetStartedPageState();
}

class _GetStartedPageState extends State<GetStartedPage> {
  int _currentSlide = 0;

  final List<Map<String, String>> slides = [
    {
      'image': 'assets/images/slide1.jpg', // Replace with your image path
      'title': 'Track Health Records',
      'description': 'Easily monitor your pet’s health with detailed records.',
    },
    {
      'image': 'assets/images/slide2.jpg', // Replace with your image path
      'title': 'Set Reminders',
      'description': 'Never miss a vet visit or medication with timely reminders.',
    },
    {
      'image': 'assets/images/slide3.jpg', // Replace with your image path
      'title': 'Insightful Graphs',
      'description': 'Visualize your pet’s weight history with clear graphs.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFe74d3d), Color(0xFFc0392b)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Get Started with PetCare',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: CarouselSlider.builder(
                  itemCount: slides.length,
                  itemBuilder: (context, index, realIndex) {
                    final slide = slides[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.asset(
                              slide['image']!,
                              fit: BoxFit.cover,
                              height: 200,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 200,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(
                                    Icons.pets,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            slide['title']!,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            slide['description']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  options: CarouselOptions(
                    height: 400,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 3),
                    enlargeCenterPage: true,
                    onPageChanged: (index, reason) {
                      setState(() {
                        _currentSlide = index;
                      });
                    },
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: slides.asMap().entries.map((entry) {
                  return Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentSlide == entry.key
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignInScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFe74d3d),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text('Sign In'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}