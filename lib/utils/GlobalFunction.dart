import 'dart:core';
import 'dart:io';

import 'package:paddle_score_app/utils/DatabaseManager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

const isDebugMode = true;

Future<String> getFilePath(String? fileName) async {
  final directory = await getApplicationDocumentsDirectory();
// 若PaddleScoreData文件夹不存在，则创建
  final path = p.join(directory.path, "PaddleScoreData");
  final dir = Directory(path);
  if (!dir.existsSync()) {
    dir.createSync();
  }
  if (fileName == null) {
    return path;
  }
  return '$path/$fileName';
}

Future<List<String>> getDivisions(String dbName) async {
  Database db = await DatabaseManager.getDatabase(dbName);
  List<Map<String, dynamic>> maps =
      await db.rawQuery('SELECT DISTINCT division FROM athletes');
  var result = maps.map((map) => map['division'] as String).toList();
  printDebug(result);
  return result;
}

enum CType { pronePaddle, sprint }

String cTypeTranslate(CType c) {
  if (c == CType.pronePaddle) {
    return "趴板";
  } else if (c == CType.sprint) {
    return "竞速";
  } else {
    throw "传入错误的比赛类型";
  }
}

enum SType { firstRound, roundOf16, quarterfinals, semifinals, finals }

/// 获取当前组别的运动员总数
/// - [division] 组别名称
/// 输出：
/// {total: xx,raceCount: x}
Future<int> getAthleteCountByDivision(
    String raceEventName, String divisionName) async {
  Database db = await DatabaseManager.getDatabase(raceEventName);
  List<Map<String, dynamic>> result = await db.rawQuery(
    'SELECT COUNT(*) FROM athletes WHERE division = ? ',
    [divisionName],
  );
  return Sqflite.firstIntValue(result) ?? 0;
}

/// 通过运动员数量获取比赛数
/// - [athleteCount] 运动员数量
int getRaceCountByAthleteCount(int athleteCount) {
  if (athleteCount <= 16) {
    return 1;
  } else if (athleteCount > 16 && athleteCount <= 64) {
    return 2;
  } else if (athleteCount > 64 && athleteCount <= 128) {
    return 3;
  } else {
    return 4;
  }
}

String sTypeTranslate(SType s) {
  if (s == SType.firstRound) {
    return "初赛";
  } else if (s == SType.roundOf16) {
    return "八分之一决赛";
  } else if (s == SType.quarterfinals) {
    return "四分之一决赛";
  } else if (s == SType.semifinals) {
    return "二分之一决赛";
  } else if (s == SType.finals) {
    return "决赛";
  } else {
    throw "传入错误的比赛类型";
  }
}

enum WType { dynamic, static }

String wTypeTranslate(WType w) {
  if (w == WType.dynamic) {
    return "静水";
  } else if (w == WType.static) {
    return "动水";
  } else {
    throw "传入错误的水域类型";
  }
}

/// 这个地方是一个线头，未来可以实现让用户自定义黑名单
const List<String> divisionBlackList = ['仅团体', '接力赛', '龙板'];

int getGroupNum(int personNum) {
  var groupNum = (personNum / 16).ceil();
  while (groupNum != 1 &&
      groupNum != 2 &&
      groupNum != 4 &&
      groupNum != 8 &&
      groupNum != 16) {
    groupNum++;
  }
  return groupNum;
}

// From rank to score
int rankToScore(int rank) {
  int score = 0;
  if (rank < 17) {
    switch (rank) {
      case 1:
        score = 1000;
        break;
      case 2:
        score = 860;
        break;
      case 3:
        score = 730;
        break;
      case 4:
        score = 670;
        break;
      case 5:
        score = 610;
        break;
      case 6:
        score = 583;
        break;
      case 7:
        score = 555;
        break;
      case 8:
        score = 528;
        break;
      case 9:
        score = 500;
        break;
      case 10:
        score = 488;
        break;
      case 11:
        score = 475;
        break;
      case 12:
        score = 462;
        break;
      case 13:
        score = 450;
        break;
      case 14:
        score = 438;
        break;
      case 15:
        score = 425;
        break;
      case 16:
        score = 413;
        break;
    }
  } else if (rank < 65) {
    score = 400 - (rank - 17) * 5;
  } else {
    score = 160 - (rank - 65) * 2;
  }
  if (score < 0) {
    score = 0;
  }
  return score;
}

enum ExportType { asTeam, asDivision }

/// 查询Progress
Future<bool> checkProgress(String dbName, String progressName) async {
  var db = await DatabaseManager.getDatabase(dbName);
  var result = await db.query('progress',
      columns: ['progress_value'],
      where: 'progress_name = ?',
      whereArgs: [progressName]);
  if (result.isEmpty) {
    throw "Unknown progress name $progressName";
  } else {
    return result.first['progress_value'] == 1;
  }
}

/// 更改Progress
Future<void> setProgress(
    String dbName, String progressName, bool isCompleted) async {
  DatabaseManager.getDatabase(dbName).then((db) {
    db.update('progress', {'progress_value': isCompleted ? 1 : 0},
        where: 'progress_name = ?', whereArgs: [progressName]);
  });
}

/// 新增Progress
Future<void> insertProgress(
    String dbName, String progressName, String description) async {
  DatabaseManager.getDatabase(dbName).then((db) {
    db.insert(
        'progress',
        {
          'progress_name': progressName,
          'progress_value': 0,
          'description': description
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  });
}

/// 输出到日志
Future<void> printDebug(dynamic content) async {
  print(content);
  final logDirectory = Directory('log');
  final logFile = File('log/latest.log');
  if (!await logDirectory.exists()) {
    await logDirectory.create(recursive: true);
  }
  if (!await logFile.exists()) {
    await logFile.create(recursive: true);
  }
  await logFile.writeAsString('${content.toString()}\n', mode: FileMode.append);
}
