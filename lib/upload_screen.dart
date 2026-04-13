import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'analysis_screen.dart';

class UploadScreen extends StatefulWidget {
  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final picker = ImagePicker();

  Future pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              AnalysisScreen(imagePath: pickedFile.path),
        ),
      );
    }
  }

  Widget optionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget guidelineItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check, size: 16, color: Colors.green),
          SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  void showPickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text("Take Photo"),
              onTap: () {
                Navigator.pop(context);
                pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.image),
              title: Text("From Gallery"),
              onTap: () {
                Navigator.pop(context);
                pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
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
                      "Upload Skin Image",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),

              SizedBox(height: 20),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // 📦 UPLOAD BOX
                    GestureDetector(
                      onTap: showPickerOptions,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Color(0xFFEAF2FB),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.blue,
                            style: BorderStyle.solid,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.camera_alt,
                                size: 40, color: Colors.blue),

                            SizedBox(height: 10),

                            Text(
                              "Drag & Drop or Tap to Upload",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),

                            SizedBox(height: 5),

                            Text(
                              "Supports JPG, PNG, HEIC • Max 10MB",
                              style: TextStyle(color: Colors.grey),
                            ),

                            SizedBox(height: 15),

                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: showPickerOptions,
                              child: Text("Browse Files"),
                            )
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    Text("OR", style: TextStyle(color: Colors.grey)),

                    SizedBox(height: 10),

                    // 📷 OPTIONS
                    optionTile(
                      title: "Take a Photo",
                      subtitle: "Use your camera right now",
                      icon: Icons.camera_alt,
                      color: Colors.blue,
                      onTap: () => pickImage(ImageSource.camera),
                    ),

                    optionTile(
                      title: "From Gallery",
                      subtitle: "Pick from your photo library",
                      icon: Icons.image,
                      color: Colors.green,
                      onTap: () => pickImage(ImageSource.gallery),
                    ),

                    SizedBox(height: 20),

                    // 📋 GUIDELINES
                    Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text("Photo Guidelines",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold)),

                          SizedBox(height: 10),

                          guidelineItem(
                              "Good lighting – avoid shadows"),
                          guidelineItem(
                              "Clear, close-up of the affected area"),
                          guidelineItem(
                              "Avoid blurry or filtered images"),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // 💡 TIPS
                    Text(
                      "Tips for best results →",
                      style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold),
                    ),

                    SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}