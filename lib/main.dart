import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' as picker;
import 'package:flutter/services.dart';
import "package:image/image.dart" as dartImage;
import 'package:flutter_range_slider/flutter_range_slider.dart';

void main() => runApp(new MyApp());

class ImageData {
  double brightSliderValue;
  double blurSliderValue;
  double minBright;
  double maxBright;
  double minBlur;
  double maxBlur;

  ImageData(
      {this.blurSliderValue,
      this.brightSliderValue,
      this.minBright,
      this.maxBright,
      this.minBlur,
      this.maxBlur});
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Settings(),
    );
  }
}

class Settings extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new SettingsState();
  }
}

class SettingsState extends State<Settings> {
  @override
  void initState() {
    super.initState();
    this.getValues();
  }

  double minBright = 0.0;
  double maxBright = 255.0;
  double minBlur = 0.0;
  double maxBlur = 255.0;

  getValues() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      minBright = prefs.getDouble('minBright') ?? 0.0;
      maxBright = prefs.getDouble('maxBright') ?? 255.0;
      minBlur = prefs.getDouble('minBlur') ?? 0.0;
      maxBlur = prefs.getDouble('maxBlur') ?? 255.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text('Settings'),
        ),
        body: new Builder(builder: (BuildContext context) {
          return new Column(children: <Widget>[
            Padding(padding: EdgeInsets.all(8.0)),
            new Text('Choose Brightness'),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
              Padding(padding: EdgeInsets.only(left: 8.0)),
              Expanded(flex: 1, child: new Text('${minBright.toInt()}')),
              Expanded(
                  flex: 10,
                  child: new RangeSlider(
                    min: 0.0,
                    max: 255.0,
                    lowerValue: minBright,
                    upperValue: maxBright,
                    showValueIndicator: true,
                    valueIndicatorMaxDecimals: 1,
                    onChanged: (double newLowerValue, double newUpperValue) {
                      setState(() {
                        minBright = newLowerValue;
                        maxBright = newUpperValue;
                      });
                    },
                  )),
              Expanded(flex: 1, child: new Text('${maxBright.toInt()}')),
              Padding(padding: EdgeInsets.only(right: 8.0)),
            ]),
            Padding(padding: EdgeInsets.all(8.0)),
            new Text('Choose Blurriness'),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
              Padding(padding: EdgeInsets.only(left: 8.0)),
              Expanded(flex: 1, child: new Text('${minBlur.toInt()}')),
              Expanded(
                  flex: 10,
                  child: new RangeSlider(
                    min: 0.0,
                    max: 255.0,
                    lowerValue: minBlur,
                    upperValue: maxBlur,
                    showValueIndicator: true,
                    valueIndicatorMaxDecimals: 1,
                    onChanged: (double newLowerValue, double newUpperValue) {
                      setState(() {
                        minBlur = newLowerValue;
                        maxBlur = newUpperValue;
                      });
                    },
                  )),
              Expanded(flex: 1, child: new Text('${maxBlur.toInt()}')),
              Padding(padding: EdgeInsets.only(right: 8.0)),
            ]),
            new RaisedButton(
              child: Text('Apply'),
              onPressed: () async {
                setState(() {});
                final prefs = await SharedPreferences.getInstance();
                prefs.setDouble('maxBright', maxBright);
                prefs.setDouble('minBright', minBright);
                prefs.setDouble('maxBlur', maxBlur);
                prefs.setDouble('minBlur', minBlur);
                final imageData = ImageData(
                    minBright: minBright,
                    maxBright: maxBright,
                    minBlur: minBlur,
                    maxBlur: maxBlur);
                Navigator.pop(context, imageData);
              },
            )
          ]);
        }));
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new UserOptions(),
    );
  }
}

class UserOptions extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new UserOptionsState();
  }
}

class UserOptionsState extends State<UserOptions> {
  static const platform = const MethodChannel('FlutterOpenCV');
  File image;
  int brightness = 0;
  int blurriness = 0;
  String msg = "No message";
  double maxBright = 255.0;
  double minBright = 0.0;
  double maxBlur = 255.0;
  double minBlur = 0.0;
  bool brightnessValid = true;
  bool blurrinessValid = true;
  bool isValid = true;

  @override
  Widget build(BuildContext context) {
    checkValidity() {
      if (brightness > minBright && brightness < maxBright) {
        isValid = true;
      } else {
        isValid = false;
      }
      setState(() {});
    }

    //display image selected from gallery
    imageSelectorGallery() async {
      image = await picker.ImagePicker.pickImage(
        source: picker.ImageSource.gallery,
        maxHeight: 300.0,
        maxWidth: 400.0,
      );
      if (image != null) {
        List<int> fileBytes = image.readAsBytesSync();
        dartImage.Image newImage =
            dartImage.decodeImage(new File(image.path).readAsBytesSync());
        List<int> imageBytes = newImage.getBytes();
        var decodedImage = await decodeImageFromList(fileBytes);
        var r, g, b, avg;
        var colorSum = 0;
        for (var x = 0, len = imageBytes.length; x + 2 < len; x += 4) {
          r = imageBytes[x];
          g = imageBytes[x + 1];
          b = imageBytes[x + 2];

          avg = ((r + g + b) / 3).floor();
          colorSum += avg;
        }
        var imageWidth = decodedImage.width < 400 ? decodedImage.width : 400;
        var imageHeight = decodedImage.height < 300 ? decodedImage.height : 300;
        brightness = (colorSum / (imageWidth * imageHeight)).floor();
        getBlurriness();
      }
      checkValidity();
      setState(() {});
    }

    //display image selected from camera
    imageSelectorCamera() async {
      image = await picker.ImagePicker.pickImage(
        source: picker.ImageSource.camera,
        maxHeight: 300.0,
        maxWidth: 400.0
      );
      if (image != null) {
        List<int> fileBytes = image.readAsBytesSync();
        dartImage.Image newImage =
            dartImage.decodeImage(new File(image.path).readAsBytesSync());
        List<int> imageBytes = newImage.getBytes();
        print(imageBytes);
        var decodedImage = await decodeImageFromList(fileBytes);
        var r, g, b, avg;
        var colorSum = 0;
        for (var x = 0, len = imageBytes.length; x + 2 < len; x += 4) {
          r = imageBytes[x];
          g = imageBytes[x + 1];
          b = imageBytes[x + 2];

          avg = ((r + g + b) / 3).floor();
          colorSum += avg;
        }
        var imageWidth = decodedImage.width < 400 ? decodedImage.width : 400;
        var imageHeight = decodedImage.height < 300 ? decodedImage.height : 300;
        brightness = (colorSum / (imageWidth * imageHeight)).floor();
        getBlurriness();
      }
      checkValidity();
      setState(() {});
    }

    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Image Picker'),
        actions: <Widget>[
          new IconButton(
            icon: new Icon(Icons.settings),
            onPressed: () async {
              final dataFromSecondPage = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Settings()),
              ) as ImageData;
              if (dataFromSecondPage != null) {
                maxBright = dataFromSecondPage.maxBright;
                minBright = dataFromSecondPage.minBright;
                maxBlur = dataFromSecondPage.maxBlur;
                minBlur = dataFromSecondPage.minBlur;
                checkValidity();
              }
            },
          ),
        ],
      ),
      body: new Builder(
        builder: (BuildContext context) {
          return new Column(
            children: <Widget>[
              Row(children: <Widget>[
                new IconButton(
                  icon: Icon(Icons.add_photo_alternate),
                  onPressed: imageSelectorGallery,
                ),
                new IconButton(
                  icon: Icon(Icons.add_a_photo),
                  onPressed: imageSelectorCamera,
                ),
              ]),
              displaySelectedFile(image),
              image != null
                  ? new Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                          new Text(
                              'Brightness: $brightness, Sharpness: $blurriness \t'),
                        ])
                  : new Text(''),
              image != null &&
                      (isValid == false ||
                          blurriness < minBlur)
                  ? new Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                          blurriness < minBlur
                              ? new Text('Picture is too blurry',
                                  style: TextStyle(color: Colors.red)) : new Text(''),
                          brightness > maxBright && blurriness >= minBlur ? new Text('Picture is too bright',
                                  style: TextStyle(color: Colors.red)) : new Text(''),
                          brightness < minBright && blurriness >= minBlur ? new Text('Picture is not bright enough',
                              style: TextStyle(color: Colors.red)) : new Text(''),
                          new IconTheme(
                            data: new IconThemeData(color: Colors.red),
                            child: new Icon(Icons.error),
                          )
                        ])
                  : new Text(''),
            ],
          );
        },
      ),
    );
  }

  Widget displaySelectedFile(File file) {
    return new SizedBox(
      height: 300.0,
      width: 400.0,
      child: file == null ? new Text('Choose an image') : new Image.file(file),
    );
  }

  Future<void> getBlurriness() async {
    var params = <String, dynamic>{"image": image.path};
    double blur;
    String message;
    try {
      blur = await platform.invokeMethod('getData', params);
    } on PlatformException catch (e) {
      message = "Failed to get data from native : '${e.message}'.";
    }
    setState(() {
      msg = message;
      blurriness = blur~/10;
    });
  }
}
