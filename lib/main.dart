import 'dart:io';

import 'package:flutter/material.dart';
import 'package:paddle_score_app/pageWidgets/appEntrances/createRacePage.dart';
import 'package:paddle_score_app/pageWidgets/appEntrances/homePage.dart';
// import 'package:paddle_score_app/pageWidgets/appEntrances/racesEntrance.dart';
import 'package:paddle_score_app/pageWidgets/appEntrances/racesEntrancePage.dart';
// import 'package:paddle_score_app/page_widgets/racesEntrance.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// import '/page_widgets/homePage.dart';
// import 'page_widgets/createRacePage.dart';
import 'package:path/path.dart' as p;

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  runApp(
    ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PaddleScore demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => MyAppState()),
          ChangeNotifierProvider(create: (context) => RaceCardState()),
        ],
        child: MyHomePage(),
      ),
      routes: {
        '/home': (context) => MyHomePage(),
        '/create': (context) => CreateRacePage(),
        // '/race/:raceName': (context) {
        //   final raceName = ModalRoute.of(context)!.settings.arguments as String;
        //   return RacePage(raceName: raceName);
        // }
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class MyAppState extends ChangeNotifier {
  String selectedRace = '';

  String get raceName => selectedRace;
  List<String> races = [];
  int createCount = 0;

  void addRace(String raceName) {
    races.add(raceName);
    createCount++;
    notifyListeners();
  }

  void setSelectRace(String raceName) {
    selectedRace = raceName;
    notifyListeners();
  }

  Future<void> loadRaceNames() async {
    final directory = await getApplicationDocumentsDirectory();
    final filesPath = p.join(directory.path, 'PaddleScoreData');
    final entities = Directory(filesPath).listSync();
    races = entities
        .where((entity) => entity is File && p.extension(entity.path) == '.db')
        .map((entity) => p.basenameWithoutExtension(entity.path))
        .toList();
    notifyListeners();
  }
}

class _MyHomePageState extends State<MyHomePage> {
  bool isRailExtended = false;
  int selectedIndex = 0;

  @override
  void initState() {
    final appState = context.read<MyAppState>();
    appState.loadRaceNames(); // 在初始化时加载数据
  }
  void navigateToPage(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    // appState.loadRaceNames();
    Widget page;
    int size = appState.races.length;
    switch (selectedIndex) {
      case 0:
        page = HomePageContent() as Widget;
        break;
      case 1:
        page = Placeholder() as Widget;
        break;
      default:
        page = Placeholder() as Widget;
      // case 2:
      //   page = CreateRacePage();
      //   break;
      // default:
      //   page = RacePage(raceName: appState.races[size - selectedIndex + 2])
      //   as Widget;
      //   break;
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: Container(
                  color: Color(0xFFFAFAFA),
                  child: Column(
                    children: [
                      // 菜单按钮
                      Padding(
                        padding: isRailExtended?
                        const EdgeInsets.only(top: 8, left:0)
                            :EdgeInsets.all(8.0),
                        child: IconButton(
                          icon: Icon(Icons.menu),
                          onPressed: () {
                            setState(() {
                              isRailExtended = !isRailExtended;
                            });
                          },
                        ),
                      ),
                      if (isRailExtended) const SizedBox(height: 16),                       // 导航栏
                      Expanded(
                        child: SizedBox(
                          width: isRailExtended ? constraints.maxWidth*0.15 : constraints.maxWidth*0.08,
                          child: NavigationRail(
                            extended: isRailExtended && constraints.maxWidth >= 600,
                            destinations: const [
                              NavigationRailDestination(
                                icon: Icon(Icons.home),
                                label: Text("首页"),
                              ),
                              NavigationRailDestination(
                                icon: Icon(Icons.access_time),
                                label: Text("历史赛事"),
                              ),
                            ],
                            selectedIndex: selectedIndex,
                            onDestinationSelected: (value) {
                              setState(() {
                                selectedIndex = value;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 主内容区域
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: page,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}