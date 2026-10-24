class_name InventoryMenu
extends CanvasLayer
## Inventaire simplifié (Tab / I, ou depuis la pause) : quatre onglets alimentés par
## les données réelles du jeu (GameState, catalogues), sans liste parallèle.
## - Ressources : filament structurel, plastique à projectiles.
## - Équipement : améliorations majeures, modules (2 emplacements), échange hors combat.
## - Archives : souvenirs retrouvés n/7, fragments, commentaires de Nin0 (historique).
## - Bestiaire : espèces analysées.
## - Trophées (lot 7) : trophées internes débloqués (les secrets restent masqués).

signal closed

const TABS := ["Ressources", "Équipement", "Archives", "Bestiaire", "Trophées"]

var allowed := true
var is_open := false
var _tabs: TabContainer
var _pages: Array[VBoxContainer] = []
var _paused_before := false


func _init() -> void:
	layer = 8
	process_mode = Node.PROCESS_MODE_ALWAYS
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.05, 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := UiKit.panel()
	panel.custom_minimum_size = Vector2(720, 500)
	center.add_child(panel)
	var box := UiKit.vbox(UiKit.margin(panel, 20), 10)
	var head := UiKit.hbox(box, 10)
	UiKit.label(head, "INVENTAIRE — NIN0", 22, UiKit.TITLE_COLOR)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)
	UiKit.label(head, "Q / D : onglet    ·    Échap : fermer", 13, UiKit.DIM_COLOR)
	_tabs = TabContainer.new()
	_tabs.theme = UiKit.THEME
	_tabs.custom_minimum_size = Vector2(680, 420)
	box.add_child(_tabs)
	for title in TABS:
		var scroll := ScrollContainer.new()
		scroll.name = title
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_tabs.add_child(scroll)
		var page := VBoxContainer.new()
		page.add_theme_constant_override("separation", 10)
		page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(page)
		_pages.append(page)
	visible = false


func open(tab := -1) -> void:
	if is_open:
		return
	is_open = true
	if tab >= 0:
		_tabs.current_tab = tab
	refresh()
	visible = true
	_paused_before = get_tree().paused
	get_tree().paused = true
	GameState.modal_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Sfx.play(&"blip", -8.0)


func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	get_tree().paused = _paused_before
	GameState.modal_open = _paused_before
	if not _paused_before:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if is_open:
		if event.is_action_pressed("pause") or event.is_action_pressed("inventory"):
			close()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("move_left"):
			_tabs.current_tab = wrapi(_tabs.current_tab - 1, 0, TABS.size())
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("move_right"):
			_tabs.current_tab = wrapi(_tabs.current_tab + 1, 0, TABS.size())
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory") and allowed and not GameState.modal_open and not get_tree().paused:
		open()
		get_viewport().set_input_as_handled()


func refresh() -> void:
	for page in _pages:
		for child in page.get_children():
			child.queue_free()
	_fill_resources(_pages[0])
	_fill_equipment(_pages[1])
	_fill_archives(_pages[2])
	_fill_bestiary(_pages[3])
	_fill_trophies(_pages[4])


# --- Trophées -------------------------------------------------------------------------

func _fill_trophies(page: VBoxContainer) -> void:
	UiKit.label(page, "Trophées : %d / %d" % [Achievements.unlocked_count(), Achievements.LIST.size()], 17, UiKit.TITLE_COLOR)
	var titles := {Achievements.PROGRESSION: "PROGRESSION", Achievements.DISCOVERY: "DÉCOUVERTE",
			Achievements.COOPERATION: "COOPÉRATION", Achievements.SECRET: "SECRETS"}
	for category in titles:
		UiKit.label(page, titles[category], 13, UiKit.SCAN_COLOR)
		for id in Achievements.LIST:
			var data: Array = Achievements.LIST[id]
			if data[2] != category:
				continue
			var done := Achievements.is_unlocked(id)
			var row := UiKit.hbox(page, 12)
			UiKit.icon(row, &"check" if done else (&"question" if category == Achievements.SECRET else &"lock"), 34)
			var col := UiKit.vbox(row, 1)
			col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var hidden: bool = category == Achievements.SECRET and not done
			UiKit.label(col, "Trophée secret" if hidden else data[0], 16, UiKit.TITLE_COLOR if done else UiKit.DIM_COLOR)
			UiKit.label(col, "???" if hidden else data[1], 13, Color.WHITE if done else Color(0.6, 0.62, 0.66), true)


# --- Ressources -----------------------------------------------------------------------

func _fill_resources(page: VBoxContainer) -> void:
	var filament_known := GameState.seen_notices.has(&"resource_filament") or GameState.fragments > 0 or not GameState.collected_pickups.is_empty()
	_resource_row(page, &"filament", "Filament structurel", "%d" % GameState.fragments,
			"Matériau de réparation et de fabrication (réparations, renforts, modules).", filament_known)
	var plastic_known := GameState.seen_notices.has(&"resource_plastic") or GameState.has_cannon()
	_resource_row(page, &"plastic", "Plastique à projectiles", "%d / %d" % [GameState.ammo_plastic, GameState.PLASTIC_MAX],
			"Permet de fabriquer les munitions du canon (une bille par tir).", plastic_known)


func _resource_row(page: Control, icon: StringName, title: String, amount: String, text: String, known: bool) -> void:
	var row := UiKit.hbox(page, 14)
	UiKit.icon(row, icon if known else &"question", 46)
	var col := UiKit.vbox(row, 2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiKit.label(col, title if known else "Ressource inconnue", 18, UiKit.TITLE_COLOR)
	UiKit.label(col, text if known else "Pas encore trouvée.", 14, UiKit.DIM_COLOR, true)
	if known:
		UiKit.label(row, amount, 22)


# --- Équipement -----------------------------------------------------------------------

func _fill_equipment(page: VBoxContainer) -> void:
	UiKit.label(page, "AMÉLIORATIONS MAJEURES (permanentes)", 13, UiKit.SCAN_COLOR)
	var any := false
	for upgrade in UpgradeCatalog.all():
		if upgrade.category == UpgradeData.Category.MODULE:
			continue
		var owned := GameState.has_upgrade(upgrade.id) or (upgrade.id == &"legs" and GameState.legs_installed)
		if owned:
			any = true
			_upgrade_row(page, upgrade, "Installé" if upgrade.category == UpgradeData.Category.MAJOR else "Niveau %d · actif" % upgrade.tier)
		elif GameState.has_discovery(upgrade.required_discovery):
			any = true
			_upgrade_row(page, upgrade, "Plan connu · à fabriquer à l'imprimante", true)
	if not any:
		UiKit.label(page, "Aucune.", 14, UiKit.DIM_COLOR)
	UiKit.label(page, "MODULES — emplacements %d / %d (échange hors combat)" % [GameState.equipped_modules.size(), GameState.module_slots], 13, UiKit.SCAN_COLOR)
	var modules := 0
	for upgrade in UpgradeCatalog.all():
		if upgrade.category != UpgradeData.Category.MODULE:
			continue
		if GameState.has_upgrade(upgrade.id):
			modules += 1
			var equipped := GameState.is_equipped(upgrade.id)
			var row := _upgrade_row(page, upgrade, "Équipé" if equipped else "Fabriqué · non équipé")
			var toggle := UiKit.button(row, "Retirer" if equipped else "Équiper")
			toggle.disabled = GameState.in_combat or (not equipped and GameState.equipped_modules.size() >= GameState.module_slots)
			toggle.tooltip_text = "Impossible en combat" if GameState.in_combat else ""
			var id := upgrade.id
			toggle.pressed.connect(func() -> void:
				if GameState.is_equipped(id):
					GameState.unequip_module(id)
				else:
					GameState.equip_module(id)
				refresh())
		elif GameState.has_discovery(upgrade.required_discovery):
			modules += 1
			_upgrade_row(page, upgrade, "Plan connu · à fabriquer à l'imprimante", true)
	if modules == 0:
		UiKit.label(page, "Aucun module.", 14, UiKit.DIM_COLOR)
	if GameState.in_combat:
		UiKit.label(page, "En combat : les modules ne peuvent pas être échangés.", 14, Color(1, 0.6, 0.45))


func _upgrade_row(page: Control, upgrade: UpgradeData, state: String, dim := false) -> HBoxContainer:
	var row := UiKit.hbox(page, 12)
	var col := UiKit.vbox(row, 1)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var kind: String = ["Majeure", "Module", "Évolution"][upgrade.category]
	UiKit.label(col, "%s  ·  %s" % [upgrade.title, kind], 17, UiKit.DIM_COLOR if dim else UiKit.TITLE_COLOR)
	var effect := upgrade.effect_text if upgrade.effect_text != "" else upgrade.description
	UiKit.label(col, effect, 14, Color.WHITE, true)
	UiKit.label(col, state, 13, UiKit.SCAN_COLOR)
	return row


# --- Archives -------------------------------------------------------------------------

func _fill_archives(page: VBoxContainer) -> void:
	var archive := GameState.ARCHIVE
	UiKit.label(page, "Souvenirs retrouvés : %d / %d" % [GameState.memory_count(), archive.total], 17, UiKit.TITLE_COLOR)
	var by_slot := {}
	for id in GameState.memories:
		var memory := archive.get_entry(id)
		if memory:
			by_slot[memory.slot] = memory
	for slot in range(1, archive.total + 1):
		var box := UiKit.vbox(page, 2)
		if not by_slot.has(slot):
			UiKit.label(box, "N° %02d — signal non identifié" % slot, 15, Color(0.55, 0.58, 0.62))
			continue
		var memory: MemoryData = by_slot[slot]
		UiKit.label(box, "N° %02d — %s" % [slot, memory.title], 17, UiKit.TITLE_COLOR)
		if memory.object_name != "":
			UiKit.label(box, "Objet associé : %s" % memory.object_name, 14, UiKit.DIM_COLOR)
		var history: Array = GameState.memory_reads.get(memory.id, [])
		var current := PauseMenu.archives_line(memory)
		UiKit.label(box, "Informations récupérées :", 12, UiKit.SCAN_COLOR)
		UiKit.label(box, current, 14, Color.WHITE, true).custom_minimum_size.x = 620.0
		UiKit.label(box, "Interprétation de Nin0 :", 12, UiKit.SCAN_COLOR)
		if history.is_empty():
			UiKit.label(box, "« %s »" % memory.comment, 14, Color(0.85, 0.95, 1.0), true)
		for entry in history:
			UiKit.label(box, "« %s »  (lecture à %d/%d)" % [entry.get("comment", memory.comment), int(entry.get("found", 1)), archive.total], 14, Color(0.85, 0.95, 1.0), true)
		UiKit.label(box, "Inconnu : origine, date, auteur.", 13, Color(0.6, 0.62, 0.66))


# --- Bestiaire ------------------------------------------------------------------------

func _fill_bestiary(page: VBoxContainer) -> void:
	var known := 0
	for data in SpeciesCatalog.all():
		var row := UiKit.hbox(page, 14)
		if not GameState.has_species(data.id):
			UiKit.icon(row, &"question", 46)
			UiKit.label(row, "Espèce non analysée", 16, Color(0.55, 0.58, 0.62))
			continue
		known += 1
		UiKit.icon(row, data.icon, 56)
		var col := UiKit.vbox(row, 2)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UiKit.label(col, data.display_name, 18, UiKit.TITLE_COLOR)
		UiKit.label(col, "%s  ·  %s" % [data.classification, data.behavior], 13, UiKit.SCAN_COLOR)
		UiKit.label(col, data.description, 14, Color.WHITE, true)
		if not data.traits.is_empty():
			UiKit.label(col, "Particularités : " + " · ".join(data.traits), 14, UiKit.DIM_COLOR, true)
		if data.mechanical_inspiration != "":
			UiKit.label(col, "Inspiration mécanique : " + data.mechanical_inspiration, 14, Color(0.98, 0.75, 0.5), true)
	if known == 0:
		UiKit.label(page, "Aucune espèce analysée : observez les insectes avec la vision focalisée.", 14, UiKit.DIM_COLOR, true)
