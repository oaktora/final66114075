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
    final medium =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM incident_report ir JOIN violation_type vt ON ir.type_id = vt.type_id WHERE vt.severity = "Medium"',
          ),
        ) ??
        0;
    return {'total': total, 'high': high, 'medium': medium};
  }

  Future<List<Map<String, dynamic>>> getTop3Stations() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT ps.station_name, COUNT(ir.report_id) as incident_count
      FROM polling_station ps
      LEFT JOIN incident_report ir ON ps.station_id = ir.station_id
      GROUP BY ps.station_id
      ORDER BY incident_count DESC
      LIMIT 3
    ''');
  }

  Future<bool> checkDuplicateStation(int id, String name) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM polling_station WHERE station_name = ? AND station_id != ?',
      [name, id],
    );
    final count = Sqflite.firstIntValue(result) ?? 0;
    return count > 0;
  }

  Future<int> countIncidentsByStation(int id) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM incident_report WHERE station_id = ?',
      [id],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> updateStation(PollingStation station) async {
    final db = await database;
    return await db.update(
      'polling_station',
      station.toMap(),
      where: 'station_id = ?',
      whereArgs: [station.stationId],
    );
  }

  Future<List<Map<String, dynamic>>> getReportsWithDetails() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT ir.*, ps.station_name, vt.type_name, vt.severity
      FROM incident_report ir
      JOIN polling_station ps ON ir.station_id = ps.station_id
      JOIN violation_type vt ON ir.type_id = vt.type_id
      ORDER BY ir.timestamp DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> searchOfflineReports(
    String query,
    String filterSeverity,
  ) async {
    final db = await database;
    String sql = '''
      SELECT ir.*, ps.station_name, vt.type_name, vt.severity
      FROM incident_report ir
      JOIN polling_station ps ON ir.station_id = ps.station_id
      JOIN violation_type vt ON ir.type_id = vt.type_id
      WHERE 1=1
    ''';
    List<dynamic> args = [];

    if (query.isNotEmpty) {
      sql += ' AND ir.reporter_name LIKE ?';
      final likeStr = '%$query%';
      args.add(likeStr);
    }

    if (filterSeverity.isNotEmpty && filterSeverity != 'All') {
      sql += ' AND vt.severity = ?';
      args.add(filterSeverity);
    }

    sql += ' ORDER BY ir.timestamp DESC';
    return await db.rawQuery(sql, args);
  }
}
