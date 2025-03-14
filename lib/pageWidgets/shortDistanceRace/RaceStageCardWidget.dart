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
                  Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            color: Colors.brown,
                          ),
                          Text(
                            widget.stageName,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],
                      )),
                  Expanded(
                      flex: 8,
                      child: Row(
                        children: [
                          /// 导出分组名单
                          Expanded(
                            flex: 4,
                            child: ElevatedButton(
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
                                                await DataHelper
                                                    .generateGenericExcel(
                                                        widget.division,
                                                        raceType,
                                                        stageType,
                                                        widget.dbName);
                                            if (excelFileBytes == null) {
                                              throw Exception("生成Excel失败");
                                            }
                                            Future.delayed(Duration.zero,
                                                () async {
                                              String? filePath =
                                                  await FilePicker.platform
                                                      .saveFile(
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
                                              await file
                                                  .writeAsBytes(excelFileBytes);
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
                                                  widget.index,
                                                  RaceStatus.ongoing);
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
                                backgroundColor: WidgetStateProperty.all<Color>(
                                    Colors.white),
                                padding:
                                    WidgetStateProperty.all<EdgeInsetsGeometry>(
                                        const EdgeInsets.symmetric(
                                            horizontal: 32.0, vertical: 16.0)),
                                shape: WidgetStateProperty.all<OutlinedBorder>(
                                    RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0))),
                                shadowColor: WidgetStateProperty.all<Color>(
                                    Colors.black),
                                elevation:
                                    WidgetStateProperty.resolveWith<double>(
                                        (Set<WidgetState> states) {
                                  if (states.contains(WidgetState.hovered)) {
                                    return 16.0;
                                  }
                                  return 4.0;
                                }),
                                overlayColor: WidgetStateProperty.all<Color>(
                                    Colors.white),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.dataState.currImported
                                        ? "已导出"
                                        : "导出分组名单",
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
                          ),
                          Expanded(flex: 1, child: const SizedBox()),

                          /// 导入成绩
                          Expanded(
                              flex: 4,
                              child: ElevatedButton(
                                onPressed: !(widget.dataState.currDownloaded &&
                                        !widget.dataState.currImported)
                                    ?

                                    /// 判断是否可修改
                                    /// 如果下一步已经导入，则不支持修改
                                    (!widget.dataState.currDownloaded ||
                                            widget.dataState.nextImported
                                        ? null
                                        : () async {
                                            /// 修改成绩 todo
                                            print("尝试修改成绩");
                                            bool confirm = false;
                                            /// 弹出对话框警告用户修改成绩后需要重新导出下一场比赛的分组名单
                                            /// 确认后执行修改操作
                                            await showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    title: Row(
                                                      children: const [
                                                        Icon(Icons.warning),
                                                        Text(" 提示"),
                                                      ],
                                                    ),
                                                    content: const Text(
                                                        "修改成绩后请重新导出下一场比赛的分组名单，以更新分组与站位"),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                          confirm = false;
                                                        },
                                                        child: const Text("取消"),
                                                      ),
                                                      TextButton(
                                                        onPressed: () async {
                                                          Navigator.of(context)
                                                              .pop();
                                                          confirm = true;
                                                        },
                                                        child: const Text("确认"),
                                                      ),
                                                    ],
                                                  );
                                                });
                                            if (!confirm) {
                                              return;
                                            }
                                            Loading.startLoading("正在修改运动员数据，请稍候", context);
                                            FilePickerResult?
                                            result =
                                            await FilePicker
                                                .platform
                                                .pickFiles(
                                              type:
                                              FileType.custom,
                                              allowedExtensions: [
                                                'xlsx'
                                              ],
                                              withData: true,
                                              allowMultiple:
                                              false,
                                            );
                                            if (result == null) {
                                              Loading.stopLoading(context);
                                              return;
                                            }
                                            List<int> fileBytes =
                                            File(result.paths
                                                .first!)
                                                .readAsBytesSync();
                                            try{
                                              await DataHelper
                                                  .modifyGenericCompetitionScore(
                                                  widget
                                                      .division,
                                                  raceType,
                                                  stageType,
                                                  widget.dbName,
                                                  fileBytes);
                                              SnackBar snackBar = SnackBar(
                                                content: Text("修改成功"),
                                                duration: const Duration(seconds: 2),
                                              );
                                              ScaffoldMessenger.of(context).showSnackBar(snackBar);
                                            }
                                            catch (e) {
                                              Loading.stopLoading(context);
                                              ErrorHandler.showErrorDialog(
                                                  context,
                                                  "导入失败！可能是成绩导入时表格出现了问题，此问题可能无法修复，请联系开发者",
                                                  e.toString());
                                              rethrow;
                                            }
                                            Loading.stopLoading(context);
                                          })
                                    : () async {
                                        try {
                                          /// 导入的progress变化已经在DataHelper中完成
                                          Loading.startLoading(
                                              "正在导入${widget.stageName}${widget.stageName}成绩,请耐心等待...",
                                              context);
                                          final result = await FilePicker
                                              .platform
                                              .pickFiles(
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
                                          await Loading.stopLoading(context);
                                          setState(() {});
                                          widget.onStatusChanged(widget.index,
                                              RaceStatus.completed);
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
                                      WidgetStateProperty.all<Color>(
                                          Colors.white),
                                  padding: WidgetStateProperty.all<
                                          EdgeInsetsGeometry>(
                                      const EdgeInsets.symmetric(
                                          horizontal: 32.0, vertical: 16.0)),
                                  shape:
                                      WidgetStateProperty.all<OutlinedBorder>(
                                          RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0))),
                                  shadowColor: WidgetStateProperty.all<Color>(
                                      Colors.black),
                                  elevation:
                                      WidgetStateProperty.resolveWith<double>(
                                          (Set<WidgetState> states) {
                                    if (states.contains(WidgetState.hovered)) {
                                      return 16.0;
                                    }
                                    return 3.0;
                                  }),
                                  overlayColor: WidgetStateProperty.all<Color>(
                                      Colors.white),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                        widget.dataState.currImported
                                            ?

                                            /// 如果下一场已经导入，则不支持修改
                                            widget.dataState.nextImported
                                                ? "已导入"
                                                : "修改成绩"
                                            : "导入${widget.stageName.replaceAll('\n', '')}成绩",
                                        style: const TextStyle(fontSize: 16)),
                                    const SizedBox(
                                      width: 10.0,
                                    ),
                                    Icon(
                                      widget.dataState.currImported
                                          ? widget.dataState.nextImported
                                              ? Icons.check
                                              : Icons.edit
                                          : Icons.file_upload,
                                      color: widget.dataState.currImported ||
                                              !widget.dataState.currDownloaded
                                          ? widget.dataState.nextImported
                                              ? Colors.grey
                                              : Colors.black
                                          : Colors.black,
                                    ),
                                  ],
                                ),
                              ))
                        ],
                      ))
                ],
              ))),
    );
  }
}

class DataState {
  final bool prevImported;
  final bool currImported;
  final bool currDownloaded;
  final bool nextImported;

  DataState(
      {required this.prevImported,
      required this.currImported,
      required this.currDownloaded,
      required this.nextImported});

  @override
  String toString() {
    return "prevImported: $prevImported, currImported: $currImported, currDownloaded: $currDownloaded";
  }
}
