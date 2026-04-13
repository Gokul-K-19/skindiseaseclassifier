import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'upload_screen.dart';
import 'profile_screen.dart';
import 'history_screen.dart';
import 'result_screen.dart'; // ✅ FIXED: Added missing import

void main() {
  runApp(SkinApp());
}

class SkinApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String username = "User";
  File? profileImage;

  int scanCount = 0;
  int reportCount = 0;
  int conditionCount = 0;

  List<String> history = <String>[]; // ✅ safer typing
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // ======================
  // LOAD DATA
  // ======================
  void loadData() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return; // ✅ FIXED: avoid crash

    setState(() {
      history = prefs.getStringList("history") ?? [];

      username = prefs.getString("username") ?? "User";

      String? path = prefs.getString("profile_image");

      // ✅ FIXED: check file exists
      if (path != null && File(path).existsSync()) {
        profileImage = File(path);
      } else {
        profileImage = null;
      }

      scanCount = prefs.getInt("scan_count") ?? 0;
      reportCount = prefs.getInt("report_count") ?? 0;

      List<String> conditions =
          prefs.getStringList("conditions_list") ?? [];
      conditionCount = conditions.length;
    });
  }

  // ======================
  // 🔍 SEARCH FUNCTION
  // ======================
  List<String> getFilteredHistory() {
    if (searchQuery.isEmpty) return history;

    return history.where((item) {
      return item.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  // ======================
  // UI CARD
  // ======================
  Widget statCard(String number, String label, Color color) {
    return Expanded( // ✅ FIXED: prevent overflow
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 5),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(number,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color)),
            SizedBox(height: 5),
            Text(label),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var filteredHistory = getFilteredHistory();

    return Scaffold(
      backgroundColor: Color(0xFFEFF5FB),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2F6EDB), Color(0xFF4CB8C4)],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TOP ROW
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Hello, $username 👋",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ProfileScreen()),
                          );
                          if (result == true) loadData();
                        },
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          backgroundImage: profileImage != null
                              ? FileImage(profileImage!)
                              : null,
                          child: profileImage == null
                              ? Icon(Icons.person, color: Colors.black)
                              : null,
                        ),
                      )
                    ],
                  ),

                  SizedBox(height: 15),

                  Text(
                    "What skin issue do you want to analyze today?",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),

                  SizedBox(height: 20),

                  // 🔍 SEARCH BAR
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search previous scans...",
                        border: InputBorder.none,
                        icon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // STATS
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  statCard("$scanCount", "Scans Done", Colors.blue),
                  statCard("$conditionCount", "Conditions", Colors.green),
                  statCard("$reportCount", "Reports", Colors.orange),
                ],
              ),
            ),

            SizedBox(height: 20),

            // MAIN CARD
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2F6EDB), Color(0xFF4CB8C4)],
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Scan Your Skin Now",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Text("Upload a photo to get instant AI-powered diagnosis",
                        style: TextStyle(color: Colors.white70)),
                    SizedBox(height: 15),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => UploadScreen()),
                        );

                        loadData();
                      },
                      icon: Icon(Icons.upload),
                      label: Text("Upload Image"),
                    )
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // RECENT SCANS HEADER
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Recent Scans",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => HistoryScreen()),
                      );
                    },
                    child: Text("See All",
                        style: TextStyle(color: Colors.blue)),
                  )
                ],
              ),
            ),

            SizedBox(height: 10),

            // 🔥 HISTORY LIST
            Expanded(
              child: filteredHistory.isEmpty
                  ? Center(child: Text("No history found")) // ✅ FIXED
                  : ListView(
                      children: filteredHistory.take(3).map((item) {
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
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ResultScreen(
                                  disease: disease,
                                  severity: severity,
                                  confidence: confidence,
                                  heatmapUrl: heatmapUrl,
                                  allProbs: allProbs,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                    child: Icon(Icons.science)),
                                SizedBox(width: 10),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(disease,
                                          style: TextStyle(
                                              fontWeight:
                                                  FontWeight.bold)),
                                      Text(
                                          date.length >= 10
                                              ? date.substring(0, 10)
                                              : date,
                                          style: TextStyle(
                                              color: Colors.grey)),
                                    ],
                                  ),
                                ),

                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.2),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: Text("$severity Risk"),
                                )
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}