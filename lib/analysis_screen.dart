import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'result_screen.dart';

class AnalysisScreen extends StatefulWidget {
  final String imagePath;

  AnalysisScreen({required this.imagePath});

  @override
  _AnalysisScreenState createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  double progress = 0;

  @override
  void initState() {
    super.initState();
    startAnalysis();
  }

  // ======================
  // UPDATE STATS
  // ======================
  Future updateStats(String disease) async {
    final prefs = await SharedPreferences.getInstance();

    int scans = prefs.getInt("scan_count") ?? 0;
    int reports = prefs.getInt("report_count") ?? 0;
    List<String> conditions =
        prefs.getStringList("conditions_list") ?? [];

    scans++;
    reports++;

    if (!conditions.contains(disease)) {
      conditions.add(disease);
    }

    await prefs.setInt("scan_count", scans);
    await prefs.setInt("report_count", reports);
    await prefs.setStringList("conditions_list", conditions);
  }
  Future saveHistory(
  String disease,
  String severity,
  double confidence,
  String imagePath,
  String heatmapUrl,
  List allProbs,
) async {

  final prefs = await SharedPreferences.getInstance();

  List<String> history = prefs.getStringList("history") ?? [];

  String entry =
"$disease|$severity|$confidence|$imagePath|$heatmapUrl|${allProbs.join(",")}|${DateTime.now()}";

  history.insert(0, entry); // latest first

  if (history.length > 20) {
    history = history.sublist(0, 20);
  }

  await prefs.setStringList("history", history);
}

  // ======================
  // ANALYSIS FLOW
  // ======================
  void startAnalysis() async {
    try {
      File imageFile = File(widget.imagePath);

      final result = await ApiService.predict(imageFile);

      String disease = result["disease"] ?? "Unknown";
      String severity = result["severity"] ?? "None";
      double confidence = (result["confidence"] ?? 0).toDouble();

      String? heatmapPath = result["heatmap_url"];
      String heatmapUrl =
          heatmapPath != null ? ApiService.baseUrl + heatmapPath : "";

      // 🔥 NEW: ALL PROBABILITIES
      List allProbs = result["all_probs"] ?? [];

      print("API RESULT: $result");

      // ======================
      // UPDATE STATS (ONLY VALID)
      // ======================
      if (disease != "Not a skin image" &&
          disease != "Other skin condition") {
        await saveHistory(
  disease,
  severity,
  confidence,
  widget.imagePath,
  heatmapUrl,
  allProbs,
);
      }

      // ======================
      // PROGRESS ANIMATION
      // ======================
      Timer.periodic(Duration(milliseconds: 200), (timer) {
        setState(() {
          progress += 0.05;
        });

        if (progress >= 1) {
          timer.cancel();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ResultScreen(
                disease: disease,
                severity: severity,
                confidence: confidence,
                heatmapUrl: heatmapUrl,
                allProbs: allProbs, // 🔥 PASS HERE
              ),
            ),
          );
        }
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  // ======================
  // STEP UI
  // ======================
  Widget buildStep(String text, double threshold) {
    bool done = progress > threshold;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: done ? Colors.green.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: done ? Colors.green : Colors.grey,
          ),
          SizedBox(width: 10),
          Text(text),
        ],
      ),
    );
  }

  // ======================
  // UI
  // ======================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEFF5FB),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2F6EDB), Color(0xFF4CB8C4)],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.science, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    "AI Analysis",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),

            SizedBox(height: 20),

            // IMAGE PREVIEW
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                File(widget.imagePath),
                height: 160,
                width: 160,
                fit: BoxFit.cover,
              ),
            ),

            SizedBox(height: 20),

            Text(
              "Analyzing your skin...",
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 20),

            // PROGRESS BAR
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            SizedBox(height: 20),

            // PIPELINE STEPS
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  buildStep("Image Quality Check", 0.2),
                  buildStep("Feature Extraction", 0.4),
                  buildStep("Pattern Recognition", 0.6),
                  buildStep("Disease Classification", 0.8),
                  buildStep("Confidence Scoring", 0.95),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}