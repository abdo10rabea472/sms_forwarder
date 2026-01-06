import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final webhookCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadWebhook();
  }

  Future<void> loadWebhook() async {
    final prefs = await SharedPreferences.getInstance();
    webhookCtrl.text = prefs.getString('webhook_url') ?? '';
  }

  Future<void> saveWebhook() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('webhook_url', webhookCtrl.text);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Saved')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Webhook Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: webhookCtrl,
              decoration: const InputDecoration(
                labelText: 'Webhook URL',
                hintText: 'https://yourdomain.com/webhook',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveWebhook,
              child: const Text('SAVE'),
            )
          ],
        ),
      ),
    );
  }
}
