import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:paddle_score_app/DataHelper.dart';
import 'package:paddle_score_app/pageWidgets/universalWidgets/ErrorHandler.dart';
import 'package:paddle_score_app/pageWidgets/universalWidgets/Loading.dart';
import 'package:paddle_score_app/utils/GlobalFunction.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../main.dart';
import '../appEntrances/racesEntrancePage.dart';
import 'exportOptionWidget.dart';
import 'dart:typed_data';

import 'ScoreTableWidget.dart';

class LongDistanceRacePage extends StatefulWidget {
  final String raceBar;
  final String raceEventName;

  const LongDistanceRacePage(
      {super.key, required this.raceBar, required this.raceEventName});

  @override
  State<LongDistanceRacePage> createState() => _LongDistanceRacePageState();
}

class _LongDistanceRacePageState extends State<LongDistanceRacePage> {
  @override
  void initState() {
    super.initState();
  }

  String? _selectedFile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.raceBar),
        ),
        body: Center(
          child: FractionallySizedBox(
            alignment: Alignment.center,
            widthFactor: 0.9,
            child: ListView(children: [
              /// 提示卡片
              const Card(
                child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.green),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "提示",
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    "此页面用于处理赛事第一项，具体步骤如下：\n1. 下载待填长距离赛成绩表\n2. 在长距离赛完成后，人工录入数据到长距离成绩Excel表中。在此页面上传长距离成绩表，软件将根据成绩自动划出各组分配情况与分配的站位\n3. 转到各个比赛组别页面填写各组成绩",
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.black87),
                                  ),
                                ),
                              ],
                            )),
                      ],
                    )),
              ),

              /// 下载文件卡片
              Card(
                child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.download,
                                color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                "下载待填长距离赛成绩表",
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    "1. 请下载待填长距离赛成绩表，所有组别填写完毕后上传",
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.black87),
                                  ),
                                ),
                              ],
                            )),
                        const SizedBox(height: 8),
                        FutureBuilder(
                            future: checkProgress(
                                widget.raceEventName, "long_distance_imported"),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.done) {
                                if (snapshot.data == null) {
                                  throw Exception("无法获取到状态，一般来说该报错不会抛出");
                                }
                                return ElevatedButton(
                                  onPressed: snapshot.data!
                                      ? null
                                      : () async {
                                          /// 下载文件逻辑
                                          try {
                                            Loading.startLoading(
                                                "正在生成长距离成绩登记表", context);
                                            List<int>? excelFileBytes =
                                                await DataHelper
                                                    .generateLongDistanceScoreExcel(
                                                        widget.raceEventName);
                                            Future.delayed(Duration.zero,
                                                () async {
                                              String? filePath =
                                                  await FilePicker.platform
                                                      .saveFile(
                                                dialogTitle: '保存长距离登记表',
                                                fileName:
                                                    '长距离成绩登记表 - ${widget.raceEventName}.xlsx',
                                              );
                                              if (filePath == null) {
                                                Loading.stopLoading(context);
                                                return;
                                              }
                                              File file = File(filePath);
                                              await file.writeAsBytes(
                                                  excelFileBytes!);
                                              await setProgress(
                                                  widget.raceEventName,
                                                  "long_distance_downloaded",
                                                  true);
                                              Loading.stopLoading(context);
                                              setState(() {});
                                              print("文件已保存到:$filePath");
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                      content: Text(
                                                          "文件已保存到:$filePath，请用Excel等工具填写完毕后上传")));
                                            });
                                          } catch (e) {
                                            Loading.stopLoading(context);
                                            ErrorHandler.showErrorDialog(
                                                context,
                                                "生成Excel失败，请联系开发者",
                                                e.toString());
                                          }
                                        },
                                  child: snapshot.data!
                                      ? const Text("已完成")
                                      : const Text("下载"),
                                );
                              } else {
                                return const CircularProgressIndicator();
                              }
                            })
                      ],
                    )),
              ),

              /// 上传文件卡片
              Card(
                child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.upload_file,
                                color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                "上传长距离赛成绩表",
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    "2. 请上传长距离赛成绩表，软件将根据成绩自动划出各组分配情况与分配的站位",
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.black87),
                                  ),
                                ),
                              ],
                            )),
                        const SizedBox(height: 8),
                        FutureBuilder(future: () async {
                          final isDownloaded = await checkProgress(
                              widget.raceEventName, "long_distance_downloaded");
                          print(isDownloaded);
                          final isImported = await checkProgress(
                              widget.raceEventName, "long_distance_imported");
                          return {
                            "isDownloaded": isDownloaded,
                            "isImported": isImported
                          };
                        }(), builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            if (snapshot.data == null) {
                              throw Exception("无法获取到progress表状态，一般来说该报错不会抛出");
                            }
                            return ElevatedButton(
                              onPressed: !snapshot.data!["isDownloaded"]! ||
                                      snapshot.data![
                                          "isImported"]! // 如果导入完成或者尚未下载，按钮不可用
                                  ? null
                                  : () async {
                                      /// 上传文件逻辑
                                      FilePickerResult? result =
                                          await FilePicker.platform.pickFiles(
                                        type: FileType.custom,
                                        allowedExtensions: ['xlsx'],
                                      );
                                      if (result != null) {
                                        _selectedFile =
                                            result.files.single.path!;
                                        print(_selectedFile);
                                        // 读取二进制文件
                                        Uint8List fileBinary =
                                            File(_selectedFile!)
                                                .readAsBytesSync();
                                        Loading.startLoading(
                                            "正在导入长距离成绩到数据库中，请稍等", context);
                                        try {
                                          await DataHelper
                                              .importLongDistanceScore(
                                                  widget.raceEventName,
                                                  fileBinary);
                                          Loading.stopLoading(context);

                                          /// 导入成功
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content: Text("导入成功")));

                                          /// 返回首页并刷新
                                          Navigator.pushAndRemoveUntil(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const MyHomePage()),
                                            (route) => false,
                                          );
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      RacePage(
                                                          raceName: widget
                                                              .raceEventName)));
                                        } catch (e) {
                                          Loading.stopLoading(context);
                                          ErrorHandler.showErrorDialog(
                                              context,
                                              "Excel文件导入失败，请检查以下内容:\n1.成绩是否都已填写，即使运动员缺赛，也需要填写DNF或DNS\n2.成绩是否填写正确，成绩格式应该为XXXXXX，例如013298，不要包含其他字符\n3.编号是否为数字\n4.代表队非必填，不会影响最终结果",
                                              e.toString());
                                        }
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content:
                                                    Text("请选择填写完毕的长距离成绩表")));
                                        // User canceled the picker
                                      }
                                    },
                              child: !snapshot.data!["isDownloaded"]!
                                  ? const Text("请先下载并填写完成后再上传")
                                  : snapshot.data!["isImported"]!
                                      ? const Text("已完成")
                                      : const Text("上传"),
                            );
                          } else {
                            return const CircularProgressIndicator();
                          }
                        })
                      ],
                    )),
              ),
            ]),
          ),
        ));
  }
}
