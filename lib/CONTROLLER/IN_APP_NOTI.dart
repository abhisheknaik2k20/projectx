import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math';

class DownloadService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          await OpenFile.open(response.payload!);
        }
      },
    );
  }

  Future<bool> storagePermission() async {
    if (Platform.isAndroid) {
      final DeviceInfoPlugin info = DeviceInfoPlugin();
      final AndroidDeviceInfo androidInfo = await info.androidInfo;
      debugPrint('releaseVersion : ${androidInfo.version.release}');
      bool havePermission = false;
      try {
        final int androidVersion = int.parse(androidInfo.version.release);
        if (androidVersion >= 13) {
          final request =
              await [Permission.videos, Permission.photos].request();
          havePermission = request.values
              .every((status) => status == PermissionStatus.granted);
        } else {
          final status = await Permission.storage.request();
          havePermission = status.isGranted;
        }
      } catch (e) {
        debugPrint('Error parsing Android version: $e');
        final status = await Permission.storage.request();
        havePermission = status.isGranted;
      }
      if (!havePermission) await openAppSettings();
      return havePermission;
    }
    return true;
  }

  Future<String?> downloadFile(String downloadURL,
      {String? customDirectory}) async {
    print('Downloading from URL: $downloadURL');

    try {
      bool permissionGranted = await storagePermission();
      if (!permissionGranted) {
        print("Storage permission denied by user");
        return null;
      }
      if (Platform.isAndroid) {
        final status = await Permission.notification.request();
        if (status.isDenied) {
          print("Notification permission denied, notifications may not work");
        }
      }
      final int notificationId = Random().nextInt(1000);
      final fileName = path.basename(Uri.parse(downloadURL).path);
      String filePath;
      if (customDirectory != null) {
        final directory = Directory(customDirectory);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        filePath = path.join(customDirectory, fileName);
      } else {
        Directory? appDir;
        if (Platform.isAndroid) {
          try {
            appDir = await getExternalStorageDirectory();
          } catch (e) {
            print("Failed to get external storage directory: $e");
          }

          final downloadsDir = Directory('/storage/emulated/0/Download');
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
          }
          filePath = path.join(downloadsDir.path, fileName);
        } else {
          appDir = await getApplicationDocumentsDirectory();
          filePath = path.join(appDir.path, fileName);
        }
      }

      await _showProgressNotification(
          notificationId: notificationId,
          title: 'Downloading $fileName',
          progress: 0,
          maxProgress: 100);
      final headResponse = await http.head(Uri.parse(downloadURL));
      final fileSize = int.parse(headResponse.headers['content-length'] ?? '0');
      final request = http.Request('GET', Uri.parse(downloadURL));
      final response = await http.Client().send(request);

      if (response.statusCode == 200) {
        final file = File(filePath);
        final downloadedBytes = <int>[];
        int totalBytes = 0;

        await for (final bytes in response.stream) {
          downloadedBytes.addAll(bytes);
          totalBytes += bytes.length;

          final progress =
              fileSize > 0 ? (totalBytes / fileSize * 100).round() : 0;
          await _showProgressNotification(
              notificationId: notificationId,
              title: 'Downloading $fileName',
              progress: progress,
              maxProgress: 100);
        }

        await file.writeAsBytes(downloadedBytes);
        print('File downloaded successfully to: $filePath');
        await flutterLocalNotificationsPlugin.cancel(notificationId);
        await _showCompletionNotification(
            notificationId: notificationId,
            title: 'Download Complete',
            body: '$fileName has been downloaded',
            payload: filePath);
        return filePath;
      } else {
        print('Failed to download file: ${response.statusCode}');
        await flutterLocalNotificationsPlugin.cancel(notificationId);
        await _showErrorNotification(
            notificationId: notificationId,
            title: 'Download Failed',
            body: 'Failed to download $fileName');
        return null;
      }
    } catch (e) {
      print('Error downloading file: $e');
      final int errorNotificationId = Random().nextInt(1000);
      await _showErrorNotification(
          notificationId: errorNotificationId,
          title: 'Download Error',
          body:
              'Error downloading file: ${e.toString().substring(0, min(50, e.toString().length))}');
      return null;
    }
  }

  Future<void> _showProgressNotification(
      {required int notificationId,
      required String title,
      required int progress,
      required int maxProgress}) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails('download_channel', 'File Downloads',
            channelDescription: 'Notifications for file downloads',
            importance: Importance.low,
            priority: Priority.low,
            onlyAlertOnce: true,
            showProgress: true,
            maxProgress: maxProgress,
            progress: progress,
            ongoing: true,
            autoCancel: false);
    final NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(notificationId, title,
        'Download in progress: $progress%', notificationDetails);
  }

  Future<void> _showCompletionNotification(
      {required int notificationId,
      required String title,
      required String body,
      required String payload}) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails('download_channel', 'File Downloads',
            channelDescription: 'Notifications for file downloads',
            importance: Importance.high,
            priority: Priority.high,
            autoCancel: true);
    final NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(
        notificationId, title, body, notificationDetails,
        payload: payload);
  }

  Future<void> _showErrorNotification(
      {required int notificationId,
      required String title,
      required String body}) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails('download_channel', 'File Downloads',
            channelDescription: 'Notifications for file downloads',
            importance: Importance.high,
            priority: Priority.high,
            autoCancel: true);
    final NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(
        notificationId, title, body, notificationDetails);
  }
}
