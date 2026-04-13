import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<String> history = [];

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  void loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      history = prefs.getStringList("history") ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scan History")),
      body: ListView(
        children: history.map((item) {
          List parts = item.split("|");

// ✅ DEFAULT VALUES
String disease = parts.length > 0 ? parts[0] : "Unknown";
String severity = parts.length > 1 ? parts[1] : "None";
double confidence =
    parts.length > 2 ? double.tryParse(parts[2]) ?? 0 : 0;
String imagePath = parts.length > 3 ? parts[3] : "";

// ✅ NEW FIELDS (SAFE)
String heatmapUrl = parts.length > 4 ? parts[4] : "";

List allProbs = [];
if (parts.length > 5 && parts[5].isNotEmpty) {
  allProbs =
      parts[5].split(",").map((e) => double.tryParse(e) ?? 0).toList();
}

// ✅ DATE SAFE
String date = parts.length > 6
    ? parts[6]
    : (parts.length > 4 ? parts[4] : "");

          return ListTile(
            leading: CircleAvatar(
              backgroundImage: File(imagePath).existsSync()
                  ? FileImage(File(imagePath))
                  : null,
              child: File(imagePath).existsSync()
                  ? null
                  : Icon(Icons.image),
            ),
            title: Text(disease),
            subtitle: Text(date.substring(0, 10)),
            trailing: Text("$severity"),

            // 🔥 CLICK TO OPEN RESULT
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ResultScreen(
                    disease: disease,
                    severity: severity,
                    confidence: confidence,
                    heatmapUrl: heatmapUrl,   // ⚠️ no saved heatmap
                    allProbs: allProbs,     // ⚠️ no saved probs
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}