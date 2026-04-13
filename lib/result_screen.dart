import 'package:flutter/material.dart';
import 'report_screen.dart';

class ResultScreen extends StatelessWidget {
  final String disease;
  final String severity;
  final double confidence;
  final String heatmapUrl;
  final List allProbs;

  ResultScreen({
    required this.disease,
    required this.severity,
    required this.confidence,
    required this.heatmapUrl,
    required this.allProbs,
  });

  List<String> classes = [
    "Acne",
    "Clear",
    "Dermatitis",
    "Fungal"
  ];

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

  List<String> getFutureRisk() {
    if (disease.contains("Fungal")) {
      return [
        "May spread to other body areas",
        "Can become chronic if untreated"
      ];
    } else if (disease.contains("Dermatitis")) {
      return [
        "Skin thickening over time",
        "Increased irritation and sensitivity"
      ];
    } else if (disease.contains("Acne")) {
      return [
        "Permanent acne scars",
        "Dark spots and pigmentation"
      ];
    } else {
      return ["Maintain proper skin hygiene"];
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isValid = disease != "Not a skin image";

    return Scaffold(
      backgroundColor: Color(0xFFEFF5FB),
      body: SafeArea(
        child: SingleChildScrollView(
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
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(30)),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Analysis Results",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),

              SizedBox(height: 20),

              // MAIN CARD
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 70,
                        width: 70,
                        decoration: BoxDecoration(
                          color: Color(0xFFEAF2FB),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(Icons.science, size: 30),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(disease,
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),

                            SizedBox(height: 8),

                            if (isValid)
                              Wrap(
                                spacing: 8,
                                children: [
                                  chip("${(confidence * 100).toStringAsFixed(0)}% Confidence", Colors.green),
                                  chip("$severity Risk", getSeverityColor()),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              // 🔥 REAL AI CONFIDENCE
              if (isValid && allProbs.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("AI Confidence Score",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),

                        ...List.generate(classes.length, (i) {
                          return buildBar(
                            classes[i],
                            allProbs[i].toDouble(),
                            i == 0
                                ? Colors.green
                                : i == 1
                                    ? Colors.blue
                                    : i == 2
                                        ? Colors.orange
                                        : Colors.red,
                          );
                        })
                      ],
                    ),
                  ),
                ),

              SizedBox(height: 20),

              // FUTURE RISK
              if (isValid)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Future Risk (if untreated)",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        ...getFutureRisk().map((e) => Text("• $e"))
                      ],
                    ),
                  ),
                ),

              SizedBox(height: 20),

              if (heatmapUrl.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: (heatmapUrl.isNotEmpty &&
        (heatmapUrl.startsWith("http") ||
         heatmapUrl.startsWith("/static")))
    ? Image.network(
        heatmapUrl,
        height: 220,
        fit: BoxFit.cover,
      )
    : SizedBox(),
                  ),
                ),

              SizedBox(height: 20),

              // BUTTON
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
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReportScreen(
                            disease: disease,
                            severity: severity,
                            confidence: confidence,
                          ),
                        ),
                      );
                    },
                    child: Text("Full Report"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget chip(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(color: color)),
    );
  }

  Widget buildBar(String label, double value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label)),
          Expanded(
            child: LinearProgressIndicator(
              value: value,
              color: color,
              backgroundColor: Colors.grey[300],
            ),
          ),
          SizedBox(width: 10),
          Text("${(value * 100).toInt()}%"),
        ],
      ),
    );
  }
}