import 'package:cloud_firestore/cloud_firestore.dart';

class Record {
  final String id;
  final String userId;
  final String petId;
  final String type;
  final String details;
  final DateTime date;
  final DateTime createdAt;

  Record({
    required this.id,
    required this.userId,
    required this.petId,
    required this.type,
    required this.details,
    required this.date,
    required this.createdAt,
  });

  factory Record.fromFirestore(Map<String, dynamic> data, String id) {
    return Record(
      id: id,
      userId: data['userId'],
      petId: data['petId'],
      type: data['type'],
      details: data['details'],
      date: (data['date'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'petId': petId,
      'type': type,
      'details': details,
      'date': Timestamp.fromDate(date),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}