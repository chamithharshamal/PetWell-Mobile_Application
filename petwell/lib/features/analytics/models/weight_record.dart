import 'package:cloud_firestore/cloud_firestore.dart';

class WeightRecord {
  final String id;
  final String userId;
  final String petId;
  final double weight;
  final DateTime date;
  final DateTime createdAt;

  WeightRecord({
    required this.id,
    required this.userId,
    required this.petId,
    required this.weight,
    required this.date,
    required this.createdAt,
  });

  factory WeightRecord.fromFirestore(Map<String, dynamic> data, String id) {
    return WeightRecord(
      id: id,
      userId: data['userId'],
      petId: data['petId'],
      weight: data['weight'].toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'petId': petId,
      'weight': weight,
      'date': date,
      'createdAt': createdAt,
    };
  }
}
