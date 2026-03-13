import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';
import '../models/box_model.dart';

class QrSheetScreen extends StatefulWidget {
  const QrSheetScreen({super.key});

  @override
  State<QrSheetScreen> createState() => _QrSheetScreenState();
}

class _QrSheetScreenState extends State<QrSheetScreen> {
  int _currentPage = 0;
  final int _pageSize = 10;
  bool _printMode = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, provider, _) {
        final allBoxes = provider.boxes;
        final totalPages = (allBoxes.length / _pageSize).ceil();
        
        final startIndex = _currentPage * _pageSize;
        final endIndex = (startIndex + _pageSize < allBoxes.length) 
            ? startIndex + _pageSize 
            : allBoxes.length;
            
        final currentPageBoxes = allBoxes.isEmpty 
            ? <BoxModel>[] 
            : allBoxes.sublist(startIndex, endIndex);

        return Scaffold(
          appBar: _printMode ? null : AppBar(
            title: const Text('QR Label Sheets', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: Icon(_printMode ? Icons.edit_note_rounded : Icons.print_rounded),
                tooltip: _printMode ? 'Exit Print Preview' : 'Print Mode',
                onPressed: () => setState(() => _printMode = !_printMode),
              ),
              if (currentPageBoxes.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.download_rounded),
                  tooltip: 'Download PDF',
                  onPressed: () => _generatePdf(currentPageBoxes),
                ),
            ],
          ),
          body: allBoxes.isEmpty 
              ? _buildEmptyState() 
              : Column(
                  children: [
                    if (!_printMode) Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Showing ${startIndex + 1} - $endIndex of ${allBoxes.length} boxes',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: EdgeInsets.all(_printMode ? 10 : 16),
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: currentPageBoxes.length,
                        itemBuilder: (context, index) {
                          final box = currentPageBoxes[index];
                          return _buildQrTile(box);
                        },
                      ),
                    ),
                    if (!_printMode && totalPages > 1) _buildPagination(totalPages),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code_2_rounded, size: 80, color: Colors.grey.withAlpha(50)),
          const SizedBox(height: 16),
          const Text('No boxes available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text('Create a box to generate QR labels', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildQrTile(BoxModel box) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withAlpha(30)),
        boxShadow: _printMode ? null : [
          BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            box.name ?? 'Unnamed',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          QrImageView(
            data: 'Boxvise:${box.uuid}',
            version: QrVersions.auto,
            size: 80,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 4),
          Text(
            (box.uuid ?? '').substring(0, 8).toUpperCase(),
            style: const TextStyle(fontSize: 8, color: Colors.grey, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(26), blurRadius: 10, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
          ),
          const SizedBox(width: 16),
          ...List.generate(totalPages, (index) {
            final isSelected = index == _currentPage;
            return GestureDetector(
              onTap: () => setState(() => _currentPage = index),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
          ),
        ],
      ),
    );
  }

  Future<void> _generatePdf(List<BoxModel> boxes) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Boxvise QR Labels - Page ${_currentPage + 1}', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              pw.GridView(
                crossAxisCount: 3,
                childAspectRatio: 0.8,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: boxes.map((box) {
                  return pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text(box.name ?? 'Unnamed', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                        pw.SizedBox(height: 5),
                        pw.BarcodeWidget(
                          barcode: pw.Barcode.qrCode(),
                          data: 'Boxvise:${box.uuid}',
                          width: 80,
                          height: 80,
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text((box.uuid ?? '').substring(0, 8).toUpperCase(), style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
