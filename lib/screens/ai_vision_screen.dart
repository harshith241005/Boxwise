import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class AiVisionScreen extends StatefulWidget {
  const AiVisionScreen({super.key});

  @override
  State<AiVisionScreen> createState() => _AiVisionScreenState();
}

class _AiVisionScreenState extends State<AiVisionScreen> {
  XFile? _image;
  bool _isProcessing = false;
  List<String> _detectedItems = [];

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _image = image;
        _isProcessing = true;
      });
      // Simulate AI Processing
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _isProcessing = false;
        _detectedItems = ['Hammer', 'Screwdriver Set', 'Wrench', 'Power Drill']; // Mock results
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boxvise Vision', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_image == null) ...[
              const Spacer(),
              const Icon(Icons.psychology_outlined, size: 80, color: AppTheme.primaryColor),
              const SizedBox(height: 24),
              const Text(
                'Intelligent Object Recognition',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Point your camera at items to automatically categorize and add them to your inventory.',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text('Scan with Vision AI'),
                ),
              ),
            ] else ...[
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(File(_image!.path), fit: BoxFit.cover),
                      if (_isProcessing)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: AppTheme.primaryColor),
                                SizedBox(height: 16),
                                Text('Analyzing items...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      if (!_isProcessing && _detectedItems.isNotEmpty)
                        Positioned(
                          bottom: 20, left: 20, right: 20,
                          child: GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Detected Results', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  children: _detectedItems.map((item) => Chip(
                                    label: Text(item, style: const TextStyle(fontSize: 12)),
                                    backgroundColor: AppTheme.primaryColor.withAlpha(26),
                                    side: BorderSide.none,
                                  )).toList(),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => setState(() => _image = null),
                                        child: const Text('Retake'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          // Logic to add multiple items
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Add All'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
