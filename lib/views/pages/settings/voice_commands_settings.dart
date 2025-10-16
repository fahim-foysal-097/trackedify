import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:trackedify/database/database_helper.dart';

class VoiceCommandsSettings extends StatefulWidget {
  const VoiceCommandsSettings({super.key});

  @override
  State<VoiceCommandsSettings> createState() => _VoiceCommandsSettingsState();
}

class _VoiceCommandsSettingsState extends State<VoiceCommandsSettings> {
  bool _voiceEnabled = true;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadVoicePref();
  }

  Future<void> _loadVoicePref() async {
    final v = await DatabaseHelper().isVoiceEnabled();
    if (!mounted) return;
    setState(() {
      _voiceEnabled = v;
      _loading = false;
    });
  }

  /// Request microphone permission. Returns true if permission granted.
  Future<bool> _requestMicPermission() async {
    try {
      final status = await Permission.microphone.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  Future<void> _toggleVoice(bool v) async {
    setState(() => _saving = true);

    final theme = Theme.of(context);

    if (v) {
      // When enabling voice, ask for microphone permission first.
      final permStatus = await Permission.microphone.status;

      if (!permStatus.isGranted) {
        final granted = await _requestMicPermission();

        if (!granted) {
          // Persist user choice: they denied mic -> disable voice in DB
          await DatabaseHelper().setVoiceEnabled(false);

          if (!mounted) return;
          setState(() {
            _voiceEnabled = false;
            _saving = false;
          });

          // If permanently denied, offer to open system settings
          final isPermanentlyDenied =
              await Permission.microphone.isPermanentlyDenied;

          if (isPermanentlyDenied) {
            if (!mounted) return;
            PanaraInfoDialog.show(
              context,
              title: 'Microphone permission required',
              message:
                  'Microphone permission is blocked for this app. To enable voice commands, open system settings and enable Microphone permission for Trackedify.',
              buttonText: 'Open settings',
              textColor: theme.textTheme.bodySmall?.color,
              onTapDismiss: () async {
                Navigator.pop(context);
                openAppSettings();
              },
              panaraDialogType: PanaraDialogType.warning,
            );
          } else {
            if (!mounted) return;
            PanaraInfoDialog.show(
              context,
              title: 'Permission denied',
              message:
                  'Microphone permission was denied. Voice commands have been disabled. You can enable microphone permission in system settings to use voice features.',
              buttonText: 'OK',
              textColor: theme.textTheme.bodySmall?.color,
              onTapDismiss: () => Navigator.pop(context),
              panaraDialogType: PanaraDialogType.normal,
            );
          }

          return;
        }
      }

      // Permission granted — persist enabled and update UI
      await DatabaseHelper().setVoiceEnabled(true);
      if (!mounted) return;
      setState(() {
        _voiceEnabled = true;
        _saving = false;
      });

      final cs = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: cs.primary,
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: cs.onPrimary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Voice commands enabled',
                  style: TextStyle(color: cs.onPrimary),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Disabling voice (user toggled off)
      await DatabaseHelper().setVoiceEnabled(false);
      if (!mounted) return;
      setState(() {
        _voiceEnabled = false;
        _saving = false;
      });

      final cs = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: cs.error,
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: cs.onError),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Voice commands disabled',
                  style: TextStyle(color: cs.onError),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _showTipsDialog() {
    final theme = Theme.of(context);
    PanaraInfoDialog.show(
      context,
      title: 'Hints & Tips',
      message:
          'You can use voice to add expenses. Say for example: "Add food 20" or "Shopping 500". If it fails, check microphone permission and language settings.',
      buttonText: 'Got it',
      textColor: theme.textTheme.bodySmall?.color,
      onTapDismiss: () => Navigator.pop(context),
      panaraDialogType: PanaraDialogType.normal,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Commands'),
        centerTitle: false,
        leading: IconButton(
          tooltip: "Back",
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 25,
            color: cs.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actionsPadding: const EdgeInsets.only(right: 6),
        actions: [
          IconButton(
            icon: Icon(Icons.lightbulb_outline, color: cs.onSurface),
            onPressed: _showTipsDialog,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CupertinoActivityIndicator())
          : SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                children: [
                  Text(
                    'Voice Commands',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    color: cs.surfaceContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.mic, color: Colors.green),
                        ),
                        title: Text(
                          'Enable voice commands',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Use voice to add expenses (e.g., "add food 20")',
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: _saving
                            ? const SizedBox(
                                width: 46,
                                height: 30,
                                child: Center(
                                  child: CupertinoActivityIndicator(),
                                ),
                              )
                            : CupertinoSwitch(
                                value: _voiceEnabled,
                                activeTrackColor: Colors.green,
                                onChanged: (v) async {
                                  await _toggleVoice(v);
                                },
                              ),
                        onTap: () async => await _toggleVoice(!_voiceEnabled),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
