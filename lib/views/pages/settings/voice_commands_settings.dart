import 'package:flutter/material.dart';
import 'package:spendle/database/database_helper.dart';

class VoiceCommandsSettings extends StatefulWidget {
  const VoiceCommandsSettings({super.key});

  @override
  State<VoiceCommandsSettings> createState() => _VoiceCommandsSettingsState();
}

class _VoiceCommandsSettingsState extends State<VoiceCommandsSettings> {
  bool _voiceEnabled = true;
  bool _loadingVoicePref = true;

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
      _loadingVoicePref = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Settings'), centerTitle: true),
      body: _loadingVoicePref
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Voice Commands',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _loadingVoicePref
                      ? const SizedBox(
                          height: 48,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : SwitchListTile(
                          title: const Text('Enable voice commands'),
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Colors.grey.shade400,
                          activeThumbColor: Colors.white,
                          activeTrackColor: Colors.lightBlue,
                          subtitle: const Text(
                            'Use voice to add expenses (e.g., "add food 20 or shopping 500")',
                          ),
                          value: _voiceEnabled,
                          onChanged: (v) async {
                            // persist in DB
                            await DatabaseHelper().setVoiceEnabled(v);
                            if (!mounted) return;
                            setState(() => _voiceEnabled = v);

                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  v
                                      ? 'Voice commands enabled'
                                      : 'Voice commands disabled',
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}
