package com.example.image_app;

import android.os.Bundle;

import org.opencv.core.Core;
import org.opencv.core.CvType;
import org.opencv.core.Mat;
import org.opencv.core.MatOfDouble;
import org.opencv.imgcodecs.Imgcodecs;
import org.opencv.imgproc.Imgproc;

import java.util.Map;
import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
    static {
        System.loadLibrary("opencv_java4");
    }
    public Mat matGray = new Mat();
    public Mat destination = new Mat();
    public double blurValue;

  private static final String CHANNEL = "FlutterOpenCV";
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);
    new MethodChannel(getFlutterView(), CHANNEL).setMethodCallHandler(
            new MethodChannel.MethodCallHandler() {
              @Override
              public void onMethodCall(MethodCall call, MethodChannel.Result result) {
                  Map<String, Object> params = (Map<String, Object>) call.arguments;
                  if (call.method.equals("getData")) {
                      Mat image = Imgcodecs.imread(params.get("image").toString());
                      Imgproc.cvtColor(image, matGray, Imgproc.COLOR_BGR2GRAY);
                      Imgproc.Laplacian(matGray, destination, 3);
                      MatOfDouble median = new MatOfDouble();
                      MatOfDouble std = new MatOfDouble();
                      Core.meanStdDev(destination, median , std);
                      blurValue = Math.pow(std.get(0,0)[0],2);
                      result.success(getData());
                  } else {
                      result.notImplemented();
                  }
              }
            });
  }
  private double getData() {
    return blurValue;
  }
}
