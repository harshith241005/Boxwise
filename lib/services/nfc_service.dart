import 'package:flutter/material.dart';

class NfcService {
  static Future<bool> isAvailable() async {
    // In a real app, use nfc_manager
    return true; 
  }

  static Future<String?> startSession() async {
    // Simulate NFC Scanning
    await Future.delayed(const Duration(seconds: 2));
    return "NFC-TAG-8829-XJ"; // Mock Tag ID
  }

  static Future<bool> writeTag(String data) async {
    // Simulate NFC Writing
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }
}

class NfcSheet extends StatefulWidget {
  final bool isWriting;
  final String? dataToWrite;
  
  const NfcSheet({super.key, this.isWriting = false, this.dataToWrite});

  @override
  State<NfcSheet> createState() => _NfcSheetState();
}

class _NfcSheetState extends State<NfcSheet> {
  bool _isScanning = true;
  bool _isSuccess = false;
  String? _scannedId;

  @override
  void initState() {
    super.initState();
    _handleNfc();
  }

  Future<void> _handleNfc() async {
    if (widget.isWriting) {
      final success = await NfcService.writeTag(widget.dataToWrite ?? "");
      if (mounted) {
        setState(() {
          _isScanning = false;
          _isSuccess = success;
        });
      }
    } else {
      final id = await NfcService.startSession();
      if (mounted) {
        setState(() {
          _isScanning = false;
          _scannedId = id;
          _isSuccess = id != null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 32),
          
          if (_isScanning) ...[
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 24),
            Text(widget.isWriting ? 'Ready to Write NFC Tag' : 'Ready to Scan NFC Tag', 
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Hold your phone near the NFC label', style: TextStyle(color: Colors.white54)),
          ] else if (_isSuccess) ...[
            const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 64),
            const SizedBox(height: 24),
            Text(widget.isWriting ? 'Tag Written Successfully!' : 'Tag Scanned: $_scannedId', 
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, _scannedId),
              child: const Text('Done'),
            ),
          ] else ...[
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 64),
            const SizedBox(height: 24),
            const Text('NFC Error', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(color: Colors.white54))),
          ],
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
