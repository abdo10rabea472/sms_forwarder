import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_advanced/sms_advanced.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final SmsReceiver _receiver = SmsReceiver();

  final senderCtrl = TextEditingController(text: '*');
  final webhookCtrl = TextEditingController();
  final payloadCtrl = TextEditingController(text: '''
{
  "from":"%from%",
  "text":"%text%",
  "receivedStamp":"%receivedStamp%",
  "sim":"%sim%"
}
''');

  bool ignoreSSL = false;
  bool chunked = true;
  int retries = 10;
  String simSlot = 'any';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initSms();
  }

  Future<void> _initSms() async {
    await Permission.sms.request();
    _receiver.onSmsReceived?.listen((SmsMessage msg) {
      _sendWebhook(msg);
    });
  }

  Future<void> _loadSettings() async {
    final p = await SharedPreferences.getInstance();
    webhookCtrl.text = p.getString('webhook') ?? '';
    senderCtrl.text = p.getString('sender') ?? '*';
  }

  Future<void> _saveSettings() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('webhook', webhookCtrl.text);
    await p.setString('sender', senderCtrl.text);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Saved')));
  }

  Future<void> _sendWebhook(SmsMessage msg) async {
    final p = await SharedPreferences.getInstance();
    final url = p.getString('webhook');
    if (url == null || url.isEmpty) return;

    final body = payloadCtrl.text
        .replaceAll('%from%', msg.address ?? '')
        .replaceAll('%text%', msg.body ?? '')
        .replaceAll('%receivedStamp%',
            DateTime.now().millisecondsSinceEpoch.toString())
        .replaceAll('%sim%', 'SIM1');

    await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Routing parameters')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text('Sender (number or text)'),
              TextField(controller: senderCtrl),
              const Text('Use * to catch any SMS',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),

              const SizedBox(height: 16),

              const Text('Webhook URL'),
              TextField(
                controller: webhookCtrl,
                decoration: const InputDecoration(
                  hintText: 'https://yourdomain.com/webhook',
                ),
              ),

              const SizedBox(height: 16),

              const Text('SIM Slot'),
              DropdownButtonFormField(
                value: simSlot,
                items: const [
                  DropdownMenuItem(value: 'any', child: Text('any')),
                  DropdownMenuItem(value: 'sim1', child: Text('SIM 1')),
                  DropdownMenuItem(value: 'sim2', child: Text('SIM 2')),
                ],
                onChanged: (v) => setState(() => simSlot = v!),
              ),

              const SizedBox(height: 16),

              const Text('JSON Payload Template'),
              TextField(
                controller: payloadCtrl,
                maxLines: 6,
                style: const TextStyle(fontFamily: 'monospace'),
              ),

              const SizedBox(height: 16),

              const Text('Number of retries'),
              Slider(
                value: retries.toDouble(),
                min: 0,
                max: 20,
                divisions: 20,
                label: retries.toString(),
                onChanged: (v) => setState(() => retries = v.toInt()),
              ),

              CheckboxListTile(
                title: const Text('Ignore SSL/TLS certificate errors'),
                value: ignoreSSL,
                onChanged: (v) => setState(() => ignoreSSL = v!),
              ),

              CheckboxListTile(
                title: const Text('Chunked Mode'),
                value: chunked,
                onChanged: (v) => setState(() => chunked = v!),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      child: const Text('CANCEL'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      child: const Text('SAVE'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
