import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';


import '../logic/pet_controller.dart';

class PetFormScreen extends StatefulWidget {
  const PetFormScreen({super.key});

  @override
  State<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends State<PetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  String _petType = 'dog';
  int _years = 0;
  int _months = 0;
  XFile? _petImage;
  List<XFile> _medicalRecords = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _petImage = image;
      });
    }
  }

  Future<void> _pickMedicalRecords() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result != null) {
      setState(() {
        _medicalRecords = result.files
            .where((file) => file.bytes != null)
            .map((file) => XFile.fromData(
                  file.bytes!,
                  name: file.name,
                  mimeType: file.extension,
                ))
            .toList();
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate() && _petImage != null) {
      setState(() {
        _isLoading = true;
      });

      final controller = Provider.of<PetController>(context, listen: false);

      double weight = 0.0;
      if (_weightController.text.isNotEmpty) {
        weight = double.tryParse(_weightController.text) ?? 0.0;
      }

      int totalMonths = PetController.calculateAgeInMonths(_years, _months);

      bool success = await controller.addPet(
        _nameController.text.trim(),
        totalMonths,
        _petType,
        _breedController.text.trim(),
        weight,
        _petImage!,
        _medicalRecords,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (success) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(controller.errorMessage)),
        );
      }
    } else if (_petImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pet image')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                const Text(
                  'Add Pet Profile',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Pet Image
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFECDACA),
                        shape: BoxShape.circle,
                        image: _petImage != null
                            ? DecorationImage(
                                image: Image.network(_petImage!.path).image,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _petImage == null
                          ? const Icon(Icons.add_a_photo, size: 40, color: Color(0xFFE74D3D))
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                const Text('Pet Photo*', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                const SizedBox(height: 20),

                // Pet Type
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Pet Type:'),
                    const SizedBox(width: 20),
                    ChoiceChip(
                      label: const Text('Dog'),
                      selected: _petType == 'dog',
                      selectedColor: const Color(0xFFE74D3D).withAlpha(179),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _petType = 'dog');
                        }
                      },
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('Cat'),
                      selected: _petType == 'cat',
                      selectedColor: const Color(0xFFE74D3D).withAlpha(179),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _petType = 'cat');
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Pet Name*',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your pet name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Age
                Row(
                  children: [
                    const Text('Age*:'),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              decoration: const InputDecoration(labelText: 'Years', border: OutlineInputBorder()),
                              value: _years,
                              items: List.generate(21, (i) => i)
                                  .map((value) => DropdownMenuItem(value: value, child: Text('$value')))
                                  .toList(),
                              onChanged: (value) => setState(() => _years = value!),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              decoration: const InputDecoration(labelText: 'Months', border: OutlineInputBorder()),
                              value: _months,
                              items: List.generate(12, (i) => i)
                                  .map((value) => DropdownMenuItem(value: value, child: Text('$value')))
                                  .toList(),
                              onChanged: (value) => setState(() => _months = value!),
                              validator: (value) {
                                if (_years == 0 && (value == null || value == 0)) {
                                  return 'Please enter age';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Breed
                TextFormField(
                  controller: _breedController,
                  decoration: const InputDecoration(
                    labelText: 'Breed',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // Weight
                TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),

                // Medical Records
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFECDACA),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: _pickMedicalRecords,
                  icon: const Icon(Icons.upload_file),
                  label: Text(_medicalRecords.isEmpty
                      ? 'Upload Medical Records'
                      : '${_medicalRecords.length} files selected'),
                ),
                const SizedBox(height: 30),

                // Submit Button
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE74D3D),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: _isLoading ? null : _submitForm,
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              ),
                              SizedBox(width: 10),
                              Text('Adding...', style: TextStyle(fontSize: 16, color: Colors.white)),
                            ],
                          )
                        : const Text('Add Pet', style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
