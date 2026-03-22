import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

class GoogleDriveBackup {

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveFileScope,
    ],
  );

  static Future uploadBackup(File file) async {

    final account = await _googleSignIn.signIn();

    if (account == null) {
      print("User cancelled login");
      return;
    }

    final authHeaders = await account.authHeaders;

    final client = GoogleAuthClient(authHeaders);

    final driveApi = drive.DriveApi(client);

    var driveFile = drive.File();
    driveFile.name = "tourkhata_backup.db";

    await driveApi.files.create(
      driveFile,
      uploadMedia: drive.Media(
        file.openRead(),
        file.lengthSync(),
      ),
    );

    print("Backup uploaded to Google Drive");
  }
}

class GoogleAuthClient extends http.BaseClient {

  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {

    request.headers.addAll(_headers);

    return _client.send(request);
  }
}