import 'package:flutter/material.dart';

class MatchList extends StatelessWidget {
  const MatchList({super.key});

  @override
  Widget build(BuildContext context) {
    final items = ['Item 1', 'Item 2', 'Item 3'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('title'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              print(1); // 点击加号时输出1
            },
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text('Map'),
            onTap: () {
              print(2); // 点击列表项时输出2
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_album),
            title: const Text('Album'),
            onTap: () {
              print(2); // 点击列表项时输出2
            },
          ),
          ListTile(
            leading: const Icon(Icons.phone),
            title: const Text('Phone'),
            onTap: () {
              print(2); // 点击列表项时输出2
            },
          ),
        ],
      ),
    );
  }
}