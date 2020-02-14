import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shake/shake.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audio_cache.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Interactive Picture Prototype',
        theme: ThemeData(
          primarySwatch: Colors.purple,
        ),
        home: MyHomePage(),
        debugShowCheckedModeBanner: false);
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File _image;
  double _currentOpacity = 0;
  double _amountToAdd = 0.05;
  bool _blackBackground = true;
  bool _vibrationOn = true;
  ShakeDetector detector;
  final player = AudioCache();

  void _onShake() {
    if (_currentOpacity == 1) return;

    setState(() {
      if (_currentOpacity > 1 - _amountToAdd) {
        _currentOpacity = 1.0;
        _onFullOpacity();
        return;
      }
      _currentOpacity += _amountToAdd;
      if (_currentOpacity == 1) {
        _onFullOpacity();
      }
    });
  }

  void _onFullOpacity() async {
    player.play('goodSound.mp3');

    if (_vibrationOn && await Vibration.hasVibrator()) {
      Vibration.vibrate(pattern: [200, 100, 300, 60, 600, 100, 300, 60], intensities: [200, 100, 200, 100]);
    }
  }

  Future getImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.camera);

    setState(() {
      _image = image;
      detector.startListening();
      _currentOpacity = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (detector == null) {
      player.load('goodSound.mp3');

      detector = ShakeDetector.waitForStart(
        shakeThresholdGravity: 1.4,
        shakeSlopTimeMS: 20,
        onPhoneShake: () {
          _onShake();
        },
      );
    }

    return Theme(
      data: ThemeData(
        primarySwatch: Colors.grey,
        canvasColor: _blackBackground ? Colors.black : Colors.white,
      ),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Stack(
                children: <Widget>[
                  AnimatedOpacity(
                    opacity: _currentOpacity,
                    duration: Duration(milliseconds: 1),
                    child: Center(
                      child: _image == null ? Text('No image selected.') : Image.file(_image),
                    ),
                  ),
                ],
              ),
              Column(
                children: <Widget>[
                  Container(
                    //color: Colors.amberAccent,
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Switch.adaptive(
                          activeColor: _blackBackground ? Colors.white : Colors.black87,
                          inactiveThumbColor: _blackBackground ? Colors.grey[800] : Colors.grey[200],
                          inactiveTrackColor: _blackBackground ? Colors.grey[800] : Colors.grey[200],
                          activeTrackColor: _blackBackground ? Colors.white : Colors.black87,
                          value: _vibrationOn,
                          onChanged: (value) {
                            setState(() {
                              _vibrationOn = !_vibrationOn;
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.invert_colors,
                            color: _blackBackground ? Colors.white : Colors.black,
                          ),
                          onPressed: () {
                            setState(() {
                              _blackBackground = !_blackBackground;
                            });
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 8,
                            bottom: 8,
                            top: 8,
                          ),
                          child: FloatingActionButton(
                            elevation: 0,
                            onPressed: () {
                              setState(() {
                                _currentOpacity = 0;
                              });
                            },
                            tooltip: 'Reset opacity',
                            child: Icon(Icons.wb_sunny),
                          ),
                        ),
                        Expanded(
                          child: Slider.adaptive(
                            value: _amountToAdd,
                            min: 0.01,
                            max: 0.20,
                            onChanged: (double newValue) {
                              setState(() {
                                _amountToAdd = newValue;
                              });
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            right: 8,
                            bottom: 8,
                            top: 8,
                          ),
                          child: FloatingActionButton(
                            elevation: 0,
                            onPressed: getImage,
                            tooltip: 'Pick Image',
                            child: Icon(Icons.add_a_photo),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
