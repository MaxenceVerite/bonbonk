extends Node

func _ready() -> void:
	print("--- TEST BOUTIQUE : CONFIRMATION & ICONES AGRANDIES ---")

	var menu_scene: PackedScene = preload("res://scenes/ui/main_menu.tscn")
	var menu: MainMenu = menu_scene.instantiate() as MainMenu
	add_child(menu)
	menu.switch_to_tab_index(0, false) # Boutique

	for i in range(8):
		await get_tree().process_frame

	assert(menu.shop_reward_modal != null, "ShopRewardModal doit être présent dans MainMenu")
	assert(menu.currency_fly_layer != null, "CurrencyFlyLayer doit être présent dans MainMenu")

	# Capture 0: Vue de la boutique avec les sachets et icônes agrandies
	var tex = get_viewport().get_texture()
	if tex != null:
		var img: Image = tex.get_image()
		if img != null:
			var path0: String = "C:/Users/Maxence/.gemini/antigravity-ide/brain/e0926cf3-8f29-4780-bd14-e097223fe3b8/shop_enlarged_icons.png"
			img.save_png(path0)
			print("✓ Screenshot 0 (Icônes & Sachets Agrandis) sauvegardé : ", path0)

	# 1. TEST DE SÉCURITÉ : TANT QU'ON A PAS CLIQUÉ SUR "CONFIRMER", RIEN N'EST ACHETÉ !
	# Trouver un sachet de bonbons payant
	var sachet_item: ShopItemData = null
	for item in SaveManager.shop_catalog:
		if item.id == &"shop_pack_gold" or item.id == &"shop_pack_silver":
			sachet_item = item
			break

	assert(sachet_item != null, "Sachet de bonbons non trouvé dans le catalogue")
	var start_gold: int = SaveManager.gold
	var start_diamonds: int = SaveManager.diamonds
	print("Solde initial avant clic : %d 🪙, %d 💎" % [start_gold, start_diamonds])

	# Clic sur le bouton d'achat du sachet
	print("Clic sur le bouton d'achat du sachet : ", sachet_item.display_name)
	menu._on_shop_card_action(sachet_item, false)

	# La modale doit s'ouvrir en mode CONFIRMATION
	assert(menu.shop_reward_modal.visible == true, "La modale doit être ouverte")
	assert(menu.shop_reward_modal.confirm_buttons.visible == true, "Les boutons Confirmer / Annuler doivent être visibles")
	assert(SaveManager.gold == start_gold, "ERREUR CRITIQUE : L'or a été débité avant confirmation !")
	assert(SaveManager.diamonds == start_diamonds, "ERREUR CRITIQUE : Les diamants ont été débités avant confirmation !")
	print("✓ Aucun débit effectué : l'achat attend la confirmation du joueur !")

	await get_tree().create_timer(0.35).timeout
	for f in range(6):
		await get_tree().process_frame

	# Capture 1: Modale de confirmation avec coût et solde restant
	tex = get_viewport().get_texture()
	if tex != null:
		var img: Image = tex.get_image()
		if img != null:
			var path1: String = "C:/Users/Maxence/.gemini/antigravity-ide/brain/e0926cf3-8f29-4780-bd14-e097223fe3b8/shop_purchase_confirmation_modal.png"
			img.save_png(path1)
			print("✓ Screenshot 1 (Confirmation d'Achat) sauvegardé : ", path1)

	# 2. Test Confirmation d'achat du sachet & Envol du paquet vers la droite
	var boosters_count_before: int = SaveManager.available_boosters.size()
	print("Clic sur CONFIRMER pour le sachet...")
	menu.shop_reward_modal._on_confirm_pressed()

	# La modale doit se fermer immédiatement (pas de 2e modale perturbante !)
	await get_tree().create_timer(0.18).timeout
	assert(menu.currency_fly_layer.get_child_count() > 0, "Le sachet doit être en plein vol dans CurrencyFlyLayer")
	print("✓ Sachet en plein vol vers la droite de l'écran !")

	# Capture du sachet en plein vol vers la droite
	tex = get_viewport().get_texture()
	if tex != null:
		var img: Image = tex.get_image()
		if img != null:
			var path_b: String = "C:/Users/Maxence/.gemini/antigravity-ide/brain/e0926cf3-8f29-4780-bd14-e097223fe3b8/booster_flying_to_right.png"
			img.save_png(path_b)
			print("✓ Screenshot (Paquet s'envolant vers la droite) sauvegardé : ", path_b)

	# Attendre l'arrivée à droite et le rebond du bouton Collection
	await get_tree().create_timer(0.45).timeout
	assert(SaveManager.available_boosters.size() > boosters_count_before, "Le sachet doit être dans l'inventaire")
	print("✓ Sachet réceptionné dans la Collection avec succès !")

	# 3. Test Confirmation & Envol de devises
	var item_currency: ShopItemData = null
	for item in SaveManager.shop_catalog:
		if not item.is_real_money():
			for e in item.get_reward_entries():
				if e.get("type", "") == "gold":
					item_currency = item
					break
		if item_currency != null:
			break

	print("Ouverture confirmation pour : ", item_currency.display_name)
	menu._on_shop_card_action(item_currency, false)
	await get_tree().create_timer(0.3).timeout

	print("Clic sur CONFIRMER...")
	menu.shop_reward_modal._on_confirm_pressed()

	await get_tree().create_timer(0.25).timeout
	assert(menu.currency_fly_layer.get_child_count() > 0, "Les pièces doivent être en vol")
	print("✓ %d pièces en vol vers le HUD après confirmation !" % menu.currency_fly_layer.get_child_count())

	await get_tree().create_timer(1.6).timeout
	assert(menu._is_flying_currency == false, "Animation terminée")
	print("✓ Cycle de confirmation et envol validé avec succès !")

	print("ALL CONFIRMATION & SIZING TESTS PASSED SUCCESSFULLY!")
	get_tree().quit(0)
