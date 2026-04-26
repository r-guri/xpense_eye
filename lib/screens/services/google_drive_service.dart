import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart';
import 'backup_prefs.dart';
import '../../utils/app_strings.dart';
import '../../utils/backup_service.dart';
import '../../utils/app_toast.dart';

class GoogleDriveService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'https://www.googleapis.com/auth/drive.file'],
  );

  /// 🔥 SAFE API (no popup in background)
  static Future<drive.DriveApi?> _api({bool interactive = true}) async {
    GoogleSignInAccount? acc;

    if (interactive) {
      acc = await _googleSignIn.signIn();
    } else {
      acc = _googleSignIn.currentUser ??
          await _googleSignIn.signInSilently();
    }

    if (acc == null) return null;

    final headers = await acc.authHeaders;
    return drive.DriveApi(_AuthClient(headers));
  }

  /// 🔥 EMAIL
  static Future<String?> getConnectedEmail() async {
    final acc =
        _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    return acc?.email;
  }

  /// 🔥 SIGN OUT
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// ================= 🔥 UPLOAD CORE =================
  static Future<void> _uploadFile(
    drive.DriveApi api,
    File file,
  ) async {
    final media = drive.Media(file.openRead(), file.lengthSync());

    final existing = await api.files.list(
      q: "name='xpense_backup.json' and trashed=false",
      spaces: 'drive',
    );

    final driveFile = drive.File()..name = 'xpense_backup.json';

    if (existing.files != null && existing.files!.isNotEmpty) {
      await api.files.update(
        driveFile,
        existing.files!.first.id!,
        uploadMedia: media,
      );
    } else {
      await api.files.create(driveFile, uploadMedia: media);
    }
  }

  /// ================= 🔥 MANUAL BACKUP =================
  static Future<void> uploadNow(
    BuildContext context, {
    required int userId,
    bool manual = true,
  }) async {
    try {
      final api = await _api(interactive: true);
      if (api == null) return;

      /// 🔥 PRIVATE FILE (IMPORTANT CHANGE)
      final file = await BackupService.getPrivateBackupFile(userId);

      await BackupPrefs.setBackupSize(file.lengthSync());

      await _uploadFile(api, file);

      await BackupPrefs.setLastBackup(
          DateTime.now().millisecondsSinceEpoch);

      if (manual && context.mounted) {
        AppToast.success(context, AppStrings.get("backup_completed"));
      }
    } catch (e) {
      print("BACKUP ERROR: $e");
      if (context.mounted) {
        AppToast.error(context, AppStrings.get("backup_failed"));
      }
    }
  }

  /// ================= 🔥 BACKGROUND BACKUP =================
  static Future<void> backgroundBackup(int userId) async {
    try {
      final api = await _api(interactive: false);
      if (api == null) return;

      final file = await BackupService.getPrivateBackupFile(userId);

      await _uploadFile(api, file);

      await BackupPrefs.setLastBackup(
          DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // silent
    }
  }

  /// ================= 🔥 RESTORE =================
  static Future<void> restoreNow(
    BuildContext context, {
    required int userId,
  }) async {
    try {
      final api = await _api(interactive: true);
      if (api == null) return;

      final res = await api.files.list(
        q: "name='xpense_backup.json' and trashed=false",
        spaces: 'drive',
      );

      if (res.files == null || res.files!.isEmpty) {
        if (context.mounted) {
          AppToast.error(context, AppStrings.get("no_backup_found"));
        }
        return;
      }

      final fileId = res.files!.first.id!;

      final media = await api.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = <int>[];
      await for (var chunk in media.stream) {
        bytes.addAll(chunk);
      }

      final tempDir = Directory.systemTemp;
      final file = File("${tempDir.path}/xpense_backup.json");

      await file.writeAsBytes(bytes);

      await BackupService.restoreBackupFile(file, userId);

      if (context.mounted) {
        AppToast.success(context, AppStrings.get("restore_completed"));
      }
    } catch (e) {
      print("RESTORE ERROR: $e");
      if (context.mounted) {
        AppToast.error(context, AppStrings.get("backup_failed"));
      }
    }
  }
}

class _AuthClient extends BaseClient {
  final Map<String, String> _headers;
  final Client _client = Client();

  _AuthClient(this._headers);

  @override
  Future<StreamedResponse> send(BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}