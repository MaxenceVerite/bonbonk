from PIL import Image, ImageFilter
import numpy as np
import os

def isolate_black_background(input_path, output_path, threshold=20, feather=2):
    img = Image.open(input_path).convert("RGBA")
    data = np.array(img, dtype=np.float32)

    # Luminance de fond
    r, g, b, a = data[:,:,0], data[:,:,1], data[:,:,2], data[:,:,3]
    brightness = 0.299 * r + 0.587 * g + 0.114 * b

    # Masque alpha basé sur la luminosité du fond noir
    # Pour les éléments sombres, seuil progressif
    alpha = np.clip((brightness - threshold) / 30.0, 0.0, 1.0) * 255.0

    # Color de-blacking : éclaircir les pixels sombres semi-transparents au bord
    # pour éviter une frange noire
    nonzero = alpha > 0
    factor = np.zeros_like(alpha)
    factor[nonzero] = 255.0 / np.maximum(alpha[nonzero], 1.0)
    # Clamp factor
    factor = np.clip(factor, 1.0, 2.5)

    data[:,:,0] = np.clip(data[:,:,0] * factor, 0, 255)
    data[:,:,1] = np.clip(data[:,:,1] * factor, 0, 255)
    data[:,:,2] = np.clip(data[:,:,2] * factor, 0, 255)
    data[:,:,3] = alpha

    result = Image.fromarray(data.astype(np.uint8), "RGBA")
    
    # Bounding box crop
    bbox = result.getbbox()
    if bbox:
        result = result.crop(bbox)
        # Pad slightly by 4px
        padded = Image.new("RGBA", (result.width + 8, result.height + 8), (0, 0, 0, 0))
        padded.paste(result, (4, 4))
        result = padded

    # Redimensionner proprement en taille standard 256x256
    result.thumbnail((256, 256), Image.Resampling.LANCZOS)
    result.save(output_path, "PNG")
    print(f"Saved: {output_path} ({result.size})")

os.makedirs("assets/ui", exist_ok=True)
coin_in = r"C:\Users\Maxence\.gemini\antigravity-ide\brain\e0926cf3-8f29-4780-bd14-e097223fe3b8\coin_gold_3d_1793202216538.jpg"
gem_in = r"C:\Users\Maxence\.gemini\antigravity-ide\brain\e0926cf3-8f29-4780-bd14-e097223fe3b8\gem_diamond_3d_1793202245848.jpg"

isolate_black_background(coin_in, "assets/ui/coin_gold_3d.png", threshold=15)
isolate_black_background(gem_in, "assets/ui/gem_diamond_3d.png", threshold=15)
print("Processing complete!")
