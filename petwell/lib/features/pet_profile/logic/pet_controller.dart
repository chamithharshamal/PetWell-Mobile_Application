import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';
import '../data/pet_model.dart';
import '../data/pet_repository.dart';

enum PetFormStatus { initial, loading, success, error }

class PetController extends ChangeNotifier {
  final PetRepository _repository = PetRepository();

  PetFormStatus _status = PetFormStatus.initial;
  String _errorMessage = '';
  List<Pet> _pets = [];

  PetFormStatus get status => _status;
  String get errorMessage => _errorMessage;
  List<Pet> get pets => _pets;

  // Add a pet
  Future<bool> addPet(
    String name,
    int ageMonths,
    String petType,
    String breed,
    double weight,
    XFile imageFile,
    List<XFile> medicalFiles,
  ) async {
    _status = PetFormStatus.loading;
    notifyListeners();

    try {
      final newPet = Pet(
        name: name,
        ageMonths: ageMonths,
        petType: petType,
        breed: breed,
        weight: weight,
        imageUrl: '',
      );

      await _repository.addPet(newPet, imageFile, medicalFiles);

      _status = PetFormStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _status = PetFormStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update a pet
  Future<bool> updatePet(
    String id,
    String name,
    int ageMonths,
    String petType,
    String breed,
    double weight, {
    XFile? newImageFile,
    List<XFile> newMedicalFiles = const [],
  }) async {
    _status = PetFormStatus.loading;
    notifyListeners();

    try {
      final updatedPet = Pet(
        id: id,
        name: name,
        ageMonths: ageMonths,
        petType: petType,
        breed: breed,
        weight: weight,
        imageUrl: '',
      );

      await _repository.updatePet(
        updatedPet,
        newImageFile: newImageFile,
        newMedicalFiles: newMedicalFiles,
      );

      _status = PetFormStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _status = PetFormStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Load all pets
  Future<void> loadPets() async {
    _repository.getPets().listen((petsList) {
      _pets = petsList;
      notifyListeners();
    });
  }

  // Helpers for age conversion
  static int calculateAgeInMonths(int years, int months) {
    return years * 12 + months;
  }

  static Map<String, int> calculateYearsAndMonths(int totalMonths) {
    final years = totalMonths ~/ 12;
    final months = totalMonths % 12;
    return {'years': years, 'months': months};
  }
}
