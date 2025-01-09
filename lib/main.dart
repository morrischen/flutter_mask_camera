import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_mask_camera/camera/camera_mixin.dart';
import 'package:flutter_mask_camera/camera_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

/// Logger紀錄過濾器
final kLogger = Logger(
    printer: PrettyPrinter(
        dateTimeFormat: DateTimeFormat.dateAndTime,
        methodCount: 8,
        errorMethodCount: 8));

late List<CameraDescription> kCamera;

void main() {
  runApp(const ProviderScope(
    child: CameraApp(),
  ));
}

/// CameraApp is the Main Application.
class CameraApp extends StatefulWidget {
  /// Default Constructor
  const CameraApp({super.key});

  @override
  State<CameraApp> createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      title: 'Flutter Mask Camera',
      theme: ThemeData.light(),
      home: const MyHomePage(title: 'Flutter Mask Camera'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({required this.title, super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with CameraMixin {
  File? _imageFile;
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(children: [
          IconButton(
            icon: const Icon(Icons.camera_alt, size: 64),
            onPressed: () => _takePicture(),
          ),
          if (_imageFile != null) Image.file(_imageFile!),
        ]),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  /// 開啟相機拍照頁面
  Future<void> _takePicture() async {
    final file = await showModalBottomSheet<File>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) =>
          CameraDialog(title: AppLocalizations.of(context)!.cameraDialogTitle),
    );
    if (file != null) {
      setState(() {
        _imageFile = file;
      });
    }
  }
}
