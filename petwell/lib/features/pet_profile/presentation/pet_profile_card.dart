import 'package:flutter/material.dart';
import '../data/pet_model.dart';
import '../logic/pet_controller.dart';

class PetProfileCard extends StatelessWidget {
  final Pet pet;
  
  const PetProfileCard({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    Map<String, int> ageMap = PetController.calculateYearsAndMonths(pet.ageMonths);
    int years = ageMap['years']!;
    int months = ageMap['months']!;
    
    String ageText = '';
    if (years > 0) {
      ageText += '$years year${years > 1 ? 's' : ''}';
    }
    if (months > 0) {
      if (ageText.isNotEmpty) ageText += ' ';
      ageText += '$months month${months > 1 ? 's' : ''}';
    }
    if (ageText.isEmpty) {
      ageText = 'Less than 1 month';
    }
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          if (pet.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.network(
                pet.imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 180,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 180,
                    color: Colors.grey[200],
                    child: const Icon(Icons.error, size: 50),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        pet.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECDACA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        pet.petType.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE74D3D),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (pet.breed.isNotEmpty) Text('Breed: ${pet.breed}'),
                const SizedBox(height: 4),
                Text('Age: $ageText'),
                if (pet.weight > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Weight: ${pet.weight} kg'),
                  ),
                if (pet.medicalRecordUrls.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.file_present, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${pet.medicalRecordUrls.length} medical record${pet.medicalRecordUrls.length > 1 ? 's' : ''}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}