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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.deepPurple,
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
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
    PanaraInfoDialog.show(
      context,
      title: 'Hints & Tips',
      message:
          'You can use voice to add expenses. Say for example: "Add food 20" or "Shopping 500". If it fails, check microphone permission and language settings.',
      buttonText: 'Got it',
      textColor: Colors.black54,
      onTapDismiss: () => Navigator.pop(context),
      panaraDialogType: PanaraDialogType.normal,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Commands'),
        centerTitle: false,
        leading: IconButton(
          tooltip: "Back",
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 25),
          onPressed: () => Navigator.pop(context),
        ),
        actionsPadding: const EdgeInsets.only(right: 6),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
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
                  const Text(
                    'Voice Commands',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    color: Colors.green.shade50,
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
                        title: const Text(
                          'Enable voice commands',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Use voice to add expenses (e.g., "add food 20")',
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
                        onTap: () async {
                          await _toggleVoice(!_voiceEnabled);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
