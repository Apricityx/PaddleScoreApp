import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:paddle_score_app/utils/GlobalFunction.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  late Widget searchBar;
  String _selectedDivision = 'U9组男子';
  String _searchText = '';
  final _typeAheadController = TextEditingController();
  List<RaceState> _raceStates = [];

  // bool _isLoading = true;

  @override
  void initState() {
    // super.initState();

    // _loadRaceStates();
    if (widget.raceBar.contains('趴板')) {
      divisions =
          divisions.where((division) => division.startsWith('U')).toList();
    }

    /// 生成搜索框
    void performSearch(String searchText) {
      final matchedDivision = divisions.firstWhere(
        (division) => division.contains(searchText),
        orElse: () => '',
      );
      setState(() {
        _selectedDivision = matchedDivision;
        _searchText = searchText;
      });
    }

    searchBar = Row(
      children: [
        Expanded(
          child: TypeAheadField(
            textFieldConfiguration: TextFieldConfiguration(
                decoration: InputDecoration(
                  hintText: '搜索组别',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search),
                  // suffixIcon: IconButton(
                  //   icon:const Icon(Icons.search),
                  //   onPressed: (){
                  //     performSearch(_typeAheadController.text);
                  //   },
                  // ),
                ),
                controller: _typeAheadController,
                onSubmitted: (text) {
                  performSearch(text);
                }),
            suggestionsCallback: (pattern) {
              return divisions
                  .where((division) => division.contains(pattern))
                  .toList();
            },
            itemBuilder: (context, suggestion) {
              return ListTile(
                  title: Text(suggestion),
                  onTap: () {
                    _typeAheadController.text = suggestion;
                    performSearch(suggestion);
                  });
            },
            onSuggestionSelected: (suggestion) {
              setState(() {
                _selectedDivision = suggestion;
                _searchText = suggestion;
                _typeAheadController.text = suggestion;
              });
            },
          ),
        ),
        // SizedBox(
        //   height: 40,
        //   child:ElevatedButton(
        //       onPressed: (){
        //         performSearch(_typeAheadController.text);
        //       },
        //       child: const Text('搜索'),
        //   ),
        // ),
      ],
    );

    /// init end
  }

  Future<void> _loadRaceStates() async {
    final prefs = await SharedPreferences.getInstance();
    final raceStatesJson = prefs.getStringList('$_selectedDivision-raceStates');
    if (raceStatesJson != null) {
      setState(() {
        _raceStates = raceStatesJson
            .map((json) => RaceState.fromJson(jsonDecode(json)))
            .toList();
      });
    } else {
      _raceStates = await getRaceProcess(_selectedDivision);
      _saveRaceStates();
    }
  }

  Future<List<RaceState>> _getRaceStates() async {
    return _raceStates;
  }

  Future<void> _saveRaceStates() async {
    final prefs = await SharedPreferences.getInstance();
    final raceSatesJson =
        _raceStates.map((raceState) => jsonEncode(raceState.toJson())).toList();
    await prefs.setStringList('$_selectedDivision-raceSates', raceSatesJson);
  }

  void _onRaceStageStatusChanged(int index, RaceStatus newStatus) {
    setState(() {
      // _raceStates[index] = _raceStates[index].copyWith(status: newStatus);
    });
    // setState(() {
    // });
    // _saveRaceStates();
  }

  Map<String, bool> _hoveringStates = {};

  Widget createNavi(String text) {
    _hoveringStates[text] = _hoveringStates[text] ?? false;
    final isSearchResult = _searchText.isNotEmpty && text.contains(_searchText);
    final isHover = _hoveringStates[text]!;
    final isSelected = _selectedDivision == text;
    return MouseRegion(
      onExit: (event) {
        setState(() {
          _hoveringStates[text] = false;
        });
      },
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedDivision = text;
            _searchText = '';
          });
        },
        onHover: (isHovering) {
          if (!isSelected) {
            setState(() {
              _hoveringStates[text] = isHovering;
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 10),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
            boxShadow: isHover || isSelected || isSearchResult == text
                ? [
                    const BoxShadow(color: Colors.black),
                  ]
                : [],
            color: isSelected || isSearchResult
                ? Colors.black
                : isHover
                    ? Colors.purple[50] // 悬浮时设置为紫色
                    : null, // 其他情况为默认颜色
          ),
          child: ListTile(
            title: Text(
              text,
              style: TextStyle(
                color: isSelected || isSearchResult
                    ? Colors.white
                    : isHover
                        ? Colors.black // 悬浮时设置为黑色
                        : Colors.black,
              ),
            ),
            iconColor: isSelected || isSearchResult
                ? Colors.white // 选中或搜索结果时设置为白色
                : isHover
                    ? Colors.black // 悬浮时设置为黑色
                    : Colors.black,
            // leading: const Icon(Icons.sports_motorsports),
            leading: const Icon(Icons.label_outline),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            tileColor: isSelected || isSearchResult
                ? Colors.black
                : isHover
                    ? Colors.purple[50] // 悬浮时设置为紫色
                    : null,
            selected: _selectedDivision == text,
            selectedTileColor: Colors.black,
          ),
        ),
      ),
    );
  }

  /// 用于获取比赛的场数
  Future<List<RaceState>> getRaceProcess(String division) async {
    int athleteCount = await getAthleteCountByDivision(
        widget.raceEventName, _selectedDivision);
    // totalAccount = athleteCount;
    if (athleteCount <= 16) {
      // raceAccount = 1;
      return [
        RaceState(name: "决赛", status: RaceStatus.notStarted),
      ];
    } else if (athleteCount > 16 && athleteCount <= 64) {
      // raceAccount = 2;
      return [
        RaceState(name: '初赛', status: RaceStatus.notStarted),
        RaceState(name: '决赛', status: RaceStatus.notStarted),
      ];
    } else if (athleteCount > 64 && athleteCount <= 128) {
      // raceAccount = 3;
      return [
        RaceState(name: '初赛', status: RaceStatus.notStarted),
        RaceState(name: '1/2\n决赛', status: RaceStatus.notStarted),
        RaceState(name: '决赛', status: RaceStatus.notStarted),
      ];
    } else {
      // raceAccount = 4;
      return [
        RaceState(name: "初赛", status: RaceStatus.notStarted),
        RaceState(name: "1/4\n决赛", status: RaceStatus.notStarted),
        RaceState(name: "1/2\n决赛", status: RaceStatus.notStarted),
        RaceState(name: "决赛", status: RaceStatus.notStarted)
      ];
    }
  }

  /// 构建组件
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      appBar: AppBar(
        title: Text(widget.raceBar),
      ),
      body: Stack(
        children: [
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Expanded(
                      child: SizedBox(
                          // width: 200,
                          child: Container(
                        decoration: const BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey,
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: Offset(3, 3),
                              )
                            ]),

                        /// 可能会出问题的判断
                            /// 问题出在这里 todo
                        child: widget.raceBar.contains('趴板') // todo fixme 不能写死
                            ? ListView(children: [
                                createNavi('U9组男子'),
                                createNavi('U9组女子'),
                                createNavi('U12组男子'),
                                createNavi('U12组女子'),
                                createNavi('U15组男子'),
                                createNavi('U15组女子'),
                                createNavi('U18组男子'),
                                createNavi('U18组女子'),
                              ])
                            : ListView(
                                children: [
                                  createNavi('U9组男子'),
                                  createNavi('U9组女子'),
                                  createNavi('U12组男子'),
                                  createNavi('U12组女子'),
                                  createNavi('U15组男子'),
                                  createNavi('U15组女子'),
                                  createNavi('U18组男子'),
                                  createNavi('U18组女子'),
                                  createNavi('充气板组男子'),
                                  createNavi('充气板组女子'),
                                  createNavi('大师组男子'),
                                  createNavi('大师组女子'),
                                  createNavi('高校甲组男子'),
                                  createNavi('高校甲组女子'),
                                  createNavi('高校乙组男子'),
                                  createNavi('高校乙组女子'),
                                  createNavi('卡胡纳组男子'),
                                  createNavi('卡胡纳组女子'),
                                  createNavi('公开组男子'),
                                  createNavi('公开组女子'),
                                ],
                              ),
                      )),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 5,
                // child: _buildContent(_selectedDivision),
                /// 开始构建内容
                child: _buildContent(_selectedDivision),
              ),
            ],
          ),
          Positioned(
              top: 16,
              right: 16,
              child: SizedBox(
                width: 200,
                height: 40,
                child: searchBar,
              ))
        ],
      ),
    );
  }

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
                "$_selectedDivision赛事进度",
                style: const TextStyle(fontSize: 18),
              ),
              subtitle: FutureBuilder(future: () async {
                /// 获取当前组别的运动员总数和比赛轮数
                final athleteCount = await getAthleteCountByDivision(
                    widget.raceEventName, _selectedDivision);
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
                Stack(
                  children: [
                    // 进度条居中显示
                    // Center(
                    //   child: RaceTimeline(
                    //       raceStates: _getRaceStates(),
                    //       onStatusChanged: _onRaceStageStatusChanged),
                    // ),
                    // 图例位于右下角，并且距离边框留有一定的间距
                    Positioned(
                      bottom: 10.0, // 设置距离底部的间距
                      right: 50.0, // 设置距离右边的间距
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        // 让文本右对齐
                        children: [
                          Text("🔵 赛事进行中"),
                          Text("🟢 赛事已完成"),
                          Text("⚪ 赛事未开始"),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        )),
      ),
      // if (!_isLoading) todo 不知道这个是干啥的
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50),
        // 2025.2.9 更换为FutureBuilder
        child: FutureBuilder(
            future: getRaceProcess(_selectedDivision),
            builder: (BuildContext context,
                AsyncSnapshot<List<RaceState>> snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return IgnorePointer(
                  ignoring: snapshot.data!.isEmpty,
                  child: SizedBox(
                    height: snapshot.data!.length * 100,
                    child: ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        /// 动态生成比赛阶段卡片 todo 并不是这里导致重复渲染
                        return RaceStageCard(
                            stageName: snapshot.data![index].name,
                            raceName:
                                widget.raceBar.contains('趴板') ? '趴板' : '竞速',
                            division: _selectedDivision,
                            dbName: widget.raceEventName,
                            index: index,
                            onStatusChanged: _onRaceStageStatusChanged);
                      },
                    ),
                  ),
                );
              } else {
                return const CircularProgressIndicator();
              }
            }),
      ),
    ]);
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
