import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:texture_hub/texture_hub.dart';
import 'package:camera/camera.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

enum TextureRoute { original, textureHub }

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  CameraDescription cameraDescription;
  CameraController controller;
  String imagePath;
  TextureRoute textureRoute = TextureRoute.original;
  TextureSlot textureSlot;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (controller != null) {
        createCamera();
      }
    }
  }

  Future<void> initCamera() async {
    final List<CameraDescription> cameras = await availableCameras();
    cameraDescription = cameras.firstWhere((CameraDescription camera) {
      return camera.lensDirection == CameraLensDirection.back;
    });
    await createCamera();
    await createSlot();
  }

  Future<void> createCamera() async {
    if (controller != null) {
      await controller.dispose();
    }
    controller = CameraController(cameraDescription, ResolutionPreset.high);

    controller.addListener(() {
      if (mounted) setState(() {});
      if (controller.value.hasError) {
        showInSnackBar('Camera error ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      print(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void showInSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Camera example'),
      ),
      body: Column(
        children: <Widget>[
          _textureRouteSelector(),
          Expanded(
            child: Container(
              child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: Center(
                  child: _cameraPreviewWidget(),
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(
                  color: controller != null && controller.value.isRecordingVideo
                      ? Colors.redAccent
                      : Colors.grey,
                  width: 3.0,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                _thumbnailWidget(),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return const Text('Initializing...');
    } else {
      return AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(controller),
      );
    }
  }

  /// Display the thumbnail of the captured image or video.
  Widget _thumbnailWidget() {
    return Expanded(
      child: Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            imagePath == null
                ? Container()
                : SizedBox(
                    child: Image.file(File(imagePath)),
                    width: 64.0,
                    height: 64.0,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _textureRouteSelector() {
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Expanded(
            child: RadioListTile<TextureRoute>(
              title: const Text('Original'),
              groupValue: textureRoute,
              value: TextureRoute.original,
              onChanged: (TextureRoute value) {
                setState(() {
                  textureRoute = value;
                });
              },
            ),
          ),
          Expanded(
            child: RadioListTile<TextureRoute>(
              title: const Text('TextureHub'),
              value: TextureRoute.textureHub,
              groupValue: textureRoute,
              onChanged: (TextureRoute value) {
                setState(() {
                  textureRoute = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> createSlot() async {
    textureSlot = await TextureHub.allocate();
    await controller.addTextureOutput(textureSlot);
  }
}
