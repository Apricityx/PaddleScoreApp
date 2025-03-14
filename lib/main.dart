import 'dart:io';

import 'package:flutter/material.dart';
import 'package:paddle_score_app/pageWidgets/appEntrances/createRacePage.dart';

// import 'package:paddle_score_app/pageWidgets/abondon/createRacePage.dart';
import 'package:paddle_score_app/pageWidgets/appEntrances/homePage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:paddle_score_app/pageWidgets/appEntrances/racesEntrance.dart';
import 'package:paddle_score_app/pageWidgets/appEntrances/racesEntrancePage.dart';
import 'package:paddle_score_app/pageWidgets/appEntrances/settingsPage.dart';
import 'package:paddle_score_app/utils/GlobalFunction.dart';
import 'package:paddle_score_app/utils/Routes.dart';
import 'package:paddle_score_app/utils/SettingService.dart';

// import 'package:paddle_score_app/page_widgets/racesEntrance.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// import '/page_widgets/homePage.dart';
// import 'page_widgets/createRacePage.dart';
import 'package:path/path.dart' as p;

void main() {
  // 确保 Flutter 绑定已初始化
  WidgetsFlutterBinding.ensureInitialized();
  SettingService.loadSettings();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MyAppState()),
        // ChangeNotifierProvider(create: (context) => RaceCardState()),
      ],
      child: MyApp(),
    ),
    // ChangeNotifierProvider(
    //   create: (context) => MyAppState(),
    //   child: MyApp(),
    // ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PaddleScore demo',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Insert this line
      supportedLocales: const [Locale("zh", "CN"), Locale("en", "US")],
      theme: ThemeData(
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.linux: OpenUpwardsPageTransitionsBuilder(),
            TargetPlatform.windows: OpenUpwardsPageTransitionsBuilder(),
            TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: OpenUpwardsPageTransitionsBuilder(),
          },
        ),
        fontFamily: 'HarmonyFont',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(),

      // todo 路由表
      routes: routes,
      onGenerateRoute: (settings) {
        if (settings.name!.startsWith('/race/')) {
          final raceName = settings.name!.substring('/race/'.length);
          return MaterialPageRoute(
            builder: (context) => RacePage(raceName: raceName),
          );
        } else if (settings.name == '/race') {
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('错误')),
              body: const Center(child: Text('请指定比赛名称')),
            ),
          );
        }
        return MaterialPageRoute(builder: (context) => UnknownRouteScreen());
      },
      // {
      //     '/home': (context) => MyHomePage(),
      //     '/race/:raceName': (context) => RacePage(raceName: '',), // 注意这里是 RacePage()，不传递参数
      //     // ...其他路由
      //   },
      // onGenerateRoute: (settings) {
      //   if (settings.name!.startsWith('/race/')) {
      //     final raceName = settings.name!.substring('/race/'.length);
      //     return MaterialPageRoute(
      //       builder: (context) => RacePage(raceName: raceName),
      //     );
      //   }
      //   return MaterialPageRoute(builder: (context) => Placeholder());//处理未知路由
      // },
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
    final filesPath = p.join(directory.path, "PaddleScoreData");
// 如果文件夹不存在，则创建
    final dir = Directory(filesPath);
    if (!dir.existsSync()) {
      dir.createSync();
    }

    final entities = Directory(filesPath).listSync();
    races = entities
        .where((entity) => entity is File && p.extension(entity.path) == '.db')
        .map((entity) => p.basenameWithoutExtension(entity.path))
        .toList();
    printDebug(races);
    notifyListeners();
  }
}

class _MyHomePageState extends State<MyHomePage> {
  bool isRailExtended = false;
  int selectedIndex = 0;

  @override
  void initState() {
    final appState = context.read<MyAppState>();
    // appState.loadRaceNames(); // 在初始化时加载数据
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
        page = const HomePageContent();
        break;
      case 1:
        page = const Placeholder();
        break;
      case 2:
        page = const SettingsPage();
        break;
      default:
        page = const Placeholder();
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
                  color: const Color(0xFFFAFAFA),
                  child: Column(
                    children: [
                      // 菜单按钮
                      Padding(
                        padding: isRailExtended
                            ? const EdgeInsets.only(top: 8, left: 0)
                            : const EdgeInsets.all(8.0),
                        child: IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () {
                            setState(() {
                              isRailExtended = !isRailExtended;
                            });
                          },
                        ),
                      ),
                      if (isRailExtended) const SizedBox(height: 16), // 导航栏
                      Expanded(
                        child: SizedBox(
                          width: isRailExtended
                              ? constraints.maxWidth * 0.15
                              : constraints.maxWidth * 0.08,
                          child: NavigationRail(
                            extended:
                                isRailExtended && constraints.maxWidth >= 600,
                            destinations: const [
                              NavigationRailDestination(
                                icon: Icon(Icons.home),
                                label: Text("首页"),
                              ),
                              NavigationRailDestination(
                                icon: Icon(Icons.access_time),
                                label: Text("历史赛事"),
                              ),
                              NavigationRailDestination(
                                icon: Icon(Icons.settings),
                                label: Text("设置"),
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

class UnknownRouteScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('404')),
      body: const Center(child: Text('页面未找到')),
    );
  }
}
