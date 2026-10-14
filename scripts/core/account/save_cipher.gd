class_name SaveCipher
extends RefCounted

## Utilitaire de persistance chiffrée AES pour les profils locaux.
## Garantit l'intégrité via écriture atomique et copie de secours (.bak).

const APP_SALT: String = "Bonbonk_Flip_AES256_Secret_Salt_v1"
const DEVICE_TOKEN_PATH: String = "user://device_token.id"

static func get_cipher_key() -> String:
	var dev_id: String = OS.get_unique_id()
	if dev_id.is_empty():
		dev_id = _get_or_create_fallback_device_id()
	return (APP_SALT + ":" + dev_id).sha256_text().substr(0, 32)

static func _get_or_create_fallback_device_id() -> String:
	if FileAccess.file_exists(DEVICE_TOKEN_PATH):
		var f: FileAccess = FileAccess.open(DEVICE_TOKEN_PATH, FileAccess.READ)
		if f != null:
			var txt: String = f.get_as_text().strip_edges()
			f.close()
			if not txt.is_empty():
				return txt

	# Génération d'un UUID pseudo-aléatoire persistant
	var generated: String = "dev_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())
	var fw: FileAccess = FileAccess.open(DEVICE_TOKEN_PATH, FileAccess.WRITE)
	if fw != null:
		fw.store_string(generated)
		fw.close()
	return generated

static func save_encrypted_json(file_path: String, data: Dictionary) -> bool:
	var key: String = get_cipher_key()
	var json_str: String = JSON.stringify(data, "\t")
	var tmp_path: String = file_path + ".tmp"
	var bak_path: String = file_path + ".bak"

	# S'assurer que le dossier parent existe
	var dir_path: String = file_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)

	# 1. Écriture atomique dans un fichier temporaire
	var file: FileAccess = FileAccess.open_encrypted_with_pass(tmp_path, FileAccess.WRITE, key)
	if file == null:
		push_error("SaveCipher: Échec d'ouverture du fichier chiffré temporaire: %s (Erreur: %d)" % [tmp_path, FileAccess.get_open_error()])
		return false

	file.store_string(json_str)
	file.close()

	# 2. Backup de l'ancienne version si existante
	if FileAccess.file_exists(file_path):
		if FileAccess.file_exists(bak_path):
			DirAccess.remove_absolute(bak_path)
		DirAccess.copy_absolute(file_path, bak_path)
		DirAccess.remove_absolute(file_path)

	# 3. Remplacement final
	var rename_err: Error = DirAccess.rename_absolute(tmp_path, file_path)
	if rename_err != OK:
		# Fallback : copie simple
		DirAccess.copy_absolute(tmp_path, file_path)
		DirAccess.remove_absolute(tmp_path)

	return true

static func load_encrypted_json(file_path: String) -> Dictionary:
	var key: String = get_cipher_key()

	# 1. Tenter le fichier principal
	if FileAccess.file_exists(file_path):
		var res: Dictionary = _read_and_parse(file_path, key)
		if not res.is_empty():
			return res
		push_warning("SaveCipher: Fichier principal illisible ou corrompu: %s, tentative sur backup..." % file_path)

	# 2. Tenter le fichier de backup .bak
	var bak_path: String = file_path + ".bak"
	if FileAccess.file_exists(bak_path):
		var res_bak: Dictionary = _read_and_parse(bak_path, key)
		if not res_bak.is_empty():
			print("SaveCipher: Sauvegarde restaurée avec succès depuis %s" % bak_path)
			return res_bak

	return {}

static func _read_and_parse(path: String, key: String) -> Dictionary:
	var file: FileAccess = FileAccess.open_encrypted_with_pass(path, FileAccess.READ, key)
	if file == null:
		return {}

	var text: String = file.get_as_text()
	file.close()

	if text.strip_edges().is_empty():
		return {}

	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed as Dictionary

	return {}
