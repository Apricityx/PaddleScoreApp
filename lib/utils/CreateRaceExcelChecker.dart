import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:paddle_score_app/utils/GlobalFunction.dart';

class CreateRaceExcelChecker {
  /// 获取有哪些组别
  /// @param fileBinary Excel文件的二进制数据
  static Future<List<String>> getDivisions(List<int> fileBinary) async {
    // 组别在Excel文件的第一列
    // 读取Excel文件
    // 读取第一列
    var excel = Excel.decodeBytes(fileBinary);
    var sheet = excel.tables.keys.first;
    List<CellValue?> divisionColumn =
        excel.tables[sheet]!.rows.map((e) => e[0]?.value).toList();
    // 去掉第一行
    divisionColumn.removeAt(0);
    // 转换为List<String>
    List<String> divisions = divisionColumn.map((e) => e.toString()).toList();
    // 去重
    divisions = divisions.toSet().toList();
    return divisions;
  }

  static getAthleteCount(List<int> fileBinary) {
    // 读取Excel文件
    var excel = Excel.decodeBytes(fileBinary);
    var sheet = excel.tables.keys.first;
    // 输出行数
    return excel.tables[sheet]!.maxRows - 1;
  }

  /// 检查Excel文件是否符合规范
  /// 检查规则：1. 第二列除开第一行外不能有空值
  static ValidExcelResult validExcel(Uint8List readAsBytesSync) {
    ValidExcelResult result = ValidExcelResult();
    var excel = Excel.decodeBytes(readAsBytesSync);
    var sheet = excel.tables.keys.first;
    var rows = excel.tables[sheet]!.rows;

    /// 1. ID不能重复
    result.numberNoDuplicate = true;
    List<String> numberSet = [];
    for (var i = 1; i < rows.length; i++) {
      numberSet.add(rows[i][1]!.value.toString());
    }
    if (numberSet.toSet().length != numberSet.length) {
      print(numberSet.toSet().length != numberSet.length);
      printDebug('ID重复', level: 1);
      result.numberNoDuplicate = false;
    }

    /// 2. ID不能为非数字或为空
    result.numberNoIllegalChar = true;
    for (var id in numberSet) {
      if (!RegExp(r'^\d+$').hasMatch(id) || id == '') {
        printDebug('ID非数字或为空', level: 1);
        result.numberNoIllegalChar = false;
      }
    }

    /// 3. 组别中不能有空格
    result.divisionNameNoIllegalChar = true;
    for (var i = 1; i < rows.length; i++) {
      if (rows[i][0]?.value == null ||
          rows[i][0]!.value.toString().contains(' ')) {
        printDebug('组别中有空格', level: 1);
        result.divisionNameNoIllegalChar = false;
      }
    }

    /// 4. 运动员名不能为空
    result.athleteNameNoEmpty = true;
    for (var i = 1; i < rows.length; i++) {
      if (rows[i][2]?.value == null || rows[i][2]!.value.toString() == '') {
        printDebug('运动员名为空', level: 1);
        result.athleteNameNoEmpty = false;
      }
    }

    /// 5. 队伍名不能为空
    result.teamNoEmpty = true;
    for (var i = 1; i < rows.length; i++) {
      if (rows[i][3]?.value == null || rows[i][3]!.value.toString() == '') {
        printDebug('队伍名为空', level: 1);
        result.teamNoEmpty = false;
      }
    }
    return result;
  }
}

class ValidExcelResult {
  bool numberNoIllegalChar;
  bool numberNoDuplicate;
  bool divisionNameNoIllegalChar;
  bool athleteNameNoEmpty;
  bool teamNoEmpty;

  ValidExcelResult()
      : numberNoIllegalChar = false,
        numberNoDuplicate = false,
        divisionNameNoIllegalChar = false,
        athleteNameNoEmpty = false,
        teamNoEmpty = false;
}
