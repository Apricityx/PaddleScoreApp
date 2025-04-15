import 'dart:math';

import 'package:excel/excel.dart';
import 'package:paddle_score_app/utils/SettingService.dart';
import 'package:sqflite/sqflite.dart';

import 'DatabaseManager.dart';
import 'GlobalFunction.dart';

class ExcelGenerator {
  static Future<List<int>?> generic(
      String division, CType c, SType s, String dbName) async {
    /// 查询该比赛类别的分组人数
    int athleteCountPerGroup = await getAthleteCountPerGroup(dbName, c);
    printDebug("$c分组人数:$athleteCountPerGroup");

    print('生成$division${cTypeTranslate(c)}${sTypeTranslate(s)}的Excel');
    var excel = Excel.createExcel();
    var tableName = "${division}_${sTypeTranslate(s)}_${cTypeTranslate(c)}";
    print('tableName: $tableName');
    Database db = await DatabaseManager.getDatabase(dbName);
    var a = await db.query("'$tableName'", columns: ['id']);
    int athletesNum = a.length;
    // 生成Excel
    int groupNum = getGroupNum(athletesNum, athleteCountPerGroup);
    if (groupNum == 0) {
      throw Exception(
          "该比赛尚未进行！抛出该错误的原因是运动员数量返回为0，请检查该场比赛$division${cTypeTranslate(c)}${sTypeTranslate(s)}是否已经录入数据！");
    }
    // !!!todo!!!
    for (var i = 0; i < groupNum; i++) {
      // 查询_group == i的运动员
      print('正在录入第${i + 1}组');
      var athletes = await db.rawQuery(
          'SELECT $tableName.name,$tableName.id, $tableName._group, "长距离比赛".long_distant_rank FROM $tableName LEFT JOIN "长距离比赛" ON "长距离比赛".id = $tableName.id WHERE $tableName._group = ${i + 1}');
      print(
          'SELECT $tableName.name,$tableName.id, $tableName._group, "长距离比赛".long_distant_rank FROM $tableName LEFT JOIN "长距离比赛" ON "长距离比赛".id = $tableName.id WHERE $tableName._group = ${i + 1}');
      if (athletes.isEmpty) {
        throw Exception("未获取到运动员！$tableName的上一场比赛可能尚未录入数据！");
      }
      // print('查询$tableName,查询到的运动员：$athletes');
      // 将运动员按long_distant_rank倒序排序，long_distant_rank越小越优先
      var sortedAthletes = List.from(athletes);
      sortedAthletes.sort((a, b) {
        int rankA = int.parse(a['long_distant_rank'].toString());
        int rankB = int.parse(b['long_distant_rank'].toString());
        return rankA.compareTo(rankB); // 按降序排序
      });
      print('排序后的运动员：$sortedAthletes');
      List<String> headers = [
        '编号',
        '姓名',
        '成绩（按照xxxxxx的格式填写,代表xx:xx:xx）',
        '长距离比赛排名',
        '静水出发位置',
        '动水出发位置',
        '备注'
      ];
      var sheet =
          excel['$division${cTypeTranslate(c)}${sTypeTranslate(s)}${i + 1}'];
      // 设置标题
      sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('G1'),
          customValue: TextCellValue(
              '$division${cTypeTranslate(c)}${sTypeTranslate(s)}${i + 1}'));
      // 添加header
      for (int i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1))
          ..value = TextCellValue(headers[i])
          ..cellStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
          );
      }
      // 录入运动员
      var index = 2;
      for (var athlete in sortedAthletes) {
        print('正在录入${athlete['name']}');
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: index))
            .value = TextCellValue('${athlete['id']}');
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: index))
            .value = TextCellValue('${athlete['name']}');
        if (SettingService.settings['isDebugMode']) {
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: index))
              .value = TextCellValue(_randomTimeGenerator()); // 时间 -todo delete
        } else {
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: index))
              .value = TextCellValue('');
        }
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: index))
            .value = TextCellValue('${athlete['long_distant_rank']}'); // todo
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: index))
            .value = TextCellValue(_getStaticPosition(
                index - 2, athleteCountPerGroup)
            .toString()); // 静水
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: index))
            .value = TextCellValue(_getDynamicPosition(
                index - 2, athleteCountPerGroup)
            .toString()); // 动水
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: index))
            .value = TextCellValue('');
        ++index;
      }
      // 删除sheet1
      excel.delete('Sheet1');
    }
    return excel.encode();
  }

  static Future<List<int>?> longDistance(String dbName) async {
    Database db = await DatabaseManager.getDatabase(dbName);
    List<Map<String, dynamic>> tables =
        await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    List<String> tableNames =
        tables.map((row) => row['name'] as String).toList();
    print(tableNames);
    var divisions = await getDivisions(dbName);
    // 生成Excel，生成n个sheet，每一个sheet代表一个组别
    // 生成表头
    var excel = Excel.createExcel();
    List<String> headers = [
      '编号',
      '姓名',
      '代表队',
      '成绩（按照xxxxxx的格式填写,代表xx:xx:xx）',
      '备注'
    ];
    List<String> overviewHeaders = [
      '编号',
      '姓名',
      '代表队',
      '成绩(按照xxxxxx的格式填写,代表xx:xx:xx)',
      '组别',
      '备注'
    ];
    // 将sheet1重命名为总表
    excel.rename("Sheet1", "总表");
    var overviewSheet = excel["总表"];

    // 设置总表格式
    overviewSheet.merge(
        CellIndex.indexByString('A1'), CellIndex.indexByString('F1'),
        customValue: TextCellValue('桨板长距离赛成绩单'));
    var cell = overviewSheet.cell(CellIndex.indexByString('A1'));
    cell.cellStyle = CellStyle(
      fontSize: 20,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );
    for (int i = 0; i < overviewHeaders.length; i++) {
      overviewSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 3))
        ..value = TextCellValue(overviewHeaders[i])
        ..cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
        );
    }

    overviewSheet.merge(
        CellIndex.indexByString('A2'), CellIndex.indexByString('F3'),
        customValue: TextCellValue('请勿修改此表，请填写其他sheet内的数据'));
    cell = overviewSheet.cell(CellIndex.indexByString('A2'));
    cell.cellStyle = CellStyle(
      fontSize: 14,
      bold: true,
      //设置为红色
      fontColorHex: ExcelColor.red,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    for (var division in divisions) {
      var sheet = excel[division];
      // 设置标题
      sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('E1'),
          customValue: TextCellValue('$division长距离成绩表'));
      // 设置合并单元格的样式
      var cell = sheet.cell(CellIndex.indexByString('A1'));
      cell.cellStyle = CellStyle(
        fontSize: 20,
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );
      // 设置B2到E2为header
      for (int i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1))
          ..value = TextCellValue(headers[i])
          ..cellStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
          );
      }
      // 从数据库读取数据
      // 先填此sheet,再填总表的链接数据
      var athletes = await db.rawQuery('''
      SELECT * FROM athletes WHERE division = '$division'
    ''');
      for (int i = 0; i < athletes.length; i++) {
        var athlete = athletes[i];
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 2))
            .value = TextCellValue('${athlete['id']}');
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 2))
            .value = TextCellValue('${athlete['name']}');
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 2))
            .value = TextCellValue('${athlete['team']}');
        if (SettingService.settings['isDebugMode']) {
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i + 2))
              .value = TextCellValue(_randomTimeGenerator());
        } else {
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i + 2))
              .value = TextCellValue('');
        } // todo delete
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: i + 2))
            .value = TextCellValue('');
        // 将columnIndex: 3, rowIndex: i + 2的数据类型设为字符串
      }
      for (int i = 0; i < athletes.length; i++) {
        var athlete = athletes[i];
        // 填总表的链接数据
        // 从末尾开始填写
        var rowIndex = overviewSheet.maxRows;
        overviewSheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
            .value = FormulaCellValue('$division!A${i + 3}');
        overviewSheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
            .value = FormulaCellValue('$division!B${i + 3}');
        overviewSheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
            .value = FormulaCellValue('$division!C${i + 3}');
        overviewSheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
            .value = FormulaCellValue('$division!D${i + 3}');
        overviewSheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
            .value = TextCellValue(division);
        overviewSheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
            .value = FormulaCellValue('$division!E${i + 3}');
      }
    }
    var fileBytes = excel.encode();
    return fileBytes;
  }

  /// 用于导出最终的成绩表
  /// 传入参数包括e和isContainProne，前者用于确定导出类型，后者用于判断是否需要包含趴板成绩
  static Future<List<int>> exportScores(
      String dbName, ExportType e, bool isContainProne) async {
    Database db = await DatabaseManager.getDatabase(dbName);
    // var divisions = await getDivisions(dbName);
    var excel = Excel.createExcel();
    // 确定导出的类型
    List sheetNames;
    if (e == ExportType.asDivision) {
      sheetNames = await getDivisions(dbName);
    } else if (e == ExportType.asTeam) {
      sheetNames = await db
          .rawQuery('SELECT DISTINCT team FROM athletes')
          .then((value) => value.map((e) => e['team'].toString()).toList());
    } else {
      throw "未知的导出类型，请检查调用参数";
    }
    for (var sheetName in sheetNames) {
      var sheet = excel[sheetName];
      // 设置标题
      sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('H1'),
          customValue: TextCellValue('$sheetName成绩表'));
      // 设置合并单元格的样式
      var cell = sheet.cell(CellIndex.indexByString('A1'));
      cell.cellStyle = CellStyle(
        fontSize: 20,
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );
      List<String> headers = [];
      List<Map> athletes;
      if (e == ExportType.asDivision) {
        athletes = await db.rawQuery('''
            SELECT id,name,division,long_distance_score,prone_paddle_score,sprint_score,technical_score FROM athletes WHERE division = '$sheetName'
          ''');
      } else {
        athletes = await db.rawQuery('''
            SELECT id,name,team,long_distance_score,prone_paddle_score,sprint_score,technical_score FROM athletes WHERE team = '$sheetName'
          ''');
      }
      if (isContainProne) {
        /// 1. 包含趴板
        headers = [
          '编号',
          '姓名',
          '代表队',
          '长距离积分',
          '趴板积分',
          '竞速积分',
          '技术积分',
          '总积分',
          '备注'
        ];
        for (int i = 0; i < headers.length; i++) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1))
            ..value = TextCellValue(headers[i])
            ..cellStyle = CellStyle(
              bold: true,
              horizontalAlign: HorizontalAlign.Center,
            );
        }
        for (int i = 0; i < athletes.length; i++) {
          var athlete = athletes[i];
          int longDistanceScore = athlete['long_distance_score'];
          int pronePaddleScore = athlete['prone_paddle_score'];
          int sprintScore = athlete['sprint_score'];
          int technicScore = athlete['technical_score'];
          int totalScore =
              longDistanceScore + pronePaddleScore + sprintScore + technicScore;
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 2))
              .value = TextCellValue('${athlete['id']}');
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 2))
              .value = TextCellValue('${athlete['name']}');
          if (e == ExportType.asDivision) {
            sheet
                .cell(
                    CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 2))
                .value = TextCellValue('${athlete['division']}');
          } else {
            sheet
                .cell(
                    CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 2))
                .value = TextCellValue('${athlete['team']}');
          }
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i + 2))
              .value = TextCellValue('$longDistanceScore');
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: i + 2))
              .value = TextCellValue('$pronePaddleScore');
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: i + 2))
              .value = TextCellValue('$sprintScore');
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: i + 2))
              .value = TextCellValue('$technicScore');
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: i + 2))
              .value = TextCellValue('$totalScore');
        }
      } else {
        /// 2. 不包含趴板
        headers = ['编号', '姓名', '代表队', '长距离积分', '竞速积分', '技术积分', '总积分', '备注'];
        for (int i = 0; i < headers.length; i++) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1))
            ..value = TextCellValue(headers[i])
            ..cellStyle = CellStyle(
              bold: true,
              horizontalAlign: HorizontalAlign.Center,
            );
        }
        for (int i = 0; i < athletes.length; i++) {
          var athlete = athletes[i];
          int longDistanceScore = athlete['long_distance_score'];
          int sprintScore = athlete['sprint_score'];
          int technicScore = athlete['technical_score'];
          int totalScore = longDistanceScore + sprintScore + technicScore;
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 2))
              .value = TextCellValue('${athlete['id']}');
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 2))
              .value = TextCellValue('${athlete['name']}');
          if (e == ExportType.asDivision) {
            sheet
                .cell(
                    CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 2))
                .value = TextCellValue('${athlete['division']}');
          } else {
            sheet
                .cell(
                    CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 2))
                .value = TextCellValue('${athlete['team']}');
          }
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i + 2))
              .value = TextCellValue('$longDistanceScore');
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: i + 2))
              .value = TextCellValue('$sprintScore');
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: i + 2))
              .value = TextCellValue('$technicScore');
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: i + 2))
              .value = TextCellValue('$totalScore');
        }
      }

      // 从数据库读取数据
    }

    excel.delete('Sheet1');
    var fileBytes = excel.encode();
    if (fileBytes == null) {
      throw Exception('导出最终成绩Excel失败！');
    }
    return fileBytes;
  }

  static String _randomTimeGenerator() {
    // 生成一个随机的时间 格式为hh:mm.ss
    Random random = Random();
    int hour = random.nextInt(24);
    int minute = random.nextInt(60);
    int second = random.nextInt(60);
    // 0.1的概率为DNS
    if (random.nextInt(10) == 0) {
      return 'DNS';
    }
    // 0.05的概率为DNF
    if (random.nextInt(20) == 0) {
      return 'DNF';
    }
    // 0.005的概率为DSQ
    if (random.nextInt(500) == 0) {
      return 'DSQ';
    }
    return '${hour.toString().padLeft(2, '0')}${minute.toString().padLeft(2, '0')}${second.toString().padLeft(2, '0')}';
  }

  static int _getStaticPosition(int index, int athleteCountPerGroup) {
    // 静水中，从中间出发为优势水道
    if (athleteCountPerGroup % 2 == 0) {
      if (index % 2 == 0) {
        return athleteCountPerGroup ~/ 2 - (index ~/ 2);
      } else {
        return athleteCountPerGroup ~/ 2 + 1 + ((index - 1) ~/ 2);
      }
    } else {
      if (index % 2 == 0) {
        return athleteCountPerGroup ~/ 2 + 1 - (index ~/ 2);
      } else {
        return athleteCountPerGroup ~/ 2 + ((index - 1) ~/ 2);
      }
    }
  }

  static int _getDynamicPosition(int index, int athleteCountPerGroup) {
    return index + 1;
    //   // 动水中，从两侧出发为优势水道
    //   if (index % 2 == 0) {
    //     return athleteCountPerGroup - (index ~/ 2);
    //   } else {
    //     return 1 + ((index - 1) ~/ 2);
    //   }
    // }
  }
}
