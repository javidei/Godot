extends "res://scripts/version_070_save_slots_patch.gd"


func _make_slot_card(summary: Dictionary) -> PanelContainer:
	var card := super(summary)
	if card == null or not bool(summary.get("occupied", false)):
		return card
	var day_id := int(summary.get("current_day", 0))
	var day_title := str(summary.get("day_title", ""))
	var objective_done := int(summary.get("day_objectives_completed", 0))
	var objective_total := int(summary.get("day_objectives_total", 0))
	for node in card.find_children("*", "Label", true, false):
		if node is not Label:
			continue
		var label := node as Label
		if label.text.contains(" personajes · "):
			label.text = "Día %d%s · %d/%d objetivos · %s · %d MONEDAS" % [
				day_id,
				(" · " + day_title) if not day_title.is_empty() else "",
				objective_done,
				objective_total,
				_format_duration(float(summary.get("play_seconds", 0.0))),
				int(summary.get("coins", 0))
			]
			break
	return card
