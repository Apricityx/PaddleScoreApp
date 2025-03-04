import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:paddle_score_app/utils/GlobalFunction.dart';
import 'package:provider/provider.dart';

import 'RaceStageCardWidget.dart';
import 'RaceStateWidget.dart';

class ShortDistancePage extends StatefulWidget {
  final String raceBar;
  final String raceEventName;

  const ShortDistancePage(
      {super.key, required this.raceBar, required this.raceEventName});

  @override
  State<ShortDistancePage> createState() => _SprintRacePageState();
}

class _SprintRacePageState extends State<ShortDistancePage> {
  /// 用于获取左侧的组别列表
  /// 参数为是否为青少年组独占的比赛
  /// 返回值为组别名组成的列表
  Future<List<String>> _getListDivisions(bool hasTeens) async {
    var divisions = await getDivisions(widget.raceEventName);
    if (hasTeens) {
      divisions =
          divisions.where((element) => element.startsWith('U')).toList();
    } else {
      divisions = divisions.toList();
    }
    return divisions;
  }

  /// 搜索框使用的组别列表
  List<String> divisions = [
    'U9组男子',
    'U9组女子',
    'U12组男子',
    'U12组女子',
    'U15组男子',
    'U18组男子',
    'U18组女子',
    '充气板组男子',
    '充气板组女子',
    '大师组男子',
    '大师组女子',
    '高校甲组男子',
    '高校甲组女子',
    '高校乙组男子',
    '高校乙组女子',
    '卡胡纳组男子',
    '卡胡纳组女子',
    '公开组男子',
    '公开组女子',
  ];

  // late Widget searchBar;

  // String _selectedDivision = 'U9组男子';
  final _typeAheadController = TextEditingController();

  // bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // _loadRaceStates();
    if (widget.raceBar.contains('趴板')) {
      /// todo 草率至极的判断 通过raceBar判断是否为趴板比赛
      divisions =
          divisions.where((division) => division.startsWith('U')).toList();
    }

    /// init end
  }

  void _onRaceStageStatusChanged(int index, RaceStatus newStatus) {
    setState(() {
      // _raceStates[index] = _raceStates[index].copyWith(status: newStatus);
    });
    // setState(() {
    // });
    // _saveRaceStates();
  }

  /// 用于获取比赛的场数
  Future<List<String>> getRaceProcess(String division) async {
    int athleteCount =
        await getAthleteCountByDivision(widget.raceEventName, division);
    // totalAccount = athleteCount;
    /// 获取比赛类别 趴板 or 竞速
    CType c;
    if (widget.raceBar.contains('趴板')) {
      c = CType.pronePaddle;
    } else {
      c = CType.sprint;
    }

    /// 查询该比赛类别的分组人数
    int athleteCountPerGroup =
        await getAthleteCountPerGroup(widget.raceEventName, c);
    printDebug("$c分组人数:$athleteCountPerGroup");

    if (athleteCount <= athleteCountPerGroup) {
      // raceAccount = 1;
      return ["决赛"];
    } else if (athleteCount > athleteCountPerGroup &&
        athleteCount <= athleteCountPerGroup * 4) {
      // raceAccount = 2;
      return ["初赛", "决赛"];
    } else if (athleteCount > athleteCountPerGroup * 4 &&
        athleteCount <= athleteCountPerGroup * 8) {
      // raceAccount = 3;
      return ["初赛", "二分之一决赛", "决赛"];
    } else {
      // raceAccount = 4;
      return ["初赛", "四分之一决赛", "二分之一决赛", "决赛"];
    }
  }

  /// 构建组件
  @override
  Widget build(BuildContext context) {
    /// 搜索框执行搜索操作
    void performSearch(String searchText, BuildContext context) {
      final matchedDivision = divisions.firstWhere(
        (division) => division.contains(searchText),
        orElse: () => '',
      );
      Provider.of<RightStateNotifier>(context, listen: false)
          .setDivision(matchedDivision);
    }

    return ChangeNotifierProvider<RightStateNotifier>(
        create: (_) => RightStateNotifier(),
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          appBar: AppBar(
            title: Text(widget.raceBar),
          ),
          body: Stack(
            children: [
              Row(
                children: [
                  /// 左侧内容
                  leftWidget(),

                  /// 右侧内容
                  Consumer<RightStateNotifier>(
                    builder: (context, notifier, child) {
                      return Expanded(
                        flex: 5,
                        // child: _buildContent(_selectedDivision),
                        /// 开始构建内容
                        child: _buildContent(notifier._selectedDivision),
                      );
                    },
                  ),
                ],
              ),

              /// 搜索框
              Builder(
                builder: (context) {
                  /// 此处为context的副本，是必须的，后边搜索框组件build后context会丢失Provider属性
                  BuildContext tempContext = context;
                  return Positioned(
                      top: 16,
                      right: 16,
                      child: SizedBox(
                        width: 200,
                        height: 40,
                        child: Row(
                          children: [
                            /// 搜索框
                            Expanded(
                                child: TypeAheadField<String>(
                              suggestionsCallback: (pattern) {
                                return divisions
                                    .where((division) =>
                                        division.contains(pattern))
                                    .toList();
                              },
                              builder: (context, controller, focusNode) {
                                return TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  onSubmitted: (text) {
                                    performSearch(text, tempContext);
                                  },
                                  decoration: InputDecoration(
                                    hintText: '搜索组别',
                                  ),
                                );
                              },
                              itemBuilder: (context, suggestion) => ListTile(
                                title: Text(suggestion),
                                onTap: () {
                                  _typeAheadController.text = suggestion;
                                  performSearch(suggestion, tempContext);
                                },
                              ),
                              onSelected: (suggestion) {
                                _typeAheadController.text = suggestion;
                                performSearch(suggestion, tempContext);
                              },
                            )),
                          ],
                        ),
                      ));
                },
              ),
            ],
          ),
        ));
  }

  /// build end

  /// 根据division构建内容
  Widget _buildContent(String division) {
    // final raceProcess = getRaceProcess(division);
    return Column(children: [
      const SizedBox(
        height: 80,
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50),
        child: Card(
            child: Column(
          children: [
            ExpansionTile(
              leading: FaIcon(
                FontAwesomeIcons.safari,
                color: Colors.purple[200],
              ),
              title: Text(
                "$division赛事进度",
                style: const TextStyle(fontSize: 18),
              ),
              subtitle: FutureBuilder(future: () async {
                /// 获取当前组别的运动员总数和比赛轮数
                final athleteCount = await getAthleteCountByDivision(
                    widget.raceEventName, division);
                final raceCount = getRaceCountByAthleteCount(athleteCount);
                return [athleteCount, raceCount]; // 返回一个列表，包含两个值
              }(), builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Text('共${snapshot.data![0]}人，${snapshot.data![1]}轮比赛');
                } else {
                  return const Text('共--人，--轮比赛');
                }
              }),
              children: const [
                Text("Under Construction"),
                // Stack(
                //   children: [
                //     // 进度条居中显示
                //     // Center(
                //     //   child: RaceTimeline(
                //     //       raceStates: _getRaceStates(),
                //     //       onStatusChanged: _onRaceStageStatusChanged),
                //     // ),
                //     // 图例位于右下角，并且距离边框留有一定的间距
                //     Positioned(
                //       bottom: 10.0, // 设置距离底部的间距
                //       right: 50.0, // 设置距离右边的间距
                //       child: Column(
                //         crossAxisAlignment: CrossAxisAlignment.end,
                //         // 让文本右对齐
                //         children: [
                //           Text("🔵 赛事进行中"),
                //           Text("🟢 赛事已完成"),
                //           Text("⚪ 赛事未开始"),
                //         ],
                //       ),
                //     ),
                //   ],
                // ),
              ],
            ),
          ],
        )),
      ),
      // if (!_isLoading) todo 不知道这个是干啥的
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50),
        // 2025.2.9 更换为FutureBuilder
        child: FutureBuilder(future: () async {
          var raceType = widget.raceBar.contains('趴板') ? '趴板' : '竞速';
          var raceNames = await getRaceProcess(division);
          printDebug(raceNames);

          /// 返回一个List,为每一个比赛阶段的名称
          List raceData = [];
          for (var i = 0; i < raceNames.length; i++) {
            try {
              DataState dataState;
              // 两种情况,一种为初赛,一种为决赛
              printDebug("i = $i");
              printDebug("raceNames[i] = ${raceNames[i]}");
              if (i == 0) {
                dataState = DataState(
                    prevImported: true,
                    currDownloaded: await checkProgress(widget.raceEventName,
                        "${division}_${raceNames[0]}_${raceType}_downloaded"),
                    currImported: await checkProgress(widget.raceEventName,
                        "${division}_${raceNames[0]}_${raceType}_imported"));
              } else {
                dataState = DataState(
                    prevImported: await checkProgress(widget.raceEventName,
                        "${division}_${raceNames[i - 1]}_${raceType}_imported"),
                    currDownloaded: await checkProgress(widget.raceEventName,
                        "${division}_${raceNames[i]}_${raceType}_downloaded"),
                    currImported: await checkProgress(widget.raceEventName,
                        "${division}_${raceNames[i]}_${raceType}_imported"));
              }

              /// List的格式
              raceData.add({'name': raceNames[i], 'states': dataState});
              printDebug(raceData);
            } catch (e) {
              printDebug(e.toString());
            }
          }
          printDebug(raceData.toString());
          return raceData;
        }(), builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return SizedBox(
              height: snapshot.data!.length * 100,
              child: ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  /// 动态生成比赛阶段卡片
                  /// 需要信息:
                  return RaceStageCard(
                    stageName: snapshot.data![index]["name"],
                    raceName: widget.raceBar.contains('趴板') ? '趴板' : '竞速',
                    division: division,
                    dbName: widget.raceEventName,
                    index: index,
                    onStatusChanged: _onRaceStageStatusChanged,
                    dataState: snapshot.data![index]["states"],

                    /// 一组信息
                  );
                },
              ),
            );
          } else {
            return const CircularProgressIndicator();
          }
        }),
      ),
    ]);
  }

  /// 左侧的组件，此组件一旦渲染就不必再次渲染
  Widget leftWidget() {
    return Expanded(
      flex: 1,
      child: Column(
        children: [
          Expanded(
            child: SizedBox(
                // width: 200,
                child: Material(
                    child: widget.raceBar.contains('趴板')

                        /// 草率的判断
                        ? FutureBuilder(
                            future: _getListDivisions(true),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.done) {
                                return ListView.builder(
                                  itemCount: snapshot.data!.length,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      title: Text(snapshot.data![index]),
                                      hoverColor: Colors.grey[200],
                                      onTap: () {
                                        printDebug(
                                            '点击了 ${snapshot.data![index]}');
                                        Provider.of<RightStateNotifier>(context,
                                                listen: false)
                                            .setDivision(snapshot.data![index]);
                                      },
                                    );
                                  },
                                );
                              } else {
                                return const CircularProgressIndicator();
                              }
                            })
                        : FutureBuilder(
                            future: _getListDivisions(false),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.done) {
                                return ListView.builder(
                                  itemCount: snapshot.data!.length,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      hoverColor: Colors.grey[200],
                                      title: Text(snapshot.data![index]),
                                      onTap: () {
                                        printDebug(
                                            '点击了 ${snapshot.data![index]}');
                                        Provider.of<RightStateNotifier>(context,
                                                listen: false)
                                            .setDivision(snapshot.data![index]);
                                      },
                                    );
                                  },
                                );
                              } else {
                                return const CircularProgressIndicator();
                              }
                            }))),
          ),
        ],
      ),
    );
  }
}

/// 用于右侧的状态管理
class RightStateNotifier extends ChangeNotifier {
  String _selectedDivision = '请在左边选择';

  void setDivision(String division) {
    _selectedDivision = division;
    notifyListeners();
  }
}
// FutureBuilder( // todo 这个futureBuilder貌似没起任何作用
//   future: raceProcess,
//   builder: (context, snapshot) {
//     if (snapshot.hasData) {
//       _raceStates = snapshot.data!;
//       _isLoading = false;
//       // setState(() {});
//       return const SizedBox.shrink();
//     } else if (snapshot.hasError) {
//       return Text('Error:${snapshot.error}');
//     } else {
//       return const CircularProgressIndicator();
//     }
//   },
