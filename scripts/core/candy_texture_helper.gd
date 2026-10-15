class_name CandyTextureHelper
extends RefCounted

## Helper utilitaire pour charger de façon 100% fiable les textures graphiques
## Supporte à la fois le ResourceLoader standard de Godot et le fallback direct Image.load_from_file.

static var _cache: Dictionary = {}

static func load_texture(res_path: String) -> Texture2D:
	if _cache.has(res_path):
		var cached: Texture2D = _cache[res_path]
		if cached != null and is_instance_valid(cached):
			return cached

	# 1. Tentative standard Godot
	if ResourceLoader.exists(res_path):
		var res: Resource = load(res_path)
		if res is Texture2D:
			_cache[res_path] = res
			return res

	# 2. Fallback direct sur disque (évite les soucis de cache .ctex non re-généré)
	var abs_path: String = ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(abs_path):
		var img: Image = Image.load_from_file(abs_path)
		if img != null and not img.is_empty():
			var itex: ImageTexture = ImageTexture.create_from_image(img)
			_cache[res_path] = itex
			return itex

	return null
