import 'dart:io';

import 'package:paddle_score_app/utils/GlobalFunction.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseManager {
  static Future<Database> getDatabase(String dbName) async {
    print("获取数据库：$dbName");
    String path = await getFilePath("$dbName.db");
    return await openDatabase(
      path,
      onCreate: (db, version) async {
        /// 初始化数据库基本信息
        /// 包括：运动员信息表，长距离比赛表，进度表
        print("数据库不存在，创建数据库：$path");
        await initAthleteTable(db);
        await db.execute('''
        CREATE TABLE 'progress' (
          progress_name VARCHAR(255) PRIMARY KEY,
          progress_value INT DEFAULT 0,
          description VARCHAR(255)
        );
        ''');
        db.insert('progress', {
          'progress_name': 'athlete_imported',
          'progress_value': 0,
          'description': '运动员信息是否导入，新建比赛后变为1'
        });
        db.insert('progress', {
          'progress_name': 'long_distance_downloaded',
          'progress_value': 0,
          'description': '长距离比赛成绩单是否下载，下载长距离比赛成绩后变为1'
        });
        db.insert('progress', {
          'progress_name': 'long_distance_imported',
          'progress_value': 0,
          'description': '长距离比赛成绩是否导入，导入长距离比赛成绩后变为1'
        });

      },
      version: 1,
    );
  }

  static Future<void> initAthleteTable(Database db) async {
    const sql = '''
    CREATE TABLE athletes (
    id INT PRIMARY KEY,
    name VARCHAR(255),
    team VARCHAR(255),
    division VARCHAR(255),
    long_distance_score INT,
    prone_paddle_score INT,
    sprint_score INT,
    technical_score INT
);
    ''';
    await db.execute(sql);
    await initLongDistantTable(db);
  }

  // 插入长距离的具体实现在读取Excel的时已经完成
  static Future<void> initLongDistantTable(Database db) async {
    await db.execute('''
        CREATE TABLE '长距离比赛' (
          id INT PRIMARY KEY,
          name VARCHAR(255),
          time VARCHAR(255),
          long_distant_rank INT
);
      ''');
  }

  // 获取所有数据表的表名
  static Future<List<String>> getTableNames(Database db) {
    return db
        .rawQuery("SELECT name FROM sqlite_master WHERE type='table'")
        .then((tables) => tables.map((row) => row['name'] as String).toList());
  }

  static Future<void> deleteDatabase(String dbName) async {
    String path = await getFilePath("$dbName.db");
    await File(path).delete();
  }
}
