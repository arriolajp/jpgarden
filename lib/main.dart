import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  File? _image;
  String _plantName = '';
  bool _isLoading = false;

  // Function to pick an image from gallery or camera
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      _identifyPlant();
    }
  }

  // Function to call the Plant.id API and identify the plant
  Future<void> _identifyPlant() async {
    if (_image == null) return;

    setState(() {
      _isLoading = true;
    });

    final Uri url = Uri.parse('https://api.plant.id/v2/identify');
    final String apiKey = 'your_plant_id_api_key'; // Add your Plant.id API Key here

    final request = http.MultipartRequest('POST', url)
      ..headers['Api-Key'] = apiKey
      ..files.add(await http.MultipartFile.fromPath('image', _image!.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final Map<String, dynamic> data = json.decode(responseData);

      if (data['suggestions'] != null && data['suggestions'].isNotEmpty) {
        setState(() {
          _plantName = data['suggestions'][0]['plant']['scientific_name'];
        });
      } else {
        setState(() {
          _plantName = 'Could not identify the plant.';
        });
      }
    } else {
      setState(() {
        _plantName = 'Error: Unable to connect to the API.';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green[800],
          title: const Text('jpgarden'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _isLoading
                  ? CircularProgressIndicator()
                  : _image != null
                      ? Image.file(_image!)
                      : Text('No image selected'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Pick an Image'),
              ),
              SizedBox(height: 20),
              Text(
                _plantName.isEmpty ? 'Plant Information' : _plantName,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
