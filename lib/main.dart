import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(SyncoApp());
}

enum ConnectionType { usb, wifi }

class SyncoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Synco",
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0E0E0E),
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ConnectionType mode = ConnectionType.usb;

  String status = "Not connected";

  String pcUrl = "http://192.168.1.76:5000"; // 🔥 CHANGE THIS

  String? discoveredIp;

  @override
  void initState() {
    super.initState();
    if (mode == ConnectionType.wifi) {
      startDiscovery();
    }
  }

  // -------------------------
  // WIFI AUTO DISCOVERY
  // -------------------------
  void startDiscovery() async {
    RawDatagramSocket.bind(InternetAddress.anyIPv4, 9999)
        .then((socket) {
      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          Datagram? dg = socket.receive();

          if (dg != null) {
            setState(() {
              discoveredIp = dg.address.address;
              pcUrl = "http://$discoveredIp:5000";
              status = "PC found: $discoveredIp";
            });
          }
        }
      });
    });
  }

  // -------------------------
  // CHECK CONNECTION
  // -------------------------
  Future<void> checkConnection() async {
    try {
      final res = await http.get(Uri.parse("$pcUrl/status"));
      final data = jsonDecode(res.body);

      setState(() {
        status = data["message"];
      });
    } catch (e) {
      setState(() {
        status = "❌ PC not reachable";
      });
    }
  }

  // -------------------------
  // SEND MULTIPLE FILES
  // -------------------------
  Future<void> sendFiles() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);

    if (result == null) return;

    for (var file in result.files) {
      var request =
          http.MultipartRequest("POST", Uri.parse("$pcUrl/upload"));

      request.files.add(await http.MultipartFile.fromPath(
        "file",
        file.path!,
        filename: file.name,
      ));

      await request.send();
    }

    setState(() {
      status = "Sent ${result.files.length} files";
    });
  }

  // -------------------------
  // UI
  // -------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Synco"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // MODE SWITCH
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: Text("USB"),
                  selected: mode == ConnectionType.usb,
                  onSelected: (_) {
                    setState(() {
                      mode = ConnectionType.usb;
                      pcUrl = "http://192.168.1.76:5000";
                      status = "USB mode";
                    });
                  },
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: Text("WiFi"),
                  selected: mode == ConnectionType.wifi,
                  onSelected: (_) {
                    setState(() {
                      mode = ConnectionType.wifi;
                      status = "Searching PC...";
                      startDiscovery();
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // STATUS
            Text(
              status,
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 20),

            // CHECK BUTTON
            ElevatedButton(
              onPressed: checkConnection,
              child: const Text("Check PC"),
            ),

            const SizedBox(height: 20),

            // SEND FILES BUTTON
            ElevatedButton(
              onPressed: sendFiles,
              child: const Text("Send Files"),
            ),
          ],
        ),
      ),
    );
  }
}