extends "res://scripts/version_095_unified_audio_visual.gd"

const DataStory098 = preload("res://scripts/story.gd")
const DataAccess098 = preload("res://scripts/data_access.gd")


func _select_visit(character_id: String) -> void:
	if character_id == "javi":
		var dm: Variant = DataAccess098.dm()
		if dm != null and dm.has_method("reroll_javi_question_for_visit"):
			dm.call("reroll_javi_question_for_visit")
			# Story se reconstruye justo antes de entrar para que esta visita use el
			# nuevo insulto, manteniendo una sola pregunta durante toda la estancia.
			DataStory098.refresh()
			_patch_story()
			var transitions := main.get_node_or_null("Version044VisitTransitions") if main != null else null
			if transitions != null and transitions.has_method("_ensure_story_patches"):
				transitions.call("_ensure_story_patches")
	super(character_id)
