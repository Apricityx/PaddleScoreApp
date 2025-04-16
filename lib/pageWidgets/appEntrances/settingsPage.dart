import 'package:flutter/material.dart';

import '../../utils/SettingService.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Map<String, dynamic> settings = SettingService.settings;

  @override
  void initState() {
    super.initState();
  }
  final TextEditingController _shortController = TextEditingController(text: SettingService.settings['shortNumber']?.toString());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 夜间模式开关
          Card(
            child: ListTile(
              title: const Text('调试模式'),
              subtitle: const Text('调试模式下，下载成绩单时会随机生成运动员的成绩'),
              trailing: Switch(
                value: SettingService.settings['isDebugMode'],
                onChanged: (value) {
                  SettingService.updateSetting('isDebugMode', value);
                  setState(() {
                    SettingService.settings['isDebugMode'] = value;
                  });
                  SettingService.saveSettings(context);
                },
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          // 语言选择
          // Card(
          //   child: ListTile(
          //     title: const Text('短距离每组人数'),
          //     subtitle: const Text('短距离分组中，每组有多少个人'),
          //     trailing: SizedBox(
          //       width: 100, // 限制输入框宽度
          //       child: TextField(
          //         controller: _shortController, // 绑定控制器
          //         keyboardType: TextInputType.number, // 设置键盘类型为数字键盘
          //         decoration: const InputDecoration(
          //           hintText: '输入每组人数', // 提示文字
          //           errorText: null, // 动态错误提示可用来反馈用户非法输入
          //         ),
          //         onChanged: (value) {
          //           if (value.isNotEmpty && int.tryParse(value) != null) {
          //             SettingService.settings['shortNumber'] = int.parse(value);
          //             SettingService.saveSettings(context);
          //           } else {
          //             SettingService.settings['shortNumber'] = null; // 或者设置为 0 等默认值
          //             ScaffoldMessenger.of(context)
          //               ..clearSnackBars()
          //               ..showSnackBar(
          //                 const SnackBar(
          //                   content: Text('请输入正整数'),
          //                 ),
          //               );
          //           }
          //         },
          //       ),
          //     ),
          //   ),
          // )
        ],
      ),
    );
  }
}
