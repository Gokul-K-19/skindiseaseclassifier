from flask import Flask, request, jsonify
from flask_cors import CORS
import torch
import torch.nn.functional as F
import torchvision.transforms as transforms
from PIL import Image
import numpy as np
import cv2
import os
import uuid

# ======================
# DEVICE
# ======================
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# ======================
# MODEL
# ======================
from Final_pred import SGCM

class_names = [
    "Acne",
    "Clear",
    "Dermatitis",
    "Fungal"
]

model = SGCM(len(class_names)).to(device)
model.load_state_dict(torch.load("sgcm_best.pth", map_location=device))
model.eval()

# ======================
# TRANSFORM
# ======================
transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize([0.485, 0.456, 0.406],
                         [0.229, 0.224, 0.225])
])

# ======================
# SKIN DETECTOR
# ======================
def is_skin_image(image_pil):
    img = np.array(image_pil.convert("RGB"))
    img = cv2.resize(img, (224, 224))

    hsv = cv2.cvtColor(img, cv2.COLOR_RGB2HSV)

    lower = np.array([0, 30, 60], dtype=np.uint8)
    upper = np.array([20, 150, 255], dtype=np.uint8)

    skin_mask = cv2.inRange(hsv, lower, upper)
    skin_ratio = np.sum(skin_mask > 0) / skin_mask.size

    return skin_ratio > 0.15

# ======================
# SEVERITY
# ======================
def compute_severity(image_pil):
    img = np.array(image_pil.convert("RGB"))
    img = cv2.resize(img, (224, 224))

    lab = cv2.cvtColor(img, cv2.COLOR_RGB2LAB)
    L, A, B = cv2.split(lab)

    gray = cv2.cvtColor(img, cv2.COLOR_RGB2GRAY)

    red_mask = A > (np.mean(A) + 6)
    dark_mask = L < (np.mean(L) - 10)

    lesion_mask = red_mask | dark_mask
    lesion_ratio = np.sum(lesion_mask) / lesion_mask.size

    texture = np.std(gray) / 255.0
    edges = cv2.Canny(gray, 40, 120)
    edge_density = np.sum(edges > 0) / edges.size
    color_var = np.std(A) / 255.0

    severity = (
        0.45 * lesion_ratio +
        0.20 * texture +
        0.20 * edge_density +
        0.15 * color_var
    )

    severity = np.clip((severity - 0.08) / 0.35, 0, 1)

    if severity < 0.32:
        return "Mild"
    elif severity < 0.58:
        return "Moderate"
    else:
        return "Severe"

# ======================
# GRAD-CAM HOOKS
# ======================
features = []
gradients = []

def forward_hook(module, input, output):
    features.append(output)

def backward_hook(module, grad_in, grad_out):
    gradients.append(grad_out[0])

# 🔥 Try earlier layer for better spread
target_layer = model.features[-1]
target_layer.register_forward_hook(forward_hook)
target_layer.register_backward_hook(backward_hook)

# ======================
# IMPROVED GRAD-CAM
# ======================
def generate_gradcam(image_tensor):
    features.clear()
    gradients.clear()

    output, _ = model(image_tensor)
    pred_class = output.argmax(dim=1)

    model.zero_grad()
    output[0, pred_class].backward()

    grad = gradients[0]
    fmap = features[0]

    weights = torch.mean(grad, dim=(2, 3), keepdim=True)

    cam = (weights * fmap).sum(dim=1, keepdim=True)

    cam = torch.relu(cam)

    cam = cam.squeeze().detach().cpu().numpy()

    # Normalize
    cam = cam - cam.min()
    cam = cam / (cam.max() + 1e-8)

    # ✅ Expand region slightly
    cam = np.power(cam, 0.3)
    cam = np.maximum(cam, 0.2 * cam.max())

    return cam

# ======================
# APP
# ======================
app = Flask(__name__, static_folder="static")
CORS(app)

@app.route('/')
def home():
    return "API Running"

@app.route('/predict', methods=['POST'])
def predict():
    file = request.files['image']
    image = Image.open(file.stream).convert("RGB")

    # ======================
    # SKIN CHECK
    # ======================
    if not is_skin_image(image):
        return jsonify({
            "disease": "Not a skin image",
            "confidence": 0.0,
            "severity": None,
            "heatmap_url": None,
            "all_probs": []
        })

    input_tensor = transform(image).unsqueeze(0).to(device)

    # ======================
    # MODEL
    # ======================
    with torch.no_grad():
        class_out, _ = model(input_tensor)
        probs = torch.softmax(class_out, dim=1)

        conf, pred = torch.max(probs, 1)
        confidence = float(conf.item())

        sorted_probs, _ = torch.sort(probs, descending=True)
        second_conf = float(sorted_probs[0][1].item())

    disease = class_names[pred.item()]

    # ======================
    # UNKNOWN DETECTION
    # ======================
    if confidence < 0.65 or (confidence - second_conf) < 0.15:
        return jsonify({
            "disease": "Other skin condition",
            "confidence": confidence,
            "severity": None,
            "heatmap_url": None,
            "all_probs": probs.squeeze().tolist()
        })

    # ======================
    # SEVERITY
    # ======================
    if "clear" not in disease.lower():
        severity = compute_severity(image)
    else:
        severity = None

    # ======================
    # GRAD-CAM
    # ======================
    cam = generate_gradcam(input_tensor)

    heatmap = cv2.resize(cam, (224, 224))

    heatmap = np.uint8(255 * heatmap)
    heatmap = cv2.applyColorMap(heatmap, cv2.COLORMAP_JET)

# ✅ LIGHT blur (not heavy)
    heatmap = cv2.GaussianBlur(heatmap, (7, 7), 0)

    original = np.array(image.resize((224, 224)))

# ✅ Better blending
    overlay = cv2.addWeighted(original, 0.7, heatmap, 0.5, 0)

    # ======================
    # SAVE
    # ======================
    if not os.path.exists("static"):
        os.makedirs("static")

    filename = f"heatmap_{uuid.uuid4().hex}.jpg"
    heatmap_path = os.path.join("static", filename)

    cv2.imwrite(heatmap_path, overlay)

    return jsonify({
        "disease": disease,
        "confidence": confidence,
        "severity": severity,
        "heatmap_url": f"/static/{filename}",
        "all_probs": probs.squeeze().tolist()
    })

# ======================
# RUN
# ======================
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
import os

port = int(os.environ.get("PORT", 5000))

app.run(host="0.0.0.0", port=port)