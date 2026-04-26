import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(SyncoApp());
}

enum DeviceMode {
  charging,
  fileTransfer,
  control,
  approval,
  idle,
}

class SyncoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Synco",
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DeviceMode currentMode = DeviceMode.idle;
  String status = "Not connected";

  final String pcUrl = "http://192.168.1.76:5000";

  String modeText(DeviceMode mode) {
    switch (mode) {
      case DeviceMode.charging:
        return "🔋 Charging";
      case DeviceMode.fileTransfer:
        return "📁 File Transfer";
      case DeviceMode.control:
        return "🎮 Control";
      case DeviceMode.approval:
        return "🔒 Approval";
      case DeviceMode.idle:
        return "⚪ Idle";
    }
  }

  Future<void> checkConnection() async {
    try {
      final res = await http.get(Uri.parse("$pcUrl/status"));
      final data = jsonDecode(res.body);

      setState(() {
        status = "${data["message"]} | Mode: ${data["mode"]}";
      });
    } catch (e) {
      setState(() {
        status = "❌ PC not reachable";
      });
    }
  }

  Future<void> setMode(DeviceMode mode) async {
    try {
      await http.post(
        Uri.parse("$pcUrl/mode"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"mode": mode.name}),
      );

      setState(() {
        currentMode = mode;
        status = "Mode: ${mode.name}";
      });
    } catch (e) {
      setState(() {
        status = "❌ Mode error";
      });
    }
  }

  Future<void> sendFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
      );

      if (result == null) return;

      for (var file in result.files) {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse("$pcUrl/upload"),
        );

        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path!,
            filename: file.name,
          ),
        );

        await request.send();
      }

      setState(() {
        status = "📁 Sent ${result.files.length} files";
      });

    } catch (e) {
      setState(() {
        status = "❌ Transfer failed";
      });
    }
  }

  Widget modeButton(String title, DeviceMode mode) {
    return ElevatedButton(
      onPressed: () => setMode(mode),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
      ),
      child: Text(title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        title: Text("Synco"),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // STATUS BOX
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF1C1C1C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "Status: $status",
                style: TextStyle(color: Colors.white),
              ),
            ),

            SizedBox(height: 20),

            // MODE DISPLAY
            Text(
              "Mode: ${modeText(currentMode)}",
              style: TextStyle(
                color: Colors.greenAccent,
                fontSize: 18,
              ),
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: checkConnection,
              child: Text("Check PC Connection"),
            ),

            SizedBox(height: 20),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                modeButton("Charging", DeviceMode.charging),
                modeButton("File", DeviceMode.fileTransfer),
                modeButton("Control", DeviceMode.control),
                modeButton("Approval", DeviceMode.approval),
                modeButton("Idle", DeviceMode.idle),
              ],
            ),

            SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: sendFiles,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(16),
                  backgroundColor: Colors.blueAccent,
                ),
                child: Text("Send Files"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}