import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/pet_controller.dart';
import 'add_pet_button.dart';
import 'pet_profile_card.dart';

class PetsListScreen extends StatefulWidget {
  // Using super parameter for key
  const PetsListScreen({super.key});
  
  @override
  State<PetsListScreen> createState() => _PetsListScreenState();
}

class _PetsListScreenState extends State<PetsListScreen> {
  @override
  void initState() {
    super.initState();
    // Load pets when screen initializes
    // Fixed BuildContext across async gap issue by using a proper late initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PetController>(context, listen: false).loadPets();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Pets',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFE74D3D),
      ),
      body: Consumer<PetController>(
        builder: (context, controller, child) {
          final pets = controller.pets;
          
          if (pets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.pets,
                    size: 80,
                    color: Color(0xFFECDACA),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No pets added yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first pet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: pets.length,
            itemBuilder: (context, index) {
              return PetProfileCard(pet: pets[index]);
            },
          );
        },
      ),
      floatingActionButton: const AddPetButton(),
    );
  }
}