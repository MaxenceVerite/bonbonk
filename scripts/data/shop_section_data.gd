class_name ShopSectionData
extends Resource

## Décrit une section (rayon) de la boutique : son ruban, les articles qu'elle
## affiche (par catégorie) et la façon de les présenter.

const ShopItemDataScript = preload("res://scripts/data/shop_item_data.gd")

enum Layout {
	FEATURED_GALLERY, # Galerie mise en avant : cartes dorées à image de fond, tailles variables
	REWARD_ROWS,      # Cartes horizontales : image à gauche, titre, récompense, bouton
	ITEM_TILES        # Tuiles verticales classiques : icône, nom, boutons de prix
}

@export var id: StringName = &"section"
@export var title: String = "SECTION"
@export var category: ShopItemData.Category = ShopItemData.Category.BOOSTERS
@export var layout: Layout = Layout.ITEM_TILES
@export_range(1, 4) var columns: int = 2
## Masque complètement la section (ruban compris) si aucun article ne correspond.
@export var hide_when_empty: bool = true

static func create(p_id: StringName, p_title: String, p_category: ShopItemData.Category, p_layout: Layout, p_columns: int = 2) -> ShopSectionData:
	var s: ShopSectionData = (load("res://scripts/data/shop_section_data.gd") as GDScript).new()
	s.id = p_id
	s.title = p_title
	s.category = p_category
	s.layout = p_layout
	s.columns = p_columns
	return s
