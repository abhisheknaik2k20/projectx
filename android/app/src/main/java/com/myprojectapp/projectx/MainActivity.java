package com.myprojectapp.projectx;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import android.media.AudioManager;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine; 
import android.hardware.Camera;
import io.flutter.embedding.android.FlutterFragmentActivity;

public class MainActivity extends FlutterFragmentActivity {
    private static final String CHANNEL = "samples.flutter.dev/microphone";
    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            if (call.method.equals("muteMicrophone")) {
                                AudioManager audioManager = (AudioManager) getSystemService(AUDIO_SERVICE);
                                audioManager.setMicrophoneMute(true);
                                result.success(null);
                            } else if (call.method.equals("unmuteMicrophone")) {
                                AudioManager audioManager = (AudioManager) getSystemService(AUDIO_SERVICE);
                                audioManager.setMicrophoneMute(false);
                                result.success(null);
                            } else {
                                result.notImplemented();
                            }
                           
                        }
                );
        
    }
}
