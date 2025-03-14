import 'package:flutter/material.dart';
class Loading{
  static Future startLoading(String text,context){
    return showDialog(
        context: context,
        barrierDismissible: false, // 点击外部不可关闭
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Text(text),
              ],
            ),
          );
        });
  }
  static stopLoading(context) {
    Navigator.of(context).pop();
  }
}

