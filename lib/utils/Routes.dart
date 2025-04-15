import 'package:flutter/cupertino.dart';
import 'package:paddle_score_app/pageWidgets/appEntrances/settingsPage.dart';

import '../main.dart';
import '../pageWidgets/appEntrances/createRacePage.dart';
import '../pageWidgets/appEntrances/exportPage.dart';
import '../pageWidgets/appEntrances/racesEntrancePage.dart';

var routes = {
  '/home': (context) => MyHomePage(),
  // '/create': (context) => CreateRacePage(),
  '/create': (context) => CreateRacePage(), // 创建比赛页面，带参数
  '/settings': (context) => SettingsPage(),
  '/race': (context) => RacePage(raceName: '',),
  '/export': (context) => ExportPage(raceName: '',),
};
