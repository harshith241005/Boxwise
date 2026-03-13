import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/box_model.dart';
import '../theme/app_theme.dart';

class QrCodeScreen extends StatelessWidget {
  final BoxModel box;
  const QrCodeScreen({super.key, required this.box});

  @override
  Widget build(BuildContext context) {
    final color = Color(box.colorValue ?? AppTheme.primaryColor.value);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Box Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.inventory_2_rounded, color: color, size: 40),
              ),
              const SizedBox(height: 16),
              Text(box.name?.toString() ?? 'Unnamed Box', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.location_on_outlined, size: 14, color: isDark ? Colors.white54 : Colors.black54),
                const SizedBox(width: 4),
                Text(box.location?.toString() ?? 'Unknown', style: TextStyle(fontSize: 14, color: isDark ? Colors.white54 : Colors.black54)),
              ]),
              const SizedBox(height: 32),

              // QR Code Card
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(color: color.withAlpha(51), blurRadius: 30, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: 'Boxvise:${box.uuid}',
                      version: QrVersions.auto,
                      size: 220,
                      eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: color),
                      dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: const Color(0xFF1A1A2E)),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5FA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        box.uuid?.substring(0, 8).toUpperCase() ?? '',
                        style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E), letterSpacing: 1.5, fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Info text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(13),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryColor.withAlpha(38)),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor.withAlpha(179), size: 22),
                  const SizedBox(width: 12),
                  Expanded(child: Text(
                    'Print this QR code and stick it on the physical box for quick scanning.',
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54, height: 1.4),
                  )),
                ]),
              ),
              const SizedBox(height: 20),

              // Items summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(13) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(13)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Box Contents', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87)),
                  const SizedBox(height: 8),
                  Text('${box.items.length} items · ${box.totalQuantity} total quantity',
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.black38),
                  ),
                  if (box.items.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 6, children: (box.items ?? []).where((i) => i != null).take(5).map((item) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: color.withAlpha(26), borderRadius: BorderRadius.circular(8)),
                      child: Text(item.name?.toString() ?? '', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
                    )).toList()),
                    if (box.items.length > 5) Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('+${box.items.length - 5} more', style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38)),
                    ),
                  ],
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
