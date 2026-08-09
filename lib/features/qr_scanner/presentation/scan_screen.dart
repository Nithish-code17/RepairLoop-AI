import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/content_frame.dart';
import '../../../core/widgets/page_header.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final _manualController = TextEditingController();
  final _scannerController = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  var _processing = false;

  @override
  void dispose() {
    _manualController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleCapture(BarcodeCapture capture) async {
    if (_processing || capture.barcodes.isEmpty) return;
    final value = capture.barcodes.first.rawValue;
    if (value == null || value.isEmpty) return;
    await _openPassport(value);
  }

  Future<void> _openPassport(String scannedValue) async {
    setState(() => _processing = true);
    try {
      final passportId = scannedValue
          .replaceFirst('repairloop://passport/', '')
          .trim()
          .toUpperCase();
      final productId = await ref
          .read(productRepositoryProvider)
          .findProductIdByPassport(passportId);
      if (!mounted) return;
      if (productId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No RepairLoop passport matched this code.')),
        );
      } else {
        await _scannerController.stop();
        if (mounted) context.push('/passport/$productId');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) => ContentFrame(
        child: ListView(
          children: [
            const PageHeader(
              title: 'Scan product passport',
              description: 'Open a verified device record using its RepairLoop QR code.',
            ),
            const SizedBox(height: 22),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 1.18,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            MobileScanner(
                              controller: _scannerController,
                              onDetect: _handleCapture,
                            ),
                            Center(
                              child: Container(
                                width: 210,
                                height: 210,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white, width: 3),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                            if (_processing)
                              const ColoredBox(
                                color: Color(0x88000000),
                                child: Center(
                                  child: CircularProgressIndicator(color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Enter passport ID manually',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _manualController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                hintText: 'RLP-DL-000001',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              onSubmitted: _openPassport,
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _processing
                                  ? null
                                  : () => _openPassport(_manualController.text),
                              child: const Text('Open passport'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
}
