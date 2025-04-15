import 'dart:ffi';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:paddle_score_app/utils/DatabaseManager.dart';
import 'package:paddle_score_app/utils/ExcelAnalyzer.dart';
import 'package:paddle_score_app/utils/ExcelGenerator.dart';
import 'package:paddle_score_app/utils/GlobalFunction.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DataHelper {
  /// 传入报名表的Excel文件，初始化数据库，这是所有操作的第一步
  /// [dbName] 数据库名
  /// [xlsxFileBytes] 文件二进制数据
  /// [groupsAthleteCount] 每组运动员数
  static Future<void> loadExcelFileToAthleteDatabase(String dbName,
      List<int> xlsxFileBytes, List<int> groupsAthleteCount) async {
    printDebug("录入分组人数");
    Database db = await DatabaseManager.getDatabase(dbName);

    /// 录入每组人数
    await db.insert('progress', {
      'progress_name': 'proneGroupAthleteCount',
      'progress_value': groupsAthleteCount[0],
      'description': '趴板每组的人数'
    });

    await db.insert('progress', {
      'progress_name': 'sprintGroupAthleteCount',
      'progress_value': groupsAthleteCount[1],
      'description': '竞速每组的人数'
    });

    await db.insert('progress', {
      'progress_name': 'technicalGroupAthleteCount',
      'progress_value': groupsAthleteCount[2],
      'description': '技术每组的人数'
    });

    printDebug(
        "已录入每组人数，分别为：${groupsAthleteCount[0]}, ${groupsAthleteCount[1]}");

    /// 初始化运动员信息表
    await ExcelAnalyzer.initAthlete(dbName, xlsxFileBytes);

    await db.update('progress', {'progress_value': 1},
        where: 'progress_name = ?', whereArgs: ['athlete_imported']);
    print("All Done :D");
    return;
  }

  /// 生成长距离比赛成绩表
  /// [dbName] 数据库名
  /// 返回一个List<int>，即Excel文件的二进制数据
  static Future<List<int>?> generateLongDistanceScoreExcel(
      String dbName) async {
    // 生成长距离比赛Excel
    // 读取所有数据表
    var temp = await ExcelGenerator.longDistance(dbName);
    print("All Done :D");
    return temp;
  }

  /// 导入长距离比赛成绩表
  /// [dbName] 数据库名
  /// [fileBinary] 文件二进制数据
  static Future<void> importLongDistanceScore(
      String dbName, List<int> fileBinary) async {
    var databaseFileBinary =
        File(await getFilePath("$dbName.db")).readAsBytesSync();
    print("已完成数据库备份");
    try {
      await ExcelAnalyzer.longDistance(dbName, fileBinary);
      await DatabaseManager.getDatabase(dbName).then((db) async {
        await db.update('progress', {'progress_value': 1},
            where: 'progress_name = ?', whereArgs: ['long_distance_imported']);
      });
      print("All Done :D");
    } catch (e) {
      printDebug("出现错误: $e 数据库已恢复");
      File(await getFilePath("$dbName.db"))
          .writeAsBytesSync(databaseFileBinary);
      rethrow;
    }

    return;
  }

  /// 生成趴板和竞速的Excel
  /// [division] 组别
  /// [c] 比赛进度
  /// [s] 项目
  /// [dbName] 数据库名
  /// [groupAthleteCount] 长距离组别人数
  static Future<List<int>?> generateGenericExcel(
      String division, CType c, SType s, String dbName) async {
    var temp = ExcelGenerator.generic(division, c, s, dbName);
    print("All Done :D");
    return temp;
  }

  /// 选择并导入趴板或竞速成绩表的Excel
  /// [division] 组别
  /// [fileBinary] 文件二进制数据
  /// [c] 比赛进度
  /// [s] 项目
  /// [dbName] 数据库名
  static Future<void> importGenericCompetitionScore(String division,
      List<int> fileBinary, CType c, SType s, String dbName) async {
    await ExcelAnalyzer.generic(division, fileBinary, c, s, dbName);
    await DatabaseManager.getDatabase(dbName).then((db) async {
      print(
          '尝试将${division}_${cTypeTranslate(c)}_${sTypeTranslate(s)}_imported更新为1');
      await db.update('progress', {'progress_value': 1},
          where: 'progress_name = ?',
          whereArgs: [
            '${division}_${sTypeTranslate(s)}_${cTypeTranslate(c)}_imported'
          ]);
    });
    print("All Done :D");
    return;
  }

  /// 导出最终成绩表，给出数据库名，返回一个List<int>，即Excel文件的二进制数据
  /// [dbName] 数据库名
  /// [e] 导出类型
  static Future<List<int>> exportFinalScore(
      String dbName, ExportType e, bool isContainProne) async {
    var temp = await ExcelGenerator.exportScores(dbName, e, isContainProne);
    print("All Done :D");
    return temp;
  }

  /// 删除该数据库
  static Future<void> deleteDatabase(String dbName) async {
    await DatabaseManager.deleteDatabase(dbName);
    print("All Done :D");
    return;
  }

  /// 修改某一场比赛的成绩
  static modifyGenericCompetitionScore(String division, CType raceType,
      SType stageType, String dbName, List<int> fineBinary) async {
    var databaseFileBinary =
        File(await getFilePath("$dbName.db")).readAsBytesSync();
    print("已完成数据库备份");
    try {
      await ExcelAnalyzer.modifyGeneric(
          division, raceType, stageType, dbName, fineBinary);
      print("All Done :D");
    } catch (e) {
      printDebug("修改运动员成绩出现错误: $e 数据库已恢复");
      print("修改运动员成绩出现错误: $e 数据库已恢复");
      File(await getFilePath("$dbName.db"))
          .writeAsBytesSync(databaseFileBinary);
      rethrow;
    }
  }
}
