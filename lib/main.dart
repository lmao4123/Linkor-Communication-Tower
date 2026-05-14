import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const SyncoApp());
}

enum ConnectionType { usb, wifi }

class SyncoApp extends StatelessWidget {
  const SyncoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Synco",
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0E0E0E),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ConnectionType mode = ConnectionType.usb;

  String status = "Not connected";

  String pcUrl = "http://192.168.1.76:5000"; // change this if needed

  String? discoveredIp;

  // -------------------------
  // WIFI DISCOVERY
  // -------------------------
  void startDiscovery() async {
    try {
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
    } catch (e) {
      setState(() {
        status = "WiFi discovery error";
      });
    }
  }

  // -------------------------
  // CHECK CONNECTION
  // -------------------------
  Future<void> checkConnection() async {
    try {
      final res = await http.get(Uri.parse("$pcUrl/status"));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          status = data["message"];
        });
      } else {
        setState(() {
          status = "❌ Server error";
        });
      }
    } catch (e) {
      setState(() {
        status = "❌ PC not reachable";
      });
    }
  }

  // -------------------------
  // SEND FILES (FIXED)
  // -------------------------
  Future<void> sendFiles() async {
    try {
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(allowMultiple: true);

      if (result == null) {
        setState(() => status = "No files selected");
        return;
      }

      int sent = 0;

      for (var file in result.files) {
        if (file.path == null) continue;

        var request = http.MultipartRequest(
          "POST",
          Uri.parse("$pcUrl/upload"),
        );

        request.files.add(
          await http.MultipartFile.fromPath(
            "file",
            file.path!,
            filename: file.name,
          ),
        );

        var response = await request.send();

        print("UPLOAD ${file.name}: ${response.statusCode}");

        if (response.statusCode == 200) {
          sent++;
        }
      }

      setState(() {
        status = "Sent $sent/${result.files.length} files";
      });
    } catch (e) {
      setState(() {
        status = "Upload error: $e";
      });
    }
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
                  label: const Text("USB"),
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
                  label: const Text("WiFi"),
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

            // CHECK CONNECTION
            ElevatedButton(
              onPressed: checkConnection,
              child: const Text("Check PC"),
            ),

            const SizedBox(height: 20),

            // SEND FILES
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