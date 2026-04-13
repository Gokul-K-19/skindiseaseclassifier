import 'package:flutter/material.dart';

class ReportScreen extends StatelessWidget {
  final String disease;
  final String severity;
  final double confidence;

  ReportScreen({
    required this.disease,
    required this.severity,
    required this.confidence,
  });

  Color getSeverityColor() {
    switch (severity) {
      case "Mild":
        return Colors.green;
      case "Moderate":
        return Colors.orange;
      case "Severe":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String getDescription() {
    if (disease.contains("Acne")) {
      return "Acne is a common skin condition caused by clogged pores, oil, and bacteria.";
    } else if (disease.contains("Fungal")) {
      return "Fungal infections are caused by fungi and can spread if untreated.";
    } else if (disease.contains("Dermatitis")) {
      return "Dermatitis is inflammation of the skin causing redness and irritation.";
    } else {
      return "General skin condition detected.";
    }
  }

  String getRecommendation() {
    if (severity == "Mild") {
      return "Maintain proper hygiene and basic skincare routine.";
    } else if (severity == "Moderate") {
      return "Use medicated creams and monitor symptoms.";
    } else if (severity == "Severe") {
      return "Consult a dermatologist immediately.";
    } else {
      return "Follow general skin care practices.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEFF5FB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 🔵 HEADER
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
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Medical Report",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),

              SizedBox(height: 20),

              // 🧠 DISEASE CARD
              buildCard(
                title: "Detected Condition",
                content: disease,
              ),

              // 📊 CONFIDENCE
              buildProgressCard(
                title: "Confidence Level",
                value: confidence,
              ),

              // ⚠️ SEVERITY
              buildSeverityCard(),

              // 📄 DESCRIPTION
              buildCard(
                title: "Description",
                content: getDescription(),
              ),

              // 💡 RECOMMENDATION
              buildCard(
                title: "Recommendation",
                content: getRecommendation(),
              ),

              SizedBox(height: 20),

              // 📥 BUTTON
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2F6EDB), Color(0xFF4CB8C4)],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.all(15),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text("Back to Home"),
                  ),
                ),
              ),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 REUSABLE CARD
  Widget buildCard({required String title, required String content}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            Text(content),
          ],
        ),
      ),
    );
  }

  // 🔹 PROGRESS CARD
  Widget buildProgressCard({required String title, required double value}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 10),
            LinearProgressIndicator(
              value: value,
              minHeight: 10,
              borderRadius: BorderRadius.circular(10),
            ),
            SizedBox(height: 5),
            Text("${(value * 100).toStringAsFixed(1)}%"),
          ],
        ),
      ),
    );
  }

  // 🔹 SEVERITY CARD
  Widget buildSeverityCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: getSeverityColor().withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: getSeverityColor()),
            SizedBox(width: 10),
            Text(
              "Severity: $severity",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: getSeverityColor()),
            ),
          ],
        ),
      ),
    );
  }
}