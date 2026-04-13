import torch
import torch.nn as nn
import torch.nn.functional as F
import torchvision
import torchvision.transforms as transforms
from PIL import Image
import numpy as np
import cv2

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# ======================
# CLASS NAMES (IMPORTANT)
# ======================
class_names = [
    "Acne Vulgaris",
    "Clear Skin",
    "Dermatitis",
    "Fungal Infection"
]

# ======================
# MODEL
# ======================
class GhostModule(nn.Module):
    def __init__(self, in_channels, out_channels, ratio=2):
        super().__init__()
        init_channels = out_channels // ratio
        new_channels = out_channels - init_channels

        self.primary = nn.Sequential(
            nn.Conv2d(in_channels, init_channels, 1, bias=False),
            nn.BatchNorm2d(init_channels),
            nn.SiLU()
        )

        self.cheap = nn.Sequential(
            nn.Conv2d(init_channels, new_channels, 3,
                      padding=1, groups=init_channels, bias=False),
            nn.BatchNorm2d(new_channels),
            nn.SiLU()
        )

    def forward(self, x):
        primary_out = self.primary(x)
        cheap_out = self.cheap(primary_out)
        return torch.cat([primary_out, cheap_out], dim=1)


class SEBlock(nn.Module):
    def __init__(self, channels, reduction=16):
        super().__init__()
        self.fc1 = nn.Linear(channels, channels // reduction)
        self.fc2 = nn.Linear(channels // reduction, channels)

    def forward(self, x):
        B, C, H, W = x.size()
        y = F.adaptive_avg_pool2d(x, 1).view(B, C)
        y = F.relu(self.fc1(y))
        y = torch.sigmoid(self.fc2(y)).view(B, C, 1, 1)
        return x * y


class LargeKernelDW(nn.Module):
    def __init__(self, channels):
        super().__init__()
        self.dw = nn.Conv2d(channels, channels, 5,
                            padding=2, groups=channels, bias=False)
        self.bn = nn.BatchNorm2d(channels)

    def forward(self, x):
        return F.silu(self.bn(self.dw(x)))


class LightAttention(nn.Module):
    def __init__(self, channels):
        super().__init__()
        self.conv = nn.Conv2d(channels, channels, 1, bias=False)

    def forward(self, x):
        B, C, H, W = x.shape
        attn = torch.softmax(self.conv(x).view(B, C, -1), dim=-1)
        return x * attn.view(B, C, H, W)


class SGCMBlock(nn.Module):
    def __init__(self, channels):
        super().__init__()
        self.ghost = GhostModule(channels, channels)
        self.large = LargeKernelDW(channels)
        self.se = SEBlock(channels)
        self.attn = LightAttention(channels)

    def forward(self, x):
        return self.attn(self.se(self.large(self.ghost(x))))


class SGCM(nn.Module):
    def __init__(self, num_classes):
        super().__init__()

        from torchvision.models import MobileNet_V3_Small_Weights
        backbone = torchvision.models.mobilenet_v3_small(
            weights=None
        )

        self.features = backbone.features
        self.sgcm = SGCMBlock(576)
        self.pool = nn.AdaptiveAvgPool2d(1)

        self.classifier = nn.Linear(576, num_classes)

        self.severity_head = nn.Sequential(
            nn.Linear(576, 256),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(256, 64),
            nn.ReLU(),
            nn.Linear(64, 1)
        )

    def forward(self, x):
        x = self.features(x)
        x = self.sgcm(x)
        x = self.pool(x).view(x.size(0), -1)

        class_out = self.classifier(x)
        sev_out = self.severity_head(x)

        return class_out, sev_out


# ======================
# LOAD MODEL
# ======================
model = SGCM(len(class_names)).to(device)

model.load_state_dict(torch.load("sgcm_best.pth", map_location=device))
model.eval()

print("✅ Model loaded correctly")


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
# SEVERITY
# ======================
def compute_severity_from_image(image_pil):
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