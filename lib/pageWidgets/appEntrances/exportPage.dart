import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:paddle_score_app/pageWidgets/universalWidgets/ErrorHandler.dart';

import '../../DataHelper.dart';
import '../../utils/GlobalFunction.dart';
import '../universalWidgets/Loading.dart';

class ExportPage extends StatefulWidget {
  const ExportPage({super.key, required String raceName});

  @override
  _ExportPage createState() => _ExportPage();
}

class _ExportPage extends State<ExportPage> {
  ExportType exportType = ExportType.asDivision;

  void handleExportTypeChange(ExportType? value) {
    setState(() {
      exportType = value!;
    });
  }

  bool isContainPronePaddle = false;

  void handlePronePaddleChange(bool? value) {
    setState(() {
      isContainPronePaddle = value!;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String? raceName =
        ModalRoute.of(context)!.settings.arguments as String?;
    printDebug(raceName);
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: const Text('导出'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Divider(),
            RadioListTile<ExportType>(
              title: Text('按组别导出'),
              value: ExportType.asDivision,
              groupValue: exportType,
              onChanged: handleExportTypeChange,
            ),
            RadioListTile<ExportType>(
              title: Text('按代表队导出'),
              value: ExportType.asTeam,
              groupValue: exportType,
              onChanged: handleExportTypeChange,
            ),
//            分隔符
            Divider(),
            RadioListTile<bool>(
              title: Text('计算青年组趴板分数'),
              value: true,
              groupValue: isContainPronePaddle,
              onChanged: handlePronePaddleChange,
            ),
            RadioListTile<bool>(
              title: Text('不计算青年组趴板分数'),
              value: false,
              groupValue: isContainPronePaddle,
              onChanged: handlePronePaddleChange,
            ),
            Divider(),
            SizedBox(
              width: MediaQuery.of(context).size.width / 4, // 占满宽度
              child: TextButton(
                onPressed: () async {
                  /// 点击导出
                  try {
                    printDebug(
                        "选中的类型：$exportType 选中的趴板分数：$isContainPronePaddle 选中的比赛名: $raceName");
                    var finalScoreBinary;
                    if (exportType == ExportType.asTeam) {
                      finalScoreBinary = await DataHelper.exportFinalScore(
                          raceName!, ExportType.asTeam, isContainPronePaddle);
                    } else {
                      finalScoreBinary = await DataHelper.exportFinalScore(
                          raceName!,
                          ExportType.asDivision,
                          isContainPronePaddle);
                    }

                    /// 让用户保存文件
                    Future.delayed(Duration.zero, () async {
                      String? filePath = await FilePicker.platform.saveFile(
                        dialogTitle: '保存长距离登记表',
                        fileName: '最终成绩表 - $raceName.xlsx',
                      );
                      if (filePath == null) {
                        Loading.stopLoading(context);
                        return;
                      }
                      File file = File(filePath);
                      await file.writeAsBytes(finalScoreBinary!);
                      Loading.stopLoading(context);
                      print("文件已保存到:$filePath");
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("文件已保存到:$filePath，请检查文件是否有误")));
                    });
                  } catch (e) {
                    ErrorHandler.showErrorDialog(
                        context, "导出成绩失败，请检查所有成绩是否都已录入", e.toString());
                    rethrow;
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  // 文本颜色
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  // 水平内边距
                  textStyle:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  // 文本样式
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), // 圆角半径为高度的一半
                  ),
                  alignment: Alignment.center, // 内容左对齐
                ),
                child: Text('导出'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
