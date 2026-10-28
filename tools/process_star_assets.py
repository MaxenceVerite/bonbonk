from PIL import Image
import numpy as np
from collections import deque

def remove_white_background_floodfill(img_path, out_path, tolerance=25):
    img = Image.open(img_path).convert("RGBA")
    arr = np.array(img)
    h, w = arr.shape[:2]
    
    # Masque des pixels extérieurs
    visited = np.zeros((h, w), dtype=bool)
    q = deque()
    
    # Enfile les bords
    for x in range(w):
        q.append((0, x))
        q.append((h - 1, x))
    for y in range(h):
        q.append((y, 0))
        q.append((y, w - 1))
        
    while q:
        cy, cx = q.popleft()
        if visited[cy, cx]:
            continue
        visited[cy, cx] = True
        
        r, g, b = arr[cy, cx, :3]
        # Si c'est proche du blanc
        if r >= 255 - tolerance and g >= 255 - tolerance and b >= 255 - tolerance:
            arr[cy, cx, 3] = 0 # Transparent
            for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                ny, nx = cy + dy, cx + dx
                if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx]:
                    q.append((ny, nx))
        elif r >= 230 and g >= 230 and b >= 230:
            # Bordure douce / antialiasing
            dist = max(255 - r, 255 - g, 255 - b)
            alpha = int((dist / (tolerance + 15)) * 255)
            arr[cy, cx, 3] = min(arr[cy, cx, 3], alpha)
            
    out_img = Image.fromarray(arr, "RGBA")
    # Rogner la boîte englobante pour avoir un sprite bien centré
    bbox = out_img.getbbox()
    if bbox:
        out_img = out_img.crop(bbox)
    # Redimensionner à une taille nette standard (ex 256x256)
    out_img = out_img.resize((256, 256), Image.Resampling.LANCZOS)
    out_img.save(out_path, "PNG")
    print(f"Processed: {out_path}")

gold_path = r"C:\Users\Maxence\.gemini\antigravity-ide\brain\e0926cf3-8f29-4780-bd14-e097223fe3b8\big_gold_star_1793191226883.jpg"
empty_path = r"C:\Users\Maxence\.gemini\antigravity-ide\brain\e0926cf3-8f29-4780-bd14-e097223fe3b8\big_empty_star_1793191246681.jpg"

remove_white_background_floodfill(gold_path, r"c:\Users\Maxence\Desktop\repositories\Flip\assets\ui\star_gold_3d.png", tolerance=35)
remove_white_background_floodfill(empty_path, r"c:\Users\Maxence\Desktop\repositories\Flip\assets\ui\star_empty_3d.png", tolerance=35)
