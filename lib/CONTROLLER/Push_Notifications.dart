import 'dart:convert';
import 'package:SwiftTalk/API_KEYS.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;

class PushNotification {
  static Future<String> getAccessToken() async {
    final serviceAccountJSON = SERVICE_JSON;
    List<String> scopes = SCOPES;
    http.Client client = await auth.clientViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(serviceAccountJSON), scopes);

    auth.AccessCredentials credentials =
        await auth.obtainAccessCredentialsViaServiceAccount(
            auth.ServiceAccountCredentials.fromJson(serviceAccountJSON),
            scopes,
            client);
    client.close();
    return credentials.accessToken.data;
  }

  static sendNotification(
      {required String token,
      required String title,
      required String msg,
      required String type}) async {
    final String serverKey = await getAccessToken();
    String endPointFirebaseCloudMessaging = FIREBASE_ENDPOINT;
    final Map<String, dynamic> message = {
      'message': {
        'token': token,
        'data': {
          'title': title,
          'body': msg,
          'type': type,
          'callerName': FirebaseAuth.instance.currentUser?.displayName ?? ''
        },
      }
    };
    final http.Response response = await http.post(
        Uri.parse(endPointFirebaseCloudMessaging),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $serverKey'
        },
        body: jsonEncode(message));
    if (response.statusCode == 200) {
      print("Notification Sent Successfully");
    } else {
      print("Failed to send notification");
    }
  }
}
