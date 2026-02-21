import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/polling_station.dart';
import '../../models/violation_type.dart';
import '../../models/incident_report.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('election_violations.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE polling_station (
        station_id INTEGER PRIMARY KEY,
        station_name TEXT NOT NULL,
        zone TEXT NOT NULL,
        province TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE violation_type (
        type_id INTEGER PRIMARY KEY,
        type_name TEXT NOT NULL,
        severity TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE incident_report (
        report_id INTEGER PRIMARY KEY AUTOINCREMENT,
        station_id INTEGER NOT NULL,
        type_id INTEGER NOT NULL,
        reporter_name TEXT NOT NULL,
        description TEXT,
        evidence_photo TEXT,
        timestamp TEXT NOT NULL,
        ai_result TEXT,
        ai_confidence REAL DEFAULT 0.0,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (station_id) REFERENCES polling_station(station_id),
        FOREIGN KEY (type_id) REFERENCES violation_type(type_id)
      )
    ''');

    await _insertSeedData(db);
  }

  Future _insertSeedData(Database db) async {
    final stations = [
      {
        'station_id': 101,
        'station_name': 'โรงเรียนวัดพระมหาธาตุ',
        'zone': 'เขต 1',
        'province': 'นครศรีธรรมราช',
      },
      {
        'station_id': 102,
        'station_name': 'เต็นท์หน้าตลาดท่าวัง',
        'zone': 'เขต 1',
        'province': 'นครศรีธรรมราช',
      },
      {
        'station_id': 103,
        'station_name': 'ศาลากลางหมู่บ้านคีรีวง',
        'zone': 'เขต 2',
        'province': 'นครศรีธรรมราช',
      },
      {
        'station_id': 104,
        'station_name': 'หอประชุมอำเภอทุ่งสง',
        'zone': 'เขต 3',
        'province': 'นครศรีธรรมราช',
      },
    ];
    for (var s in stations) {
      await db.insert('polling_station', s);
    }

    final types = [
      {
        'type_id': 1,
        'type_name': 'ซื้อสิทธิ์ขายเสียง (Buying Votes)',
        'severity': 'High',
      },
      {
        'type_id': 2,
        'type_name': 'ขนคนไปลงคะแนน (Transportation)',
        'severity': 'High',
      },
      {
        'type_id': 3,
        'type_name': 'หาเสียงเกินเวลา (Overtime Campaign)',
        'severity': 'Medium',
      },
      {
        'type_id': 4,
        'type_name': 'ทำลายป้ายหาเสียง (Vandalism)',
        'severity': 'Low',
      },
      {
        'type_id': 5,
        'type_name': 'เจ้าหน้าที่วางตัวไม่เป็นกลาง (Bias Official)',
        'severity': 'High',
      },
    ];
    for (var t in types) {
      await db.insert('violation_type', t);
    }

    final reports = [
      {
        'station_id': 101,
        'type_id': 1,
        'reporter_name': 'พลเมืองดี 01',
        'description': 'พบเห็นการแจกเงินบริเวณหน้าหน่วย',
        'evidence_photo': null,
        'timestamp': '2026-02-08 09:30:00',
        'ai_result': 'Money',
        'ai_confidence': 0.95,
        'synced': 0,
      },
      {
        'station_id': 102,
        'type_id': 3,
        'reporter_name': 'สมชาย ใจกล้า',
        'description': 'มีการเปิดรถแห่เสียงดังรบกวน',
        'evidence_photo': null,
        'timestamp': '2026-02-08 10:15:00',
        'ai_result': 'Crowd',
        'ai_confidence': 0.75,
        'synced': 0,
      },
      {
        'station_id': 103,
        'type_id': 5,
        'reporter_name': 'Anonymous',
        'description': 'เจ้าหน้าที่พูดจาชี้นำผู้ลงคะแนน',
        'evidence_photo': null,
        'timestamp': '2026-02-08 11:00:00',
        'ai_result': null,
        'ai_confidence': 0.0,
        'synced': 0,
      },
    ];
    for (var r in reports) {
      await db.insert('incident_report', r);
    }
  }

  Future<List<PollingStation>> getAllStations() async {
    final db = await database;
    final result = await db.query('polling_station');
    return result.map((e) => PollingStation.fromMap(e)).toList();
  }

  Future<PollingStation?> getStation(int id) async {
    final db = await database;
    final result = await db.query(
      'polling_station',
      where: 'station_id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return PollingStation.fromMap(result.first);
  }

  Future<List<ViolationType>> getAllViolationTypes() async {
    final db = await database;
    final result = await db.query('violation_type');
    return result.map((e) => ViolationType.fromMap(e)).toList();
  }

  Future<int> insertReport(IncidentReport report) async {
    final db = await database;
    return await db.insert('incident_report', report.toMap());
  }

  Future<List<IncidentReport>> getAllReports() async {
    final db = await database;
    final result = await db.query('incident_report', orderBy: 'timestamp DESC');
    return result.map((e) => IncidentReport.fromMap(e)).toList();
  }

  Future<List<IncidentReport>> getUnsyncedReports() async {
    final db = await database;
    final result = await db.query(
      'incident_report',
      where: 'synced = ?',
      whereArgs: [0],
    );
    return result.map((e) => IncidentReport.fromMap(e)).toList();
  }

  Future<int> updateReport(IncidentReport report) async {
    final db = await database;
    return await db.update(
      'incident_report',
      report.toMap(),
      where: 'report_id = ?',
      whereArgs: [report.reportId],
    );
  }

  Future<int> deleteReport(int reportId) async {
    final db = await database;
    return await db.delete(
      'incident_report',
      where: 'report_id = ?',
      whereArgs: [reportId],
    );
  }

  Future<void> markSynced(int reportId) async {
    final db = await database;
    await db.update(
      'incident_report',
      {'synced': 1},
      where: 'report_id = ?',
      whereArgs: [reportId],
    );
  }

  Future<Map<String, int>> getStatsSummary() async {
    final db = await database;
    final total =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM incident_report'),
        ) ??
        0;
    final high =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM incident_report ir JOIN violation_type vt ON ir.type_id = vt.type_id WHERE vt.severity = "High"',
          ),
        ) ??
        0;
    final unsynced =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM incident_report WHERE synced = 0',
          ),
        ) ??
        0;
    return {'total': total, 'high': high, 'unsynced': unsynced};
  }
}
