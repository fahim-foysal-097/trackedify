import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
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

  Future<void> _toggleVoice(bool v) async {
    setState(() => _saving = true);
    await DatabaseHelper().setVoiceEnabled(v);
    if (!mounted) return;
    setState(() {
      _voiceEnabled = v;
      _saving = false;
    });

    if (!mounted) return;
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
                v ? 'Voice commands enabled' : 'Voice commands disabled',
              ),
            ),
          ],
        ),
      ),
    );
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
