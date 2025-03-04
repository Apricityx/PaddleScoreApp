import 'dart:io';

import 'package:file_picker/file_picker.dart';

// import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:paddle_score_app/pageWidgets/universalWidgets/ErrorHandler.dart';

// import 'package:glassmorphism/glassmorphism.dart';
import '../../DataHelper.dart';
import '../../utils/GlobalFunction.dart';
import '../universalWidgets/Loading.dart';
import 'RaceStateWidget.dart';

/// 工厂模式卡片组件
/// 用于提供导入不同比赛阶段成绩的入口
class RaceStageCard extends StatefulWidget {
  final String stageName;
  final String raceName;
  final String division;
  final String dbName;
  final int index;
  final Function(int, RaceStatus) onStatusChanged;
  final DataState dataState;

  const RaceStageCard(
      {super.key,
      required this.stageName,
      required this.raceName,
      required this.division,
      required this.dbName,
      required this.index,
      required this.onStatusChanged,
      required this.dataState});

  @override
  State<RaceStageCard> createState() => _RaceStageCardState();
}

class _RaceStageCardState extends State<RaceStageCard> {
  @override
  Widget build(BuildContext context) {
    CType raceType = widget.raceName == '趴板' ? CType.pronePaddle : CType.sprint;
    SType stageType;
    switch (widget.stageName) {
      case '初赛':
        stageType = SType.firstRound;
        break;
      case '八分之一决赛':
        stageType = SType.roundOf16;
        break;
      case '四分之一决赛':
        stageType = SType.quarterfinals;
        break;
      case '二分之一决赛':
        stageType = SType.semifinals;
        break;
      case '决赛':
        stageType = SType.finals;
        break;
      default:
        throw Exception('未知的比赛阶段');
    }
    // print(
    //     "开始渲染页面：${widget.division} ${widget.raceName} ${widget.stageName}, index: ${widget.index},prevStage: ${widget.prevStage}");
    return SizedBox(
      height: 100,
      child: Card(
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                // mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Icon(
                    Icons.emoji_events,
                    color: Colors.brown,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    widget.stageName,
                    style: const TextStyle(fontSize: 18),
                  ),
                  Row(
                    children: [
                      const SizedBox(
                        width: 130,
                      ),

                      /// 导出分组名单
                      ElevatedButton(
                        onPressed:

                            /// 判断是否可用的函数
                            /// 可用条件：上一步导入已完成且本步导入未完成
                            !(widget.dataState.prevImported &&
                                    !widget.dataState.currImported)
                                ? null
                                : () async {
                                    try {
                                      // print('导出待填成绩名单');
                                      String text =
                                          "正在生成${widget.division}${widget.stageName}分组名单,请耐心等待...";
                                      Loading.startLoading(text, context);

                                      /// DataHelper
                                      List<int>? excelFileBytes =
                                          await DataHelper.generateGenericExcel(
                                              widget.division,
                                              raceType,
                                              stageType,
                                              widget.dbName
                                          );
                                      if (excelFileBytes == null) {
                                        throw Exception("生成Excel失败");
                                      }
                                      Future.delayed(Duration.zero, () async {
                                        String? filePath =
                                            await FilePicker.platform.saveFile(
                                          dialogTitle:
                                              '导出${widget.division}_${widget.raceName} _${widget.stageName}分组名单(登记表)',
                                          fileName:
                                              '${widget.division}_${widget.raceName} _${widget.stageName}成绩登记表.xlsx',
                                        );
                                        if (filePath == null) {
                                          Loading.stopLoading(context);
                                          return;
                                        }
                                        File file = File(filePath);
                                        await file.writeAsBytes(excelFileBytes);
                                        // print("文件已保存到: $filePath");
                                        print(
                                            "将${widget.division}_${widget.stageName}_${widget.raceName}_downloaded设置为T");
                                        await setProgress(
                                            widget.dbName,
                                            "${widget.division}_${widget.stageName}_${widget.raceName}_downloaded",
                                            true);
                                        Loading.stopLoading(context);
                                        setState(() {});
                                        //   title: '导出${widget.division}${widget.StageName}分组名单',
                                        //   content: '成功导出${widget.division}${widget.StageName}分组名单,文件已保存到: $filePath');
                                        widget.onStatusChanged(
                                            widget.index, RaceStatus.ongoing);
                                      });
                                    } catch (e) {
                                      Loading.stopLoading(context);
                                      ErrorHandler.showErrorDialog(
                                          context,
                                          "导入失败！可能是上一步成绩导入时表格出现了问题，此问题可能无法修复，请联系开发者",
                                          e.toString());
                                      rethrow;
                                    }
                                  },
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.all<Color>(Colors.white),
                          padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                              const EdgeInsets.symmetric(
                                  horizontal: 32.0, vertical: 16.0)),
                          shape: WidgetStateProperty.all<OutlinedBorder>(
                              RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0))),
                          shadowColor:
                              WidgetStateProperty.all<Color>(Colors.black),
                          elevation: WidgetStateProperty.resolveWith<double>(
                              (Set<WidgetState> states) {
                            if (states.contains(WidgetState.hovered)) {
                              return 16.0;
                            }
                            return 4.0;
                          }),
                          overlayColor:
                              WidgetStateProperty.all<Color>(Colors.white),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.dataState.currImported ? "已导出" : "导出分组名单",
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(
                              width: 10.0,
                            ),
                            Icon(
                                widget.dataState.currImported
                                    ? Icons.check
                                    : Icons.file_download,
                                color: widget.dataState.currImported ||
                                        !widget.dataState.prevImported
                                    ? Colors.grey
                                    : Colors.black),
                          ],
                        ),
                      ),
                      const SizedBox(
                        width: 130,
                      ),

                      /// 导入成绩
                      ElevatedButton(
                        onPressed: !(widget.dataState.currDownloaded &&
                                !widget.dataState.currImported)
                            ? null
                            : () async {
                                try {
                                  /// 导入的progress变化已经在DataHelper中完成
                                  Loading.startLoading(
                                      "正在导入${widget.stageName}${widget.stageName}成绩,请耐心等待...",
                                      context);
                                  final result =
                                      await FilePicker.platform.pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: ['xlsx'],
                                    withData: true,
                                    allowMultiple: false,
                                  );
                                  if (result == null) {
                                    /// 文件为空直接取消操作
                                    Loading.stopLoading(context);
                                    return;
                                  }
                                  List<int> fileBytes =
                                      File(result.paths.first!)
                                          .readAsBytesSync();
                                  await DataHelper
                                      .importGenericCompetitionScore(
                                          widget.division,
                                          fileBytes,
                                          raceType,
                                          stageType,
                                          widget.dbName);
                                  // print("导入${widget.stageName}成绩");
                                  Loading.stopLoading(context);
                                  setState(() {});
                                  widget.onStatusChanged(
                                      widget.index, RaceStatus.completed);
                                } catch (e) {
                                  Loading.stopLoading(context);
                                  ErrorHandler.showErrorDialog(
                                      context,
                                      "导出失败！可能是成绩导入时表格出现了问题，此问题可能无法修复，请联系开发者",
                                      e.toString());
                                }
                              },
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.all<Color>(Colors.white),
                          padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                              const EdgeInsets.symmetric(
                                  horizontal: 32.0, vertical: 16.0)),
                          shape: WidgetStateProperty.all<OutlinedBorder>(
                              RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0))),
                          shadowColor:
                              WidgetStateProperty.all<Color>(Colors.black),
                          elevation: WidgetStateProperty.resolveWith<double>(
                              (Set<WidgetState> states) {
                            if (states.contains(WidgetState.hovered)) {
                              return 16.0;
                            }
                            return 3.0;
                          }),
                          overlayColor:
                              WidgetStateProperty.all<Color>(Colors.white),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                                widget.dataState.currImported
                                    ? "已导入"
                                    : "导入${widget.stageName.replaceAll('\n', '')}成绩",
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(
                              width: 10.0,
                            ),
                            Icon(
                              widget.dataState.currImported
                                  ? Icons.check
                                  : Icons.file_upload,
                              color: widget.dataState.currImported ||
                                      !widget.dataState.currDownloaded
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                          ],
                        ),
                      )
                    ],
                  )
                ],
              ))),
    );
  }
}

class DataState {
  final bool prevImported;
  final bool currImported;
  final bool currDownloaded;

  DataState(
      {required this.prevImported,
      required this.currImported,
      required this.currDownloaded});

  @override
  String toString() {
    return "prevImported: $prevImported, currImported: $currImported, currDownloaded: $currDownloaded";
  }
}
