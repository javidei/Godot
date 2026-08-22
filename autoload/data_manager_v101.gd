extends "res://autoload/data_manager_v100.gd"


# Al terminar los 16 insultos no se consume el minijuego para siempre. La
# siguiente entrada en la habitación crea una ronda nueva con todo el pool,
# barajado otra vez. El jugador decide cuándo dejar de visitar a Javi.
func prepare_javi_insult_battle_visit(state: Dictionary) -> Dictionary:
	var battle := ensure_javi_insult_battle_state(state)
	if bool(battle.get("complete", false)):
		battle["completed"] = []
		battle["remaining"] = _javi_pool_ids_0927()
		battle["session_order"] = []
		battle["complete"] = false
		state["javi_insult_battle"] = battle
	return super(state)
