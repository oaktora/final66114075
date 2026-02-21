class IncidentReport {
  final int? reportId;
  final int stationId;
  final int typeId;
  final String reporterName;
  final String? description;
  final String? evidencePhoto;
  final String timestamp;
  final String? aiResult;
  final double aiConfidence;
  final int synced;

  IncidentReport({
    this.reportId,
    required this.stationId,
    required this.typeId,
    required this.reporterName,
    this.description,
    this.evidencePhoto,
    required this.timestamp,
    this.aiResult,
    this.aiConfidence = 0.0,
    this.synced = 0,
  });

  factory IncidentReport.fromMap(Map<String, dynamic> map) {
    return IncidentReport(
      reportId: map['report_id'],
      stationId: map['station_id'],
      typeId: map['type_id'],
      reporterName: map['reporter_name'],
      description: map['description'],
      evidencePhoto: map['evidence_photo'],
      timestamp: map['timestamp'],
      aiResult: map['ai_result'],
      aiConfidence: (map['ai_confidence'] as num?)?.toDouble() ?? 0.0,
      synced: map['synced'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
      'station_id': stationId,
      'type_id': typeId,
      'reporter_name': reporterName,
      'description': description,
      'evidence_photo': evidencePhoto,
      'timestamp': timestamp,
      'ai_result': aiResult,
      'ai_confidence': aiConfidence,
      'synced': synced,
    };
    if (reportId != null) m['report_id'] = reportId;
    return m;
  }

  IncidentReport copyWith({
    int? reportId,
    int? stationId,
    int? typeId,
    String? reporterName,
    String? description,
    String? evidencePhoto,
    String? timestamp,
    String? aiResult,
    double? aiConfidence,
    int? synced,
  }) {
    return IncidentReport(
      reportId: reportId ?? this.reportId,
      stationId: stationId ?? this.stationId,
      typeId: typeId ?? this.typeId,
      reporterName: reporterName ?? this.reporterName,
      description: description ?? this.description,
      evidencePhoto: evidencePhoto ?? this.evidencePhoto,
      timestamp: timestamp ?? this.timestamp,
      aiResult: aiResult ?? this.aiResult,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      synced: synced ?? this.synced,
    );
  }
}
