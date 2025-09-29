import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';

class UpdateService {
  static const _repoOwner = "fahim-foysal-097";
  static const _repoName = "spendle";

  /// Optional GitHub API token for higher rate limit
  static const String? _githubToken = null; // null for none

  /// Detect device ABI -> maps to GitHub release naming
  static Future<String> _getDeviceArch() async {
    try {
      if (!Platform.isAndroid) return "arm64-v8a";

      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final abiList = androidInfo.supportedAbis;

      if (abiList.contains("arm64-v8a")) return "arm64-v8a";
      if (abiList.contains("armeabi-v7a")) return "armeabi-v7a";
      if (abiList.contains("x86_64")) return "x86_64";
      if (abiList.isNotEmpty) return abiList.first;

      return "arm64-v8a"; // fallback
    } catch (_) {
      return "arm64-v8a";
    }
  }

  /// Check GitHub latest release and compare with current app version
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;

      final url = Uri.parse(
        "https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest",
      );

      final headers = <String, String>{
        "Accept": "application/vnd.github+json",
        "User-Agent": "Spendle-App",
        if (_githubToken != null) "Authorization": "token $_githubToken",
      };

      final res = await http.get(url, headers: headers);
      if (res.statusCode != 200) return;

      final data = jsonDecode(res.body);
      final tag = data["tag_name"];
      final assets = data["assets"] as List;

      if (tag.replaceFirst("v", "") == currentVersion) return;

      final arch = await _getDeviceArch();
      final apkAsset = assets.firstWhere(
        (a) => (a["name"] as String).contains(arch),
        orElse: () => null,
      );

      if (apkAsset == null) return;
      final apkUrl = apkAsset["browser_download_url"];

      if (!context.mounted) return;
      PanaraConfirmDialog.show(
        context,
        title: "Update Available",
        message: "A new version $tag is available. Do you want to update?",
        confirmButtonText: "Update",
        cancelButtonText: "Later",
        onTapCancel: () => Navigator.of(context).pop(),
        onTapConfirm: () {
          Navigator.of(context).pop();
          _downloadAndInstall(apkUrl, tag, context);
        },
        panaraDialogType: PanaraDialogType.normal,
      );
    } catch (e) {
      debugPrint("Update check failed: $e");
    }
  }

  /// Download APK and show progress dialog
  static Future<void> _downloadAndInstall(
    String url,
    String version,
    BuildContext context,
  ) async {
    try {
      // Use app-specific external storage (no runtime storage permission needed)
      final dir = await getExternalStorageDirectory();
      if (dir == null) return;
      final filePath = "${dir.path}/spendle-$version.apk";
      final file = File(filePath);

      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);

      final total = response.contentLength ?? 0;
      int received = 0;
      final progressNotifier = ValueNotifier<double>(0);

      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          isDismissible: false,
          enableDrag: false,
          builder: (_) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ValueListenableBuilder<double>(
                valueListenable: progressNotifier,
                builder: (context, progress, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Downloading update..."),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(value: progress),
                      const SizedBox(height: 12),
                      Text("${(progress * 100).toStringAsFixed(0)}%"),
                    ],
                  );
                },
              ),
            );
          },
        );
      }

      final sink = file.openWrite();
      await for (final chunk in response.stream) {
        received += chunk.length;
        sink.add(chunk);
        if (total > 0) progressNotifier.value = received / total;
      }
      await sink.flush();
      await sink.close();

      if (context.mounted) Navigator.of(context).pop();

      await OpenFilex.open(filePath);
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Update failed: $e")));
      }
    }
  }
}
