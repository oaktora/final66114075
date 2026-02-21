import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../helpers/database_helper.dart';
import '../helpers/firebase_helper.dart';
import '../helpers/tflite_helper.dart';
import '../../models/incident_report.dart';
import '../../models/polling_station.dart';
import '../../models/violation_type.dart';
import '../../constants/app_theme.dart';

class AddReportScreen extends StatefulWidget {
  const AddReportScreen({super.key});

  @override
  State<AddReportScreen> createState() => _AddReportScreenState();
}

class _AddReportScreenState extends State<AddReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  List<PollingStation> _stations = [];
  List<ViolationType> _types = [];
  PollingStation? _selectedStation;
  ViolationType? _selectedType;
  String? _imagePath;
  String? _aiResult;
  double _aiConf = 0.0;
  bool _analyzing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDropdowns() async {
    final stations = await DatabaseHelper.instance.getAllStations();
    final types = await DatabaseHelper.instance.getAllViolationTypes();
    setState(() {
      _stations = stations;
      _types = types;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;
    setState(() {
      _imagePath = picked.path;
      _aiResult = null;
      _aiConf = 0.0;
    });
    _analyzeImage(picked.path);
  }

  Future<void> _analyzeImage(String path) async {
    setState(() => _analyzing = true);
    final result = await TfliteHelper.instance.classify(path);
    setState(() {
      _aiResult = result?.label;
      _aiConf = result?.confidence ?? 0.0;
      _analyzing = false;
    });
  }

  String _pad(int v) => v.toString().padLeft(2, '0');

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStation == null || _selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกหน่วยเลือกตั้งและประเภทความผิด'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final now = DateTime.now();
    final ts =
        '${now.year}-${_pad(now.month)}-${_pad(now.day)} ${_pad(now.hour)}:${_pad(now.minute)}:${_pad(now.second)}';

    final report = IncidentReport(
      stationId: _selectedStation!.stationId,
      typeId: _selectedType!.typeId,
      reporterName: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      evidencePhoto: _imagePath,
      timestamp: ts,
      aiResult: _aiResult,
      aiConfidence: _aiConf,
      synced: 0,
    );

    final id = await DatabaseHelper.instance.insertReport(report);

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity != ConnectivityResult.none) {
      try {
        final saved = report.copyWith(reportId: id);
        await FirebaseHelper.instance.pushReport(saved);
        await DatabaseHelper.instance.markSynced(id);
      } catch (_) {}
    }

    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('บันทึกรายงานเรียบร้อยแล้ว'),
            ],
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('แจ้งเหตุทุจริต')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Label('ชื่อผู้แจ้งเหตุ'),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'ชื่อ-นามสกุล หรือ Anonymous',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'กรุณากรอกชื่อ' : null,
              ),
              const SizedBox(height: 16),
              _Label('หน่วยเลือกตั้ง'),
              DropdownButtonFormField<PollingStation>(
                value: _selectedStation,
                isExpanded: true,
                decoration: const InputDecoration(
                  hintText: 'เลือกหน่วยเลือกตั้ง',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                items: _stations
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(
                          '${s.stationId} - ${s.stationName}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedStation = v),
                validator: (v) => v == null ? 'กรุณาเลือกหน่วย' : null,
              ),
              const SizedBox(height: 16),
              _Label('ประเภทความผิด'),
              DropdownButtonFormField<ViolationType>(
                value: _selectedType,
                isExpanded: true,
                decoration: const InputDecoration(
                  hintText: 'เลือกประเภท',
                  prefixIcon: Icon(Icons.warning_amber_outlined),
                ),
                style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                items: _types
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: severityColor(t.severity),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                t.typeName,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedType = v),
                validator: (v) => v == null ? 'กรุณาเลือกประเภท' : null,
              ),
              const SizedBox(height: 16),
              _Label('รายละเอียดเพิ่มเติม (ไม่บังคับ)'),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'อธิบายเหตุการณ์โดยละเอียด...',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.notes),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _Label('หลักฐานภาพ (ไม่บังคับ)'),
              if (_imagePath == null)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('ถ่ายภาพ'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('อัปโหลด'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_imagePath!),
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _imagePath = null;
                              _aiResult = null;
                            }),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_analyzing)
                      Row(
                        children: const [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'AI กำลังวิเคราะห์ภาพ...',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ],
                      )
                    else if (_aiResult != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34C759).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF34C759).withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.psychology,
                              color: Color(0xFF34C759),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'AI ตรวจพบ: $_aiResult (${(_aiConf * 100).toStringAsFixed(0)}%)',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF34C759),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    _saving ? 'กำลังบันทึก...' : 'ส่งรายงาน',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
    );
  }
}
