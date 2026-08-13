extends Node
class_name ProgressManager

signal coins_changed(balance, delta)
signal reward_claimed(reward_id, amount)
signal profile_changed(profile)
signal statistics_changed(statistics)
signal achievement_unlocked(achievement)

const DEFAULT_IDLE_TIMEOUT := 300.0
const DEFAULT_FLUSH_INTERVAL := 30.0

var main: Control
var data_manager: Node
var _has_focus := true
var _idle_seconds := 0.0
var _pending_play_seconds := 0.0
var _flush_seconds := 0.0
var _idle_timeout := DEFAULT_IDLE_TIMEOUT
var _flush_interval := DEFAULT_FLUSH_INTERVAL
var _ready_complete := false
var _notification_host: CenterContainer
var _notification_panel: PanelContainer
var _notification_label: Label
var _notification_queue: Array[String] = []
var _notification_busy := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	main = get_parent() as Control
	data_manager = get_node_or_null("/root/DataManager")
	if data_manager == null:
		push_error("ProgressManager: DataManager is not available")
		return
	data_manager.call("ensure_loaded")
	var economy: Dictionary = data_manager.call("get_economy_config")
	var activity: Variant = economy.get("activity", {})
	if typeof(activity) == TYPE_DICTIONARY:
		_idle_timeout = maxf(30.0, float((activity as Dictionary).get("idle_timeout_seconds", DEFAULT_IDLE_TIMEOUT)))
		_flush_interval = maxf(5.0, float((activity as Dictionary).get("profile_flush_seconds", DEFAULT_FLUSH_INTERVAL)))
	_build_notification_overlay()
	get_viewport().size_changed.connect(_resize_notification)
	_register_session()
	_ready_complete = true


func _process(delta: float) -> void:
	if not _ready_complete:
		return
	var safe_delta := clampf(delta, 0.0, 1.0)
	_idle_seconds += safe_delta
	if _has_focus and not get_tree().paused and _idle_seconds <= _idle_timeout:
		_pending_play_seconds += safe_delta
	_flush_seconds += safe_delta
	if _flush_seconds >= _flush_interval:
		flush_active_time()


func _input(event: InputEvent) -> void:
	if event == null:
		return
	if event is InputEventMouseMotion:
		if (event as InputEventMouseMotion).relative.is_zero_approx():
			return
	elif event is InputEventKey and not (event as InputEventKey).pressed:
		return
	elif event is InputEventMouseButton and not (event as InputEventMouseButton).pressed:
		return
	elif event is InputEventScreenTouch and not (event as InputEventScreenTouch).pressed:
		return
	elif event is InputEventJoypadButton and not (event as InputEventJoypadButton).pressed:
		return
	_idle_seconds = 0.0


func _notification(what: int) -> void:
	if not _ready_complete:
		return
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			_has_focus = false
			flush_active_time()
		NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_APPLICATION_RESUMED:
			_has_focus = true
			_idle_seconds = 0.0


func _exit_tree() -> void:
	if _ready_complete:
		flush_active_time()


func get_profile() -> Dictionary:
	if data_manager == null:
		return {}
	return data_manager.call("get_profile") as Dictionary


func get_statistics() -> Dictionary:
	var profile := get_profile()
	var raw: Variant = profile.get("statistics", {})
	return (raw as Dictionary).duplicate(true) if typeof(raw) == TYPE_DICTIONARY else {}


func get_coins(state: Dictionary = {}) -> int:
	var game_state := _resolve_state(state)
	return maxi(0, int(game_state.get("coins", 0))) if not game_state.is_empty() else 0


func record_event(event_type: String, context: Dictionary = {}, state: Dictionary = {}) -> Dictionary:
	if data_manager == null or event_type.strip_edges().is_empty():
		return {"success": false, "reason": "invalid_event", "rewards": [], "achievements": []}
	var game_state := _resolve_state(state)
	if not game_state.is_empty():
		_migrate_state_in_place(game_state)

	var profile := get_profile()
	var statistics: Dictionary = profile.get("statistics", {})
	var statistics_changed_value := _apply_statistics_event(event_type, context, game_state, statistics)
	if statistics_changed_value:
		profile["statistics"] = statistics
		if not bool(data_manager.call("save_profile", profile)):
			return {"success": false, "reason": "profile_save_failed", "rewards": [], "achievements": []}
		statistics_changed.emit(statistics.duplicate(true))
		profile_changed.emit(profile.duplicate(true))

	var rewards: Array = []
	if not game_state.is_empty():
		var rules: Array = data_manager.call("get_reward_rules", event_type)
		for raw_rule in rules:
			if typeof(raw_rule) != TYPE_DICTIONARY:
				continue
			var rule := raw_rule as Dictionary
			if not bool(rule.get("enabled", true)) or not _context_satisfies_rule(context, rule):
				continue
			var reward_id := _format_template(str(rule.get("id_template", rule.get("id", ""))), context)
			if reward_id.is_empty() or reward_id.contains("{"):
				continue
			var reward_result := _award_rule(reward_id, rule, game_state, false)
			if bool(reward_result.get("success", false)):
				rewards.append(reward_result)

	if not game_state.is_empty():
		data_manager.call("save_game", game_state)
	var unlocked := evaluate_achievements()
	return {
		"success": true,
		"event": event_type,
		"rewards": rewards,
		"achievements": unlocked,
		"coins": get_coins(game_state)
	}


# Compatible con award_reward(id, state) y award_reward(id, reward_type, state).
func award_reward(reward_id: String, reward_type_or_state: Variant = "", maybe_state: Dictionary = {}) -> Dictionary:
	var reward_type := ""
	var supplied_state := maybe_state
	if typeof(reward_type_or_state) == TYPE_DICTIONARY:
		supplied_state = reward_type_or_state as Dictionary
	else:
		reward_type = str(reward_type_or_state)
	var game_state := _resolve_state(supplied_state)
	if game_state.is_empty():
		return {"success": false, "reason": "no_game_state", "message": "No hay una partida activa."}
	_migrate_state_in_place(game_state)
	var rule := _find_reward_rule(reward_id, reward_type)
	if rule.is_empty():
		return {"success": false, "reason": "unknown_reward", "message": "La recompensa no existe."}
	var result := _award_rule(reward_id, rule, game_state, true)
	if bool(result.get("success", false)):
		result["achievements"] = evaluate_achievements()
	return result


func purchase(item_id: String, state: Dictionary) -> Dictionary:
	if data_manager == null:
		return {"success": false, "reason": "data_unavailable", "message": "Los datos no están disponibles."}
	var item: Dictionary = data_manager.call("get_shop_item", item_id)
	if item.is_empty():
		return {"success": false, "reason": "unknown_item", "message": "Ese artículo no existe."}
	if not bool(item.get("enabled", true)):
		return {"success": false, "reason": "disabled", "message": "Ese artículo no está disponible."}
	var category := str(item.get("category", ""))
	if is_item_unlocked(item_id, category):
		return {"success": false, "reason": "already_unlocked", "message": "Ya está comprado / desbloqueado.", "item": item}
	var game_state := _resolve_state(state)
	if game_state.is_empty():
		return {"success": false, "reason": "no_game_state", "message": "No hay una partida activa."}
	_migrate_state_in_place(game_state)
	var price := maxi(0, int(item.get("price", 0)))
	var old_balance := get_coins(game_state)
	if old_balance < price:
		return {"success": false, "reason": "insufficient_coins", "message": "No tienes suficientes MONEDAS.", "coins": old_balance, "item": item}

	var old_profile := get_profile()
	var profile := old_profile.duplicate(true)
	var unlock_key := "unlocked_cosmetics" if category == "cosmetic" else "unlocked_collectibles"
	var unlocks: Array = profile.get(unlock_key, [])
	if not unlocks.has(item_id):
		unlocks.append(item_id)
	profile[unlock_key] = unlocks
	var statistics: Dictionary = profile.get("statistics", {})
	statistics["coins_spent"] = maxi(0, int(statistics.get("coins_spent", 0))) + price
	profile["statistics"] = statistics
	game_state["coins"] = old_balance - price

	if not bool(data_manager.call("save_profile", profile)):
		game_state["coins"] = old_balance
		return {"success": false, "reason": "profile_save_failed", "message": "No se ha podido guardar el desbloqueo."}
	if not bool(data_manager.call("save_game", game_state)):
		game_state["coins"] = old_balance
		data_manager.call("save_profile", old_profile)
		return {"success": false, "reason": "save_failed", "message": "No se ha podido guardar la compra."}

	coins_changed.emit(int(game_state["coins"]), -price)
	statistics_changed.emit(statistics.duplicate(true))
	profile_changed.emit(profile.duplicate(true))
	_show_toast("%s desbloqueado" % str(item.get("name", item_id)))
	var unlocked_achievements := evaluate_achievements()
	return {
		"success": true,
		"reason": "purchased",
		"message": "Comprado / desbloqueado.",
		"item": item,
		"coins": int(game_state["coins"]),
		"achievements": unlocked_achievements
	}


func is_item_unlocked(item_id: String, category: String = "") -> bool:
	var resolved_category := category
	if resolved_category.is_empty() and data_manager != null:
		var item: Dictionary = data_manager.call("get_shop_item", item_id)
		resolved_category = str(item.get("category", ""))
	var profile := get_profile()
	var key := "unlocked_cosmetics" if resolved_category == "cosmetic" else "unlocked_collectibles"
	var unlocked: Variant = profile.get(key, [])
	return typeof(unlocked) == TYPE_ARRAY and (unlocked as Array).has(item_id)


func is_achievement_unlocked(achievement_id: String) -> bool:
	var profile := get_profile()
	var unlocked: Variant = profile.get("unlocked_achievements", {})
	return typeof(unlocked) == TYPE_DICTIONARY and (unlocked as Dictionary).has(achievement_id)


func evaluate_achievements() -> Array:
	var newly_unlocked: Array = []
	if data_manager == null:
		return newly_unlocked
	var profile := get_profile()
	var unlocked: Dictionary = profile.get("unlocked_achievements", {})
	var changed := false
	var achievements: Array = data_manager.call("get_achievements", true)
	for raw_achievement in achievements:
		if typeof(raw_achievement) != TYPE_DICTIONARY:
			continue
		var achievement := raw_achievement as Dictionary
		var achievement_id := str(achievement.get("id", ""))
		if achievement_id.is_empty() or unlocked.has(achievement_id):
			continue
		if not _achievement_conditions_met(achievement, profile):
			continue
		unlocked[achievement_id] = {"unlocked_at_unix": int(Time.get_unix_time_from_system())}
		newly_unlocked.append(achievement.duplicate(true))
		changed = true
	if not changed:
		return newly_unlocked
	profile["unlocked_achievements"] = unlocked
	if not bool(data_manager.call("save_profile", profile)):
		return []
	profile_changed.emit(profile.duplicate(true))
	for achievement in newly_unlocked:
		achievement_unlocked.emit(achievement)
		_show_toast("Logro desbloqueado: " + str(achievement.get("name", achievement.get("id", ""))))
	return newly_unlocked


func get_achievement_progress(achievement_id: String) -> Dictionary:
	if data_manager == null:
		return {}
	var achievement: Dictionary = data_manager.call("get_achievement", achievement_id)
	if achievement.is_empty():
		return {}
	var conditions: Variant = achievement.get("conditions", [])
	if typeof(conditions) != TYPE_ARRAY or (conditions as Array).is_empty():
		return {"unlocked": is_achievement_unlocked(achievement_id), "ratio": 0.0}
	var condition: Variant = (conditions as Array)[0]
	if typeof(condition) != TYPE_DICTIONARY:
		return {}
	var rule := condition as Dictionary
	var profile := get_profile()
	var current: Variant = _metric_value(str(rule.get("metric", "")), profile)
	var target: Variant = rule.get("value", 0)
	var current_number := float((current as Array).size()) if typeof(current) == TYPE_ARRAY else float(current)
	var target_number := float(target)
	return {
		"unlocked": is_achievement_unlocked(achievement_id),
		"current": current_number,
		"target": target_number,
		"ratio": clampf(current_number / target_number, 0.0, 1.0) if target_number > 0.0 else 0.0
	}


func flush_active_time() -> bool:
	_flush_seconds = 0.0
	if data_manager == null or _pending_play_seconds <= 0.001:
		return true
	var seconds_to_save := _pending_play_seconds
	var profile := get_profile()
	var statistics: Dictionary = profile.get("statistics", {})
	statistics["total_play_seconds"] = maxf(0.0, float(statistics.get("total_play_seconds", 0.0))) + seconds_to_save
	profile["statistics"] = statistics
	if not bool(data_manager.call("save_profile", profile)):
		return false
	_pending_play_seconds = maxf(0.0, _pending_play_seconds - seconds_to_save)
	statistics_changed.emit(statistics.duplicate(true))
	profile_changed.emit(profile.duplicate(true))
	evaluate_achievements()
	return true


func _register_session() -> void:
	var profile := get_profile()
	var statistics: Dictionary = profile.get("statistics", {})
	statistics["total_sessions"] = maxi(0, int(statistics.get("total_sessions", 0))) + 1
	var platforms: Dictionary = statistics.get("platforms", {})
	var platform_name := OS.get_name()
	platforms[platform_name] = maxi(0, int(platforms.get(platform_name, 0))) + 1
	statistics["platforms"] = platforms
	statistics["touch_capable_seen"] = bool(statistics.get("touch_capable_seen", false)) or DisplayServer.is_touchscreen_available()
	profile["statistics"] = statistics
	if bool(data_manager.call("save_profile", profile)):
		statistics_changed.emit(statistics.duplicate(true))
		profile_changed.emit(profile.duplicate(true))
		evaluate_achievements()


func _build_notification_overlay() -> void:
	if main == null or _notification_host != null:
		return
	_notification_host = CenterContainer.new()
	_notification_host.name = "ProgressNotificationHost"
	_notification_host.anchor_left = 0.0
	_notification_host.anchor_top = 0.0
	_notification_host.anchor_right = 1.0
	_notification_host.anchor_bottom = 0.0
	_notification_host.offset_top = 20.0
	_notification_host.offset_bottom = 120.0
	_notification_host.z_index = 1200
	_notification_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Al ser hijo directo de este manager no compite con el montaje inicial de
	# hijos de Main. Sin un Control intermedio, los anchors se resuelven contra
	# el viewport y el z_index sigue situándolo sobre el mapa.
	add_child(_notification_host)

	_notification_panel = PanelContainer.new()
	_notification_panel.name = "ProgressNotification"
	_notification_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notification_panel.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.025, 0.02, 0.97)
	style.border_color = Color("e0b25d")
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 18.0
	style.content_margin_top = 12.0
	style.content_margin_right = 18.0
	style.content_margin_bottom = 12.0
	_notification_panel.add_theme_stylebox_override("panel", style)
	_notification_host.add_child(_notification_panel)

	_notification_label = Label.new()
	_notification_label.name = "ProgressNotificationLabel"
	_notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notification_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_notification_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notification_label.add_theme_color_override("font_color", Color("fff2dd"))
	_notification_label.add_theme_font_size_override("font_size", 18)
	_notification_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notification_panel.add_child(_notification_label)
	_resize_notification()


func _resize_notification() -> void:
	if _notification_panel == null:
		return
	var viewport_width := get_viewport().get_visible_rect().size.x
	_notification_panel.custom_minimum_size = Vector2(clampf(viewport_width * 0.72, 280.0, 620.0), 62.0)
	if _notification_label != null:
		_notification_label.add_theme_font_size_override("font_size", 16 if viewport_width < 720.0 else 18)


func _drain_notifications() -> void:
	if _notification_busy or _notification_panel == null:
		return
	_notification_busy = true
	while not _notification_queue.is_empty() and is_instance_valid(_notification_panel):
		var message := str(_notification_queue.pop_front())
		_notification_label.text = message
		_notification_panel.modulate.a = 0.0
		_notification_panel.visible = true
		var reveal := create_tween()
		reveal.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		reveal.tween_property(_notification_panel, "modulate:a", 1.0, 0.16)
		await reveal.finished
		await get_tree().create_timer(2.15, true, false, true).timeout
		var hide := create_tween()
		hide.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		hide.tween_property(_notification_panel, "modulate:a", 0.0, 0.28)
		await hide.finished
		_notification_panel.visible = false
	_notification_busy = false


func _apply_statistics_event(event_type: String, context: Dictionary, state: Dictionary, statistics: Dictionary) -> bool:
	match event_type:
		"new_game_started":
			var protagonist_id := _context_id(context, ["protagonist_id", "player_id", "character_id"])
			if protagonist_id.is_empty() and not state.is_empty():
				var player: Variant = state.get("player", {})
				if typeof(player) == TYPE_DICTIONARY:
					protagonist_id = str((player as Dictionary).get("id", ""))
			if protagonist_id.is_empty():
				return false
			_increment_counter(statistics, "protagonist_games", protagonist_id)
		"conversation_started":
			statistics["conversations"] = maxi(0, int(statistics.get("conversations", 0))) + 1
		"decision_taken", "decision_made", "decision":
			statistics["decisions"] = maxi(0, int(statistics.get("decisions", 0))) + 1
		"character_visited":
			var character_id := _context_id(context, ["character_id", "id"])
			if character_id.is_empty():
				return false
			_increment_counter(statistics, "character_visits", character_id)
		"location_visited":
			var location_id := _context_id(context, ["location_id", "zone_id", "id"])
			if location_id.is_empty():
				return false
			_increment_counter(statistics, "location_visits", location_id)
		"scene_discovered":
			return _append_unique_stat(statistics, "unique_scenes", _context_id(context, ["scene_id", "id"]))
		"special_event":
			return _append_unique_stat(statistics, "unique_events", _context_id(context, ["event_id", "id"]))
		_:
			return false
	return true


func _award_rule(reward_id: String, rule: Dictionary, state: Dictionary, save_now: bool) -> Dictionary:
	var claimed: Dictionary = state.get("claimed_rewards", {})
	var unique := bool(rule.get("unique", true))
	if unique and claimed.has(reward_id):
		return {"success": false, "reason": "already_claimed", "message": "Esta recompensa ya fue cobrada.", "reward_id": reward_id, "coins": get_coins(state)}
	var amount := int(rule.get("amount", 0))
	if rule.has("amount_min") or rule.has("amount_max"):
		var minimum := int(rule.get("amount_min", amount))
		var maximum := maxi(minimum, int(rule.get("amount_max", minimum)))
		amount = randi_range(minimum, maximum)
	if amount <= 0:
		return {"success": false, "reason": "invalid_amount", "message": "La recompensa no tiene un importe válido."}
	var old_balance := get_coins(state)
	state["coins"] = old_balance + amount
	if unique:
		claimed[reward_id] = {"amount": amount, "claimed_at_unix": int(Time.get_unix_time_from_system())}
		state["claimed_rewards"] = claimed

	var profile := get_profile()
	var statistics: Dictionary = profile.get("statistics", {})
	statistics["coins_earned"] = maxi(0, int(statistics.get("coins_earned", 0))) + amount
	profile["statistics"] = statistics
	if not bool(data_manager.call("save_profile", profile)):
		state["coins"] = old_balance
		if unique:
			claimed.erase(reward_id)
		return {"success": false, "reason": "profile_save_failed", "message": "No se ha podido guardar la recompensa."}
	if save_now and not bool(data_manager.call("save_game", state)):
		state["coins"] = old_balance
		if unique:
			claimed.erase(reward_id)
		statistics["coins_earned"] = maxi(0, int(statistics.get("coins_earned", 0)))
		statistics["coins_earned"] = maxi(0, int(statistics["coins_earned"]) - amount)
		profile["statistics"] = statistics
		data_manager.call("save_profile", profile)
		return {"success": false, "reason": "save_failed", "message": "No se ha podido guardar la recompensa."}

	coins_changed.emit(int(state["coins"]), amount)
	reward_claimed.emit(reward_id, amount)
	statistics_changed.emit(statistics.duplicate(true))
	profile_changed.emit(profile.duplicate(true))
	_show_toast("+%d MONEDAS" % amount)
	return {"success": true, "reason": "rewarded", "message": "+%d MONEDAS" % amount, "reward_id": reward_id, "amount": amount, "coins": int(state["coins"])}


func _find_reward_rule(reward_id: String, reward_type: String) -> Dictionary:
	var rules: Array = data_manager.call("get_reward_rules", "") if data_manager != null else []
	var requested_type := reward_type
	if requested_type.is_empty():
		if reward_id.begins_with("first_visit_"):
			requested_type = "first_visit"
		elif reward_id.begins_with("scene_"):
			requested_type = "scene_discovery"
		elif reward_id.begins_with("event_"):
			requested_type = "special_event"
		elif reward_id.begins_with("hidden_"):
			requested_type = "hidden_collectible"
		elif reward_id.begins_with("activity_"):
			requested_type = "repeatable_activity"
	for raw_rule in rules:
		if typeof(raw_rule) != TYPE_DICTIONARY:
			continue
		var rule := raw_rule as Dictionary
		if str(rule.get("id", "")) == requested_type or str(rule.get("id", "")) == reward_id:
			return rule.duplicate(true)
	return {}


func _achievement_conditions_met(achievement: Dictionary, profile: Dictionary) -> bool:
	var conditions: Variant = achievement.get("conditions", [])
	if typeof(conditions) != TYPE_ARRAY or (conditions as Array).is_empty():
		return false
	for raw_condition in conditions as Array:
		if typeof(raw_condition) != TYPE_DICTIONARY:
			return false
		var condition := raw_condition as Dictionary
		var current: Variant = _metric_value(str(condition.get("metric", "")), profile)
		if not _compare_metric(current, str(condition.get("operator", "gte")), condition.get("value", 0)):
			return false
	return true


func _metric_value(metric: String, profile: Dictionary) -> Variant:
	var statistics: Dictionary = profile.get("statistics", {})
	match metric:
		"total_character_visits":
			return _sum_dictionary(statistics.get("character_visits", {}))
		"characters_visited_unique":
			return _positive_key_count(statistics.get("character_visits", {}))
		"locations_visited_unique":
			return _positive_key_count(statistics.get("location_visits", {}))
		"scenes_discovered_unique":
			var scenes: Variant = statistics.get("unique_scenes", [])
			return (scenes as Array).size() if typeof(scenes) == TYPE_ARRAY else 0
		"unlocked_items_total":
			return _array_size(profile.get("unlocked_collectibles", [])) + _array_size(profile.get("unlocked_cosmetics", []))
		"unlocked_collectibles", "unlocked_cosmetics":
			return profile.get(metric, [])
		_:
			return _get_nested_value(statistics, metric)


func _compare_metric(current: Variant, operator: String, target: Variant) -> bool:
	match operator:
		"gte":
			return float(current) >= float(target)
		"lte":
			return float(current) <= float(target)
		"gt":
			return float(current) > float(target)
		"lt":
			return float(current) < float(target)
		"eq":
			return current == target
		"neq":
			return current != target
		"count_gte":
			return _collection_size(current) >= int(target)
		"contains":
			return _collection_has(current, target)
		"contains_all":
			if typeof(target) != TYPE_ARRAY:
				return false
			for item in target as Array:
				if not _collection_has(current, item):
					return false
			return true
		_:
			return false


func _context_satisfies_rule(context: Dictionary, rule: Dictionary) -> bool:
	var required: Variant = rule.get("required_context", [])
	if typeof(required) == TYPE_ARRAY:
		for raw_key in required as Array:
			var key := str(raw_key)
			if not context.has(key) or str(context.get(key, "")).strip_edges().is_empty():
				return false
	var match_values: Variant = rule.get("context_equals", {})
	if typeof(match_values) == TYPE_DICTIONARY:
		for raw_key in (match_values as Dictionary).keys():
			if context.get(raw_key) != (match_values as Dictionary)[raw_key]:
				return false
	return true


func _format_template(template: String, context: Dictionary) -> String:
	var result := template
	for raw_key in context.keys():
		result = result.replace("{%s}" % str(raw_key), str(context[raw_key]))
	return result


func _migrate_state_in_place(state: Dictionary) -> void:
	var migrated: Dictionary = data_manager.call("migrate_save_state", state)
	state.clear()
	state.merge(migrated, true)


func _resolve_state(state: Dictionary) -> Dictionary:
	if not state.is_empty():
		return state
	if main != null and main.has_method("_save_game"):
		var candidate: Variant = main.get("state")
		if typeof(candidate) == TYPE_DICTIONARY:
			return candidate as Dictionary
	return state


func _context_id(context: Dictionary, keys: Array) -> String:
	for raw_key in keys:
		var value := str(context.get(raw_key, "")).strip_edges()
		if not value.is_empty():
			return value
	return ""


func _increment_counter(statistics: Dictionary, dictionary_key: String, item_id: String) -> void:
	var counts: Dictionary = statistics.get(dictionary_key, {})
	counts[item_id] = maxi(0, int(counts.get(item_id, 0))) + 1
	statistics[dictionary_key] = counts


func _append_unique_stat(statistics: Dictionary, key: String, item_id: String) -> bool:
	if item_id.is_empty():
		return false
	var items: Array = statistics.get(key, [])
	if items.has(item_id):
		return false
	items.append(item_id)
	statistics[key] = items
	return true


func _sum_dictionary(value: Variant) -> int:
	if typeof(value) != TYPE_DICTIONARY:
		return 0
	var result := 0
	for item in (value as Dictionary).values():
		result += maxi(0, int(item))
	return result


func _positive_key_count(value: Variant) -> int:
	if typeof(value) != TYPE_DICTIONARY:
		return 0
	var result := 0
	for item in (value as Dictionary).values():
		if int(item) > 0:
			result += 1
	return result


func _array_size(value: Variant) -> int:
	return (value as Array).size() if typeof(value) == TYPE_ARRAY else 0


func _collection_size(value: Variant) -> int:
	if typeof(value) == TYPE_ARRAY:
		return (value as Array).size()
	if typeof(value) == TYPE_DICTIONARY:
		return (value as Dictionary).size()
	if typeof(value) == TYPE_STRING:
		return str(value).length()
	return 0


func _collection_has(value: Variant, item: Variant) -> bool:
	if typeof(value) == TYPE_ARRAY:
		return (value as Array).has(item)
	if typeof(value) == TYPE_DICTIONARY:
		return (value as Dictionary).has(item)
	if typeof(value) == TYPE_STRING:
		return str(value).contains(str(item))
	return false


func _get_nested_value(source: Dictionary, path: String) -> Variant:
	var current: Variant = source
	for part in path.split(".", false):
		if typeof(current) != TYPE_DICTIONARY:
			return 0
		current = (current as Dictionary).get(part, 0)
	return current


func _show_toast(message: String) -> void:
	var clean_message := message.strip_edges()
	if clean_message.is_empty():
		return
	_notification_queue.append(clean_message)
	if not _notification_busy:
		call_deferred("_drain_notifications")
