import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/content_frame.dart';
import '../../../core/widgets/status_chip.dart';
import '../../products/domain/product.dart';
import '../domain/diagnosis.dart';

class DiagnosisScreen extends ConsumerStatefulWidget {
  const DiagnosisScreen({required this.productId, super.key});

  final String productId;

  @override
  ConsumerState<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends ConsumerState<DiagnosisScreen> {
  final _formKey = GlobalKey<FormState>();
  final _symptomsController = TextEditingController();
  XFile? _image;
  Uint8List? _imageBytes;
  String? _imageMimeType;
  Diagnosis? _result;
  var _analyzing = false;
  var _creatingRepair = false;

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await ImagePicker().pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (image == null) return;
    final mimeType = _mimeTypeFor(image);
    if (mimeType == null) {
      _showMessage('Choose a JPEG or PNG image.');
      return;
    }
    final bytes = await image.readAsBytes();
    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      _showMessage('Choose an image smaller than 5 MB.');
      return;
    }
    if (!mounted) return;
    setState(() {
      _image = image;
      _imageBytes = bytes;
      _imageMimeType = mimeType;
    });
  }

  Future<void> _analyze(Product product) async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authUserProvider).asData?.value;
    if (user == null) {
      _showMessage('Sign in again before submitting an assessment.');
      return;
    }
    setState(() {
      _analyzing = true;
      _result = null;
    });
    try {
      final result = await ref.read(diagnosisServiceProvider).analyze(
            product: product,
            symptoms: _symptomsController.text,
            imageBytes: _imageBytes,
            imageMimeType: _imageMimeType,
          );
      if (mounted) setState(() => _result = result);
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  String? _mimeTypeFor(XFile image) {
    final declaredType = image.mimeType;
    if (declaredType == 'image/png' || declaredType == 'image/jpeg') {
      return declaredType;
    }
    final fileName = image.name.toLowerCase();
    if (fileName.endsWith('.png')) return 'image/png';
    if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    return null;
  }

  Future<void> _requestRepair() async {
    final diagnosis = _result;
    if (diagnosis == null) return;
    setState(() => _creatingRepair = true);
    try {
      final repairId = await ref.read(repairRepositoryProvider).createRequest(
            productId: widget.productId,
            diagnosisId: diagnosis.id,
            issueSummary: diagnosis.possibleIssue,
          );
      if (mounted) context.go('/repairs/$repairId');
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _creatingRepair = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('AI-assisted assessment')),
        body: ContentFrame(
          child: AsyncValueView(
            value: ref.watch(productProvider(widget.productId)),
            data: (product) => product == null
                ? const Center(child: Text('Product not found.'))
                : _buildForm(context, product),
          ),
        ),
      );

  Widget _buildForm(BuildContext context, Product product) => ListView(
        children: [
          Text('Describe the fault', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            '${product.brand} ${product.model} • ${product.passportId}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          const _SafetyNotice(),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Symptoms', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _symptomsController,
                      minLines: 5,
                      maxLines: 8,
                      maxLength: 1500,
                      decoration: const InputDecoration(
                        hintText:
                            'Explain when the issue started, what you observe, and any recent damage or repair.',
                      ),
                      validator: (value) => value == null || value.trim().length < 15
                          ? 'Provide at least 15 characters of symptom detail'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Product or damage image',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_imageBytes != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _imageBytes!,
                          width: double.infinity,
                          height: 210,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Text(
                      'The image is sent inline through Firebase AI Logic and '
                      'is not uploaded to Firebase Storage.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.photo_camera_outlined, size: 18),
                          label: const Text('Use camera'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.image_outlined, size: 18),
                          label: const Text('Choose image'),
                        ),
                        if (_image != null)
                          TextButton(
                            onPressed: () => setState(() {
                              _image = null;
                              _imageBytes = null;
                              _imageMimeType = null;
                            }),
                            child: const Text('Remove'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed:
                            _analyzing ? null : () => _analyze(product),
                        icon: const Icon(Icons.fact_check_outlined, size: 18),
                        label: Text(
                          _analyzing ? 'Analyzing securely…' : 'Analyze symptoms',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 18),
            _ResultCard(
              diagnosis: _result!,
              creatingRepair: _creatingRepair,
              onRequestRepair: _requestRepair,
              canRequestRepair: !_result!.id.startsWith('preview-'),
            ),
          ],
          const SizedBox(height: 28),
        ],
      );
}

class _SafetyNotice extends StatelessWidget {
  const _SafetyNotice();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6E5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE7C46A)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.health_and_safety_outlined, color: Color(0xFF8A5B00)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '${AppConstants.aiDisclaimer} Do not open high-voltage products or '
                'handle swollen, hot or damaged batteries. Use professional service '
                'for potentially dangerous faults.',
                style: TextStyle(color: Color(0xFF6B4A05), height: 1.45),
              ),
            ),
          ],
        ),
      );
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.diagnosis,
    required this.creatingRepair,
    required this.onRequestRepair,
    required this.canRequestRepair,
  });

  final Diagnosis diagnosis;
  final bool creatingRepair;
  final VoidCallback onRequestRepair;
  final bool canRequestRepair;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Preliminary assessment',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  StatusChip(
                    diagnosis.severity.name.toUpperCase(),
                    tone: diagnosis.severity == DiagnosisSeverity.high
                        ? StatusTone.danger
                        : diagnosis.severity == DiagnosisSeverity.medium
                            ? StatusTone.warning
                            : StatusTone.success,
                  ),
                ],
              ),
              const Divider(height: 28),
              _ResultField(label: 'Possible issue', value: diagnosis.possibleIssue),
              _ResultField(
                label: 'Confidence',
                value: '${(diagnosis.confidence * 100).round()}%',
              ),
              _ResultField(
                label: 'Why this may fit',
                value: diagnosis.reasoningSummary,
              ),
              Text('Recommended checks', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...diagnosis.recommendedChecks.map(
                (check) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(check)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _ResultField(
                label: 'Recommended action',
                value: diagnosis.recommendedAction,
              ),
              _ResultField(
                label: 'Service guidance',
                value: diagnosis.professionalServiceRecommended
                    ? 'Professional service is recommended.'
                    : 'Try the non-invasive checks first and monitor the issue.',
              ),
              if (diagnosis.safetyWarning.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE9E7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    diagnosis.safetyWarning,
                    style: const TextStyle(
                      color: Color(0xFF8F1D16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              if (canRequestRepair)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: creatingRepair ? null : onRequestRepair,
                    icon: const Icon(Icons.build_outlined, size: 18),
                    label: Text(
                      creatingRepair
                          ? 'Creating repair request…'
                          : 'Request technician repair',
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'This live Spark-plan assessment is not yet saved to the '
                    'repair history. Technician requests remain disabled until '
                    'the secure server workflow is deployed.',
                  ),
                ),
            ],
          ),
        ),
      );
}

class _ResultField extends StatelessWidget {
  const _ResultField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
}
