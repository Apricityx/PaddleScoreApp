import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:paddle_score_app/DataHelper.dart';
import 'package:paddle_score_app/pageWidgets/universalWidgets/Loading.dart';
import 'package:paddle_score_app/utils/GlobalFunction.dart';

// import 'package:paddle_score_app/page_widgets/shortDistancePage.dart';
import 'package:provider/provider.dart';

import '../longDistanceRace/longDistancePage.dart';
import '../shortDistanceRace/shortDistancePage.dart';

enum RaceType {
  longRace,
  shortRace1,
  shortRace2,
  teamRace,
  personalScore,
}

class RacePage extends StatefulWidget {
  final String raceName;

  const RacePage({super.key, required this.raceName});

  @override
  _RacePage createState() => _RacePage(raceName);
}

class _RacePage extends State<RacePage> {
  final String raceName;

  _RacePage(this.raceName);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      appBar: AppBar(
        title: Text(raceName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            FutureBuilder(
                future: checkProgress(raceName, 'athlete_imported'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return RaceNameCard(
                        title: '6000米长距离赛（青少年3000米）',
                        raceName: raceName,
                        // subtitle: "点击进入",
                        clickable: snapshot.data as bool);
                  } else {
                    return const CircularProgressIndicator();
                  }
                }),
            FutureBuilder(
                future: checkProgress(raceName, 'long_distance_imported'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return RaceNameCard(
                        title: '200米趴板划水赛（仅限青少年）',
                        raceName: raceName,
                        // subtitle: "点击进入",
                        clickable: snapshot.data as bool);
                  } else {
                    return const CircularProgressIndicator();
                  }
                }),
            FutureBuilder(
                future: checkProgress(raceName, 'long_distance_imported'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return RaceNameCard(
                        title: '500米竞速赛',
                        raceName: raceName,
                        // subtitle: "点击进入",
                        clickable: snapshot.data as bool);
                  } else {
                    return const CircularProgressIndicator();
                  }
                }),
            Card(
              elevation: 4,
              color: Theme.of(context).canvasColor,
              child: InkWell(
                borderRadius: BorderRadius.circular(12.0),
                onTap: () async {
                  var choice = await showDialog<String>(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("请选择导出类型"),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.pop(context, null),
                            child: const Text('取消'),
                          ),
                          TextButton(
                            // 这里添加了空的Text widget
                            onPressed: () => Navigator.pop(context, "A"),
                            child: const Text('按组别导出'), // 补全了 child 属性
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, "B"),
                            child: const Text('按代表队导出'),
                          ),
                        ],
                      );
                    },
                  );
                  Loading.startLoading("导出中", context);
                  List<int> finalScoreBinary;
                  if (choice == 'A') {
                    finalScoreBinary = await DataHelper.exportFinalScore(
                        raceName, ExportType.asDivision);
                  } else if (choice == 'B') {
                    finalScoreBinary = await DataHelper.exportFinalScore(
                        raceName, ExportType.asTeam);
                  } else {
                    Loading.stopLoading(context);
                    return;
                  }
                  try {
                    await Future.delayed(Duration.zero, () async {
                      String? filePath = await FilePicker.platform.saveFile(
                        dialogTitle: '保存个人积分',
                        fileName: '个人积分 - $raceName.xlsx',
                      );
                      if (filePath == null) {
                        throw Exception("用户未选择文件");
                      } else {
                        File file = File(filePath);

                        // printDebug("!!TEST!!$choice");

                        await file.writeAsBytes(finalScoreBinary);
                        printDebug("文件已保存到:$filePath");
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('积分表下载完成')),
                        );
                        Loading.stopLoading(context);
                      }
                    });
                  } catch (e) {
                    Loading.stopLoading(context);
                  }
                },
                child: const ListTile(
                  title: Text('导出比赛积分表'),
                  subtitle: Text("点击导出"),
                  trailing: Icon(Icons.arrow_forward_ios),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 工厂方法
/// 用于创建一个新的比赛卡片实例
class RaceNameCard extends StatelessWidget {
  final String title;
  final String raceName;
  final bool clickable;

  const RaceNameCard({
    super.key,
    required this.title,
    required this.raceName,
    required this.clickable,
    // 以传入参数给成员变量赋值
  });

  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 4,
        // margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        color: clickable
            ? Theme.of(context).canvasColor
            : Theme.of(context).colorScheme.secondary,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          // color: Theme.of(context).colorScheme.secondary,
          onTap: !clickable
              ? null
              : () {
                  final raceBar = '$raceName/$title';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => title == "6000米长距离赛（青少年3000米）"
                          ? LongDistanceRacePage(
                              raceBar: raceBar, raceEventName: raceName)
                          : ShortDistancePage(
                              raceBar: raceBar,
                              raceEventName: raceName,
                            ),
                    ),
                  );
                },
          child: ListTile(
            // tileColor: Theme.of(context).canvasColor,
            title: Text(title),
            subtitle:
                clickable ? const Text("点击进入") : const Text("请在导入长距离比赛后进入"),
            trailing: const Icon(Icons.arrow_forward_ios),
          ),
        ));
  }
}
