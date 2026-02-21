import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../helpers/tflite_helper.dart';
import '../../constants/app_theme.dart';
import 'add_report_screen.dart';

class AiScanScreen extends StatefulWidget {
  const AiScanScreen({super.key});

  @override
  State<AiScanScreen> createState() => _AiScanScreenState();
}

class _AiScanScreenState extends State<AiScanScreen> {
  String? _imagePath;
  String? _label;
  double _confidence = 0.0;
  bool _analyzing = false;

  static const _labelDesc = {
    'Money': 'ตรวจพบภาพที่เกี่ยวข้องกับเงิน อาจเป็นการแจกเงินซื้อเสียง',
    'Crowd': 'ตรวจพบฝูงชนที่อาจถูกขนมา หรือกลุ่มชุมนุมผิดกฎหมาย',
    'Poster': 'ตรวจพบป้ายหาเสียงที่อาจผิดกฎระเบียบ',
    'Normal': 'ไม่พบสิ่งผิดปกติในภาพนี้',
  };

  Future<void> _pickAndAnalyze(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;
    setState(() {
      _imagePath = picked.path;
      _label = null;
      _analyzing = true;
    });
    final result = await TfliteHelper.instance.classify(picked.path);
    setState(() {
      _label = result?.label ?? 'ไม่สามารถวิเคราะห์ได้';
      _confidence = result?.confidence ?? 0.0;
      _analyzing = false;
    });
  }

  Color get _resultColor {
    switch (_label) {
      case 'Money':
        return AppColors.accent;
      case 'Crowd':
        return AppColors.warning;
      case 'Poster':
        return AppColors.medSeverity;
      case 'Normal':
        return AppColors.success;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สแกนภาพด้วย AI')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showPickOptions(),
              child: Container(
                width: double.infinity,
                height: 260,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _imagePath == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 56,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'แตะเพื่อเลือกหรือถ่ายภาพ',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(File(_imagePath!), fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickAndAnalyze(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('ถ่ายภาพ'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickAndAnalyze(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('อัลบั้ม'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_analyzing)
              Column(
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text(
                    'AI กำลังวิเคราะห์ภาพ...',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ],
              )
            else if (_label != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _resultColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _resultColor.withOpacity(0.4)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.label_important_outline,
                          color: _resultColor,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'ผลการวิเคราะห์',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _label!,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: _resultColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _confidence,
                        minHeight: 10,
                        color: _resultColor,
                        backgroundColor: _resultColor.withOpacity(0.2),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ความมั่นใจ ${(_confidence * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: _resultColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _labelDesc[_label] ?? '',
                      style: const TextStyle(color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_label != 'Normal')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddReportScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.report_problem_outlined),
                    label: const Text(
                      'แจ้งเหตุจากภาพนี้',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPickOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.primary,
              ),
              title: const Text('ถ่ายภาพ'),
              onTap: () {
                Navigator.pop(context);
                _pickAndAnalyze(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.primary,
              ),
              title: const Text('เลือกจากอัลบั้ม'),
              onTap: () {
                Navigator.pop(context);
                _pickAndAnalyze(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
