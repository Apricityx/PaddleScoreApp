import 'package:flutter/material.dart';

class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  _ExportPage createState() => _ExportPage();
}

class _ExportPage extends State<ExportPage> {

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: const Text('导出'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('导出功能尚未实现'),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('返回'),
            ),
          ],
        ),
      ),
    );
  }
}
