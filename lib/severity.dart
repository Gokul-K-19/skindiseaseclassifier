import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

String computeSeverity(String imagePath) {
  final bytes = File(imagePath).readAsBytesSync();
  img.Image? image = img.decodeImage(bytes);

  if (image == null) return "Unknown";

  int width = image.width;
  int height = image.height;

  int totalPixels = width * height;

  double redSum = 0;
  double brightnessSum = 0;
  List<double> grayValues = [];

  int lesionPixels = 0;

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      var pixel = image.getPixel(x, y);

      num r = pixel.r;
      num g = pixel.g;
      num b = pixel.b;

      double gray = (r + g + b) / 3.0;

      grayValues.add(gray);

      redSum += r;
      brightnessSum += gray;
    }
  }

  double redMean = redSum / totalPixels;
  double brightnessMean = brightnessSum / totalPixels;

  // SECOND PASS
  double variance = 0;

  for (int i = 0; i < grayValues.length; i++) {
    variance += pow(grayValues[i] - brightnessMean, 2);
  }

  double texture = sqrt(variance / totalPixels) / 255.0;

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      var pixel = image.getPixel(x, y);

      num r = pixel.r;
      num g = pixel.g;  
      num b = pixel.b;

      double gray = (r + g + b) / 3.0;

      bool redMask = r > (redMean + 20);
      bool darkMask = gray < (brightnessMean - 20);

      if (redMask || darkMask) {
        lesionPixels++;
      }
    }
  }

  double lesionRatio = lesionPixels / totalPixels;

  double severity = (
    0.45 * lesionRatio +
    0.20 * texture
  );

  severity = ((severity - 0.05) / 0.4).clamp(0, 1);

  if (severity < 0.32) return "Mild";
  if (severity < 0.58) return "Moderate";
  return "Severe";
}