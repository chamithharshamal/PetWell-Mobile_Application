import 'package:cloud_firestore/cloud_firestore.dart';

class Pet {
  final String? id;
  final String name;
  final int ageMonths;
  final String petType; // 'cat' or 'dog'
  final String breed;
  final double weight;
  final String imageUrl;
  final List<String> medicalRecordUrls;
  final DateTime createdAt;
  
  Pet({
    this.id,
    required this.name,
    required this.ageMonths,
    required this.petType,
    required this.breed,
    this.weight = 0.0,
    required this.imageUrl,
    this.medicalRecordUrls = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ageMonths': ageMonths,
      'petType': petType,
      'breed': breed,
      'weight': weight,
      'imageUrl': imageUrl,
      'medicalRecordUrls': medicalRecordUrls,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
  
  factory Pet.fromMap(Map<String, dynamic> map, String id) {
    return Pet(
      id: id,
      name: map['name'] ?? '',
      ageMonths: map['ageMonths'] ?? 0,
      petType: map['petType'] ?? 'dog',
      breed: map['breed'] ?? '',
      weight: (map['weight'] ?? 0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      medicalRecordUrls: List<String>.from(map['medicalRecordUrls'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}