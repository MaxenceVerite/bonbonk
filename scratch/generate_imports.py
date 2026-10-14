import os, hashlib, uuid

TEMPLATE = """[remap]

importer="texture"
type="CompressedTexture2D"
uid="{uid}"
path="res://.godot/imported/{filename}-{md5}.ctex"
metadata={{
"vram_texture": false
}}

[deps]

source_file="res://assets/ui/{filename}"
dest_files=["res://.godot/imported/{filename}-{md5}.ctex"]

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=1
"""

files = ['booster_bag_hero.png', 'card_gauge_bg.png', 'card_gauge_fill.png', 'card_gauge_fill_blue.png', 'icon_ball_mint.png', 'icon_ball_cherry.png']
for fn in files:
    full = os.path.join('assets/ui', fn)
    with open(full, 'rb') as f:
        data = f.read()
    m = hashlib.md5(data).hexdigest()
    u = 'uid://' + uuid.uuid4().hex[:13]
    content = TEMPLATE.format(filename=fn, md5=m, uid=u)
    with open(full + '.import', 'w', encoding='utf-8') as f:
        f.write(content)
    print('Created .import for', fn, 'md5:', m[:8])
