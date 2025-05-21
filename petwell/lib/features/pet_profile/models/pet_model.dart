import 'package:cloud_firestore/cloud_firestore.dart';

class Pet {
  final String id;
  final String userId;
  final String name;
  final String species;
  final String? breed;
  final int age;
  final String? imageUrl;
  final DateTime createdAt;

  Pet({
    required this.id,
    required this.userId,
    required this.name,
    required this.species,
    this.breed,
    required this.age,
    this.imageUrl,
    required this.createdAt,
  });

  factory Pet.fromFirestore(Map<String, dynamic> data, String id) {
    return Pet(
      id: id,
      userId: data['userId'],
      name: data['name'],
      species: data['species'],
      breed: data['breed'],
      age: data['age'],
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'species': species,
      'breed': breed,
      'age': age,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
