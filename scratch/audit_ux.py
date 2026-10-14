import glob, re, sys
sys.stdout.reconfigure(encoding='utf-8')

tscn_files = glob.glob('scenes/**/*.tscn', recursive=True)
print('=== AUDIT DES BOUTONS ET TOUCH TARGETS ===')

small_count = 0
total_buttons = 0

for path in tscn_files:
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    nodes = re.findall(r'\[node name="([^"]+)" type="(Button|TextureButton|OptionButton)"[^\]]*\](.*?)(?=\[node|\Z)', content, re.DOTALL)
    for name, btype, body in nodes:
        total_buttons += 1
        size_match = re.search(r'custom_minimum_size = Vector2\(([^)]+)\)', body)
        font_match = re.search(r'font_size = (\d+)', body)
        text_match = re.search(r'text = "([^"]+)"', body)
        
        size = size_match.group(1) if size_match else 'AUTO'
        font = font_match.group(1) if font_match else 'Theme'
        txt = text_match.group(1) if text_match else ''
        
        if size != 'AUTO':
            parts = [float(p.strip()) for p in size.split(',')]
            w, h = parts[0], parts[1]
            if w < 44 or h < 44:
                small_count += 1
                print(f'[TROP PETIT: <44px] {path} -> {name} : size={size}, font={font}, text="{txt}"')
            elif h < 48:
                print(f'[ATTENTION: <48px] {path} -> {name} : size={size}, font={font}, text="{txt}"')
        else:
            print(f'[AUTO SIZE] {path} -> {name} : font={font}, text="{txt}"')

print(f'\nTotal boutons: {total_buttons}')

print('\n=== AUDIT DES POLICES DE CARACTERES (TEXTES) ===')
small_text_count = 0
for path in tscn_files:
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    labels = re.findall(r'\[node name="([^"]+)" type="Label"[^\]]*\](.*?)(?=\[node|\Z)', content, re.DOTALL)
    for name, body in labels:
        font_match = re.search(r'font_size = (\d+)', body)
        text_match = re.search(r'text = "([^"]+)"', body)
        if font_match and text_match:
            fs = int(font_match.group(1))
            txt = text_match.group(1).replace('\n', ' ')
            if fs < 14:
                small_text_count += 1
                print(f'[POLICE TROP PETITE: {fs}px] {path} -> {name} : "{txt[:30]}"')

print(f'Textes <14px: {small_text_count}')
