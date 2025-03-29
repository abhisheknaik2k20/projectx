import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:SwiftTalk/main.dart';
import 'package:uuid/uuid.dart';

late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
FirebaseFirestore db = FirebaseFirestore.instance;

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  if (message.data.containsKey('custom_key')) {
    print('handle backround');
    try {
      _showNotification(message);
    } catch (expection) {
      print(expection);
    }
  } else {
    var androidNotificationDetails = const AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
    );
    var notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await _flutterLocalNotificationsPlugin.show(
      0,
      message.notification!.title!,
      message.notification!.body,
      notificationDetails,
      payload: 'payload',
    );
  }
}

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  void handleMessage(RemoteMessage? message) {
    if (message!.notification != null) {
      print('Some Notification Recived');
    }
  }

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();
    final fCMToken = await _firebaseMessaging.getToken();
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    print('token :$fCMToken');
    localNotiInit();
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      // print('Got a Message in Foreground');
      if (message.notification != null) {
        if (message.data.containsKey('custom_key')) {
          // try {
          //   Navigator.of(navigatorKey.currentContext!).push(
          //     MaterialPageRoute(
          //       builder: (context) => const CallScreen(),
          //     ),
          //   );
          // } catch (expection) {
          //   //print(expection);
          // }
        } else {
          //print('handle ForeGround-2');
          showSimpleNotification(
              title: message.notification!.title!,
              body: message.notification!.body!,
              payload: 'payload');
        }
      }
    });
  }

  static Future localNotiInit() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();
    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');
    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsDarwin,
            linux: initializationSettingsLinux);
    _flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: onNotificationTap,
        onDidReceiveBackgroundNotificationResponse: onNotificationTap);
  }

  static void onNotificationTap(NotificationResponse notificationResponse) {
    navigatorKey.currentState!
        .pushNamed('/home', arguments: notificationResponse);
  }

  static Future showSimpleNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    var androidNotificationDetails = const AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.high,
      priority: Priority.high,
    );

    var notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}

void _showNotification(RemoteMessage message) async {
  final Int64List vibrationPattern = Int64List(4);
  const int insistentFlag = 4;
  vibrationPattern[0] = 0;
  vibrationPattern[1] = 4000;
  vibrationPattern[2] = 4000;
  vibrationPattern[3] = 4000;
  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
    const Uuid().v4(),
    'your_channel_name',
    importance: Importance.max,
    priority: Priority.max,
    ongoing: true,
    additionalFlags: Int32List.fromList(<int>[insistentFlag]),
    playSound: true,
    sound: const RawResourceAndroidNotificationSound('ringtone'),
    enableLights: true,
    vibrationPattern: vibrationPattern,
  );
  var platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );
  await flutterLocalNotificationsPlugin.show(
    1,
    'Call Notification',
    'You have an ongoing call',
    platformChannelSpecifics,
  );
}
