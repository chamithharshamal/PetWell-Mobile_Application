import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:cross_file/cross_file.dart';
import 'pet_model.dart';

class PetRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? 'anonymous';

  CollectionReference get _petsCollection =>
      _firestore.collection('users').doc(_userId).collection('pets');

  // Add new pet
  Future<String> addPet(
    Pet pet,
    XFile imageFile,
    List<XFile> medicalFiles,
  ) async {
    try {
      final imageUrl = await _uploadFile(imageFile, 'pet_images');

      final medicalUrls = <String>[];
      for (var file in medicalFiles) {
        medicalUrls.add(await _uploadFile(file, 'medical_records'));
      }

      final savedPet = Pet(
        name: pet.name,
        ageMonths: pet.ageMonths,
        petType: pet.petType,
        breed: pet.breed,
        weight: pet.weight,
        imageUrl: imageUrl,
        medicalRecordUrls: medicalUrls,
      );

      final doc = await _petsCollection.add(savedPet.toMap());
      return doc.id;
    } catch (e) {
      throw Exception('Failed to add pet: $e');
    }
  }

  // Upload a single file
  Future<String> _uploadFile(XFile file, String folder) async {
    try {
      final fileName = '${const Uuid().v4()}_${DateTime.now().millisecondsSinceEpoch}';
      final ref = _storage.ref().child('$_userId/$folder/$fileName');

      final data = await file.readAsBytes();
      final snapshot = await ref.putData(
        data,
        SettableMetadata(contentType: file.mimeType),
      );
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  // Stream all pets
  Stream<List<Pet>> getPets() => _petsCollection.snapshots().map((snap) {
        return snap.docs
            .map((d) => Pet.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList();
      });

  // Get a single pet
  Future<Pet?> getPetById(String petId) async {
    final doc = await _petsCollection.doc(petId).get();
    if (doc.exists) {
      return Pet.fromMap(doc.data()! as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // Update pet
  Future<void> updatePet(
    Pet pet, {
    XFile? newImageFile,
    List<XFile> newMedicalFiles = const [],
  }) async {
    try {
      String? newImageUrl;
      if (newImageFile != null) {
        newImageUrl = await _uploadFile(newImageFile, 'pet_images');
      }

      final newMedicalUrls = <String>[];
      for (var file in newMedicalFiles) {
        newMedicalUrls.add(await _uploadFile(file, 'medical_records'));
      }

      final updatedData = pet.toMap();
      if (newImageUrl != null) {
        updatedData['imageUrl'] = newImageUrl;
      }
      if (newMedicalUrls.isNotEmpty) {
        updatedData['medicalRecordUrls'] = newMedicalUrls;
      }

      await _petsCollection.doc(pet.id).update(updatedData);
    } catch (e) {
      throw Exception('Failed to update pet: $e');
    }
  }

  // Delete pet
  Future<void> deletePet(String petId) async {
    await _petsCollection.doc(petId).delete();
  }
}
