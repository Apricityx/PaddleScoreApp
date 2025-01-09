import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:paddle_score_app/DataHelper.dart';
import 'package:paddle_score_app/pageWidgets/appEntrances/racesEntrancePage.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../utils/ExcelAnalyzer.dart';

class HomePageContent extends StatefulWidget{
  const HomePageContent({Key? key}) : super(key: key);
  @override
  State<HomePageContent> createState()=>_HomePageContent();
}

class _HomePageContent extends State<HomePageContent>{
  final _formKey = GlobalKey<FormState>();
  final _raceNameController = TextEditingController();
  FilePickerResult? _selectedFile;
  List<int> bytes = [];
  bool _isEventVisible = true;
  bool _isCreateVisible = true;

  get padding => null;

  Future<void> _pickExcelFile() async{
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
        allowMultiple: false,
      );
      if (result != null) {
        setState(() {
          _selectedFile = result;
          bytes = File(result.paths.first!).readAsBytesSync();
          // print(_selectedFile);
        });
      }
    } catch(e){
      print('Error: $e');
    }
  }

  Future<void> _submitForm() async {
    MyAppState appState3 = Provider.of<MyAppState>(context, listen: false);
    if (_formKey.currentState!.validate()){
      String raceName = _raceNameController.text;
      //处理Excel文件
      if(_selectedFile!=null && raceName.isNotEmpty) {
        if(appState3.races.contains(raceName)){
          showDialog(
            context: context,
            builder: (BuildContext context){
              return AlertDialog(
                title:const Text('赛事创建失败'),
                content:const Text('赛事名称已存在,请输入不同的赛事名称'),
                actions:[
                  TextButton(
                    onPressed: (){
                      Navigator.of(context).pop();
                    },
                    child: const Text('确认'),
                  ),
                ],
              );
            },
          );
          return;
        }else{
          showDialog(
            context: context,
            barrierDismissible: false, //点击对话框外部不关闭对话框
            builder: (BuildContext context){
              return const AlertDialog(
                content: Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width:16),
                    Text('正在处理运动员数据,请耐心等待...'),
                  ],
                ),
              );
            },
          );
          await DataHelper.loadExcelFileToAthleteDatabase(raceName,bytes);
          Navigator.of(context).pop();
        }
        appState3.addRace(_raceNameController.text);
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('赛事创建成功'),
              content: Text('赛事名称：$raceName'),
              actions: [
                TextButton(
                  onPressed: () {
                    //跳转到赛事页面
                    Navigator.of(context).pop();
                    appState3.setSelectRace(raceName);
                    Navigator.pushNamed(context, '/race/$raceName');
                  },
                  child: const Text('跳转到赛事页面'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('确认并返回'),
                ),
              ],
            );
          },
        );
      }else{
        showDialog(
            context: context,
            builder:(BuildContext context){
              return AlertDialog(
                title:const Text('赛事创建失败'),
                content:raceName.isEmpty
                    ?const Text('赛事名称不能为空')
                    :_selectedFile == null
                    ? const Text('请上传赛事人员名单')
                    :const Text('未知错误'),
                actions:[
                  TextButton(
                    onPressed:(){
                      Navigator.of(context).pop();
                    },
                    child:const Text('确认'),
                  ),
                ],
              );
            }
        );
      }
    }
  }

  void _clearFrom(){
    _formKey.currentState!.reset();
    _raceNameController.clear();
    setState(() {
      _selectedFile = null;
    });
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar:AppBar(
        title:const Text('首页'),
      ),
      body:Container(
        color:Theme.of(context).colorScheme.primaryContainer,
        width: double.infinity,
        child:

        Column(
          children: [
            const SizedBox(height: 30),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: Card(
                  color: Colors.white,
                  child: Theme(
                    data: ThemeData(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      title: const Text(
                        '欢迎使用桨板赛事计分系统',
                        style: TextStyle(fontSize: 24,fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('热门赛事进行中',style: TextStyle(fontSize: 18),),
                      trailing: Icon(_isEventVisible
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down),
                      onExpansionChanged: (bool expanded) {
                        setState(() {
                          _isEventVisible = expanded;
                        });
                      },
                      initiallyExpanded: true,
                      children: [
                        SizedBox(
                         child:ListTile(
                           title: Text(_raceNameController.text),
                           subtitle: const Text('点滴查看赛事详情'),
                           onTap: (){
                             // 跳转到 RacePage 并传递参数
                             Navigator.push(
                               context,
                               MaterialPageRoute(
                                 builder: (context) => RacePage(
                                   raceName: _raceNameController.text, // 传递赛事名称
                                ),
                             ),
                             );
                           },
                         ),
                        )
                        // ListTile(
                        //   title: Text('赛事2'),
                        //   subtitle: Text('运动员名单'),
                        // ),
                        // ListTile(
                        //   title: Text('赛事3'),
                        //   subtitle: Text('运动员名单'),
                        // ),
                      ],
                    ),
                  ),
                )
            ),

            const SizedBox(height: 30),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: Card(
                  color: Colors.white,
                  child: Theme(
                    data: ThemeData(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      title: const Text(
                        '创建赛事',
                        style: TextStyle(fontSize: 24,fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('请上传赛事名称和队员名单',style: TextStyle(fontSize: 16),),

                      trailing: Icon(_isCreateVisible
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down),
                      onExpansionChanged: (bool expanded) {
                        setState(() {
                          _isCreateVisible = expanded;
                        });
                      },
                        initiallyExpanded: true,
                        children:[
                        Container(
                          width: 650,
                          child: Form(
                            key:_formKey,
                            child:Column(
                              mainAxisSize: MainAxisSize.min,
                              // crossAxisAlignment: CrossAxisAlignmen,
                              children: [
                                TextFormField(
                                  controller:_raceNameController,
                                  decoration: const InputDecoration(labelText:'赛事名称',hintText: '请输入赛事名称'),
                                  validator:(value){
                                    if(value == null || value.isEmpty){
                                      return '请输入赛事名称';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height:40),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child:
                                  ElevatedButton(
                                    onPressed:_pickExcelFile,
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStateProperty.all<Color>(Color(0xFFBBDEFB)),
                                      // padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                                      //     EdgeInsets.symmetric(horizontal: 32.0,vertical: 16.0)
                                      // ),
                                      shape: MaterialStateProperty.all<OutlinedBorder>(
                                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0))
                                      ),
                                      shadowColor: MaterialStateProperty.all<Color>(Colors.black),
                                      elevation: MaterialStateProperty.resolveWith<double>((Set<MaterialState> states) {
                                        if (states.contains(MaterialState.hovered)) {
                                          return 16.0;
                                        }
                                        return 4.0;
                                      }),
                                      overlayColor: MaterialStateProperty.all<Color>(Colors.white),
                                    ),
                                    child:const Text('上传赛事人员名单'),
                                  ),
                                ),
                                const SizedBox(height: 40),
                                if(_selectedFile != null)
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child:Padding(
                                      padding:const EdgeInsets.only(top:8.0),
                                      child: Text('已选择文件：${_selectedFile!.files.first.name}',
                                        style: const TextStyle(fontSize: 18),),
                                    ),
                                  ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children:[
                                    OutlinedButton(
                                      onPressed:_clearFrom,
                                      style: OutlinedButton.styleFrom(
                                        textStyle: const TextStyle(fontSize: 18),
                                        padding: const EdgeInsets.symmetric(horizontal: 24,vertical: 12),
                                      ),
                                      child:const Text('清除表单',style: TextStyle(color: Colors.black),),
                                    ),
                                    const SizedBox(width: 16),
                                    OutlinedButton(
                                      onPressed:(){
                                        _submitForm();
                                      },
                                      style: OutlinedButton.styleFrom(
                                        textStyle: const TextStyle(fontSize: 18),
                                        padding: const EdgeInsets.symmetric(horizontal: 24,vertical: 12),
                                      ),
                                      child:const Text('确认创建',style: TextStyle(color: Colors.black),),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ]
                    ),
                  ),
                )
            ),
            // Padding(
            //   padding:const EdgeInsets.all(16),
            //   child:Container(
            //     width: 650,
            //     decoration: BoxDecoration(
            //       color: Colors.white,
            //       borderRadius: BorderRadius.circular(8.0),
            //       boxShadow: [
            //         BoxShadow(
            //           color: Colors.grey.withOpacity(0.5),
            //           spreadRadius: 2,
            //           blurRadius: 5,
            //           offset: const Offset(0, 3),
            //         ),
            //       ],
            //     ),
            //     padding: const EdgeInsets.all(20.0),
            //     child: Form(
            //       key:_formKey,
            //       child:Column(
            //         mainAxisSize: MainAxisSize.min,
            //         crossAxisAlignment: CrossAxisAlignment.start,
            //         children: [
            //           const Text("创建赛事",
            //             style: TextStyle(fontSize: 24,fontWeight: FontWeight.bold),),
            //           const SizedBox(width: 50,),
            //           SizedBox(
            //             width: 450,
            //             child:TextFormField(
            //               controller:_raceNameController,
            //               decoration: const InputDecoration(labelText:'赛事名称',hintText: '请输入赛事名称'),
            //               validator:(value){
            //                 if(value == null || value.isEmpty){
            //                   return '请输入赛事名称';
            //                 }
            //                 return null;
            //               },
            //             ),
            //           ),
            //
            //           const SizedBox(height:40),
            //           Align(
            //             alignment: Alignment.centerLeft,
            //             child:
            //             ElevatedButton(
            //               onPressed:_pickExcelFile,
            //               style: ElevatedButton.styleFrom(
            //                 textStyle: const TextStyle(fontSize: 18),
            //                 padding: const EdgeInsets.symmetric(horizontal: 24,vertical: 12 ),
            //               ),
            //               child:const Text('上传赛事人员名单'),
            //             ),
            //           ),
            //           const SizedBox(height: 15),
            //           if(_selectedFile != null)
            //             Align(
            //               alignment: Alignment.centerLeft,
            //               child:Padding(
            //                 padding:const EdgeInsets.only(top:8.0),
            //                 child: Text('已选择文件：${_selectedFile!.files.first.name}',
            //                   style: const TextStyle(fontSize: 18),),
            //               ),
            //             ),
            //           const SizedBox(height:39),
            //           Row(
            //             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            //             children:[
            //               ElevatedButton(
            //                 onPressed:_clearFrom,
            //                 style: ElevatedButton.styleFrom(
            //                   textStyle: const TextStyle(fontSize: 18),
            //                   padding: const EdgeInsets.symmetric(horizontal: 24,vertical: 12),
            //                 ),
            //                 child:const Text('清空'),
            //               ),
            //               const SizedBox(width: 16),
            //               ElevatedButton(
            //                 onPressed:(){
            //                   _submitForm();
            //                 },
            //                 style: ElevatedButton.styleFrom(
            //                   textStyle: const TextStyle(fontSize: 18),
            //                   padding: const EdgeInsets.symmetric(horizontal: 24,vertical: 12),
            //                 ),
            //                 child:const Text('确认'),
            //               ),
            //             ],
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}