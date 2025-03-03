import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:paddle_score_app/DataHelper.dart';
import 'package:paddle_score_app/test/TestUnit.dart';

import 'package:paddle_score_app/utils/GlobalFunction.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:paddle_score_app/utils/DatabaseManager.dart';

class TestPage extends StatelessWidget {
  const TestPage({super.key});

  static const testFilePath = '/home/apricityx/Desktop';

  @override
  Widget build(BuildContext context) {
    final items = ['Item 1', 'Item 2', 'Item 3', 'Item 4', 'Item 5'];
    // delete test code -todo

    return Scaffold(
      appBar: AppBar(
        title: const Text('开发者模式'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              print(1); // 点击加号时输出1
            },
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
              leading: Icon(Icons.generating_tokens),
              title: Text("跳转到新页面"),
              onTap: () async {
                Navigator.pushNamed(
                  context,
                  "/create",
                );
                // Navigator.pushNamed(context,"/settings");
              }),
          TestUnit(
              text: "导入报名表",
              icon: Icons.upload_file,
              callBack: () async {
                String dbName = "athlete";
                File xlsxFile = File("$testFilePath/参赛信息-_汉丰湖.xlsx");

                await DataHelper.loadExcelFileToAthleteDatabase(
                    dbName, xlsxFile.readAsBytesSync(), [16, 16, 16]);
              }),
          TestUnit(
              text: "下载长距离空成绩表",
              icon: Icons.sim_card_download,
              callBack: () async {
                String dbName = "athlete";
                List<int>? excelFileBytes =
                    await DataHelper.generateLongDistanceScoreExcel(dbName);
                if (excelFileBytes == null) {
                  throw Exception("生成 Excel 文件失败");
                }
                // String? filePath = await FilePicker.platform.saveFile(
                //   dialogTitle: '保存 Excel 文件',
                //   fileName: '长距离成绩单.xlsx',
                // );
                var filePath = "$testFilePath/长距离成绩单.xlsx"; // -todo
                // 创建文件并写入字节数据
                File file = File(filePath);
                await file.writeAsBytes(excelFileBytes);

                print('文件已保存到: $filePath');
                // 关闭对话框
              }),
          TestUnit(
              text: "导入已录入的长距离成绩",
              icon: Icons.import_contacts,
              callBack: () async {
                File exampleFile = File("$testFilePath/长距离成绩单.xlsx");
                await DataHelper.importLongDistanceScore(
                    'athlete', exampleFile.readAsBytesSync());
              }),
          const Divider(),
          TestUnit(
              text: '下载初赛空成绩表',
              icon: Icons.sim_card_download_outlined,
              callBack: () async {
                String dbName = "athlete";
                String path = "$testFilePath/大师组男子竞速初赛成绩表.xlsx";
                List<int>? exampleFile = await DataHelper.generateGenericExcel(
                    "大师组男子", CType.sprint, SType.firstRound, dbName);
                File file = File(path);
                await file.writeAsBytes(exampleFile!);
                print('文件已保存到: $path');
              }),
          TestUnit(
              text: '导入已填写的初赛成绩表',
              icon: Icons.import_contacts,
              callBack: () async {
                String dbName = "athlete";
                String path = "$testFilePath/大师组男子竞速初赛成绩表.xlsx";
                await DataHelper.importGenericCompetitionScore(
                    "大师组男子",
                    File(path).readAsBytesSync(),
                    CType.sprint,
                    SType.firstRound,
                    dbName);
              }),
          const Divider(),
          TestUnit(
              text: '下载二分之一决赛空成绩表',
              icon: Icons.sim_card_download_outlined,
              callBack: () async {
                String dbName = "athlete";
                String path = "$testFilePath/大师组男子竞速二分之一决赛成绩表.xlsx";
                List<int>? exampleFile = await DataHelper.generateGenericExcel(
                    "大师组男子", CType.sprint, SType.semifinals, dbName);
                File file = File(path);
                await file.writeAsBytes(exampleFile!);
                print('文件已保存到: $path');
              }),
          TestUnit(
              text: '导入已完成的二分之一决赛成绩表',
              icon: Icons.import_contacts,
              callBack: () async {
                String dbName = "athlete";
                String path = "$testFilePath/大师组男子竞速二分之一决赛成绩表.xlsx";
                await DataHelper.importGenericCompetitionScore(
                    "大师组男子",
                    File(path).readAsBytesSync(),
                    CType.sprint,
                    SType.semifinals,
                    dbName);
              }),
          const Divider(),
          TestUnit(
              text: '下载决赛空成绩表',
              icon: Icons.sim_card_download_outlined,
              callBack: () async {
                String dbName = "athlete";
                String path = "$testFilePath/大师组男子竞速决赛成绩表.xlsx";
                List<int>? exampleFile = await DataHelper.generateGenericExcel(
                    "大师组男子", CType.sprint, SType.finals, dbName);
                File file = File(path);
                await file.writeAsBytes(exampleFile!);
                print('文件已保存到: $path');
              }),
          TestUnit(
              text: '导入已完成的决赛成绩表',
              icon: Icons.import_contacts,
              callBack: () async {
                String dbName = "athlete";
                String path = "$testFilePath/大师组男子竞速决赛成绩表.xlsx";
                await DataHelper.importGenericCompetitionScore(
                    "大师组男子",
                    File(path).readAsBytesSync(),
                    CType.sprint,
                    SType.finals,
                    dbName);
              }),
          TestUnit(
            text: '测试实例',
            icon: Icons.running_with_errors,
            callBack: () async {
              var a = await getDivisions("athlete");
              // 等待5秒
              await Future.delayed(Duration(seconds: 5));
              print(a);
            },
          ),
          const Divider(),
          TestUnit(
              text: '下载高校甲组女子空成绩表',
              icon: Icons.sim_card_download_outlined,
              callBack: () async {
                String dbName = "athlete";
                String path = "$testFilePath/高校甲组女子竞速决赛成绩表.xlsx";
                List<int>? exampleFile = await DataHelper.generateGenericExcel(
                    "高校甲组女子", CType.sprint, SType.finals, dbName);
                File file = File(path);
                await file.writeAsBytes(exampleFile!);
                print('文件已保存到: $path');
              }),
          TestUnit(
              text: '导入已完成的高校甲组女子成绩表',
              icon: Icons.import_contacts,
              callBack: () async {
                String dbName = "athlete";
                String path = "$testFilePath/高校甲组女子竞速决赛成绩表.xlsx";
                await DataHelper.importGenericCompetitionScore(
                    "高校甲组女子",
                    File(path).readAsBytesSync(),
                    CType.sprint,
                    SType.finals,
                    dbName);
              }),
          TestUnit(
              text: '导出最终积分',
              icon: Icons.score,
              callBack: () async {
                String dbName = "athlete";
                String path = "$testFilePath/最终积分表2.xlsx";
                var fileBinary = await DataHelper.exportFinalScore(
                    dbName, ExportType.asDivision);
                File file = File(path);
                await file.writeAsBytes(fileBinary);
                print('文件已保存到: $path');
              }),
        ],
      ),
    );
  }
}
