import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';

class GetServiceKey {
  Future<String> getServiceKey() async {
    final scopes = [
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/Firebase.database',
      'https://www.googleapis.com/auth/Firebase.messaging',
    ];

    // For hiding the server Credentials
    final jsonFile = File('assets/credentials.json');
    final jsonString = await jsonFile.readAsString();
    final jsonData = jsonDecode(jsonString);

    final client = await clientViaServiceAccount(
      ServiceAccountCredentials.fromJson(jsonData),
      scopes,
    );

    final accessServerkey = client.credentials.accessToken.data;

    return accessServerkey;
  }
}
