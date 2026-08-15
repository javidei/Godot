extends Node

# 0.8.3: la experiencia parte de pantalla completa siempre que la plataforma lo
# permita. Los navegadores exigen que requestFullscreen() nazca de un gesto del
# usuario, así que en Web se arma una petición para el primer clic/toque/tecla.
const DEFAULT_FULLSCREEN := true

var main: Control
var audio_manager: Node
var version_manager: Node
var _web_fullscreen_armed := false


func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	main = get_parent() as Control
	if main == null:
		return
	audio_manager = main.get("audio_manager") as Node
	version_manager = main.get_node_or_null("Version040Manager")
	_apply_default_fullscreen()


func _process(_delta: float) -> void:
	_enforce_room_mute()


func _apply_default_fullscreen() -> void:
	if not DEFAULT_FULLSCREEN:
		return
	if OS.has_feature("web"):
		_arm_web_fullscreen_on_first_input()
		return
	# El modo headless de CI no tiene una ventana real sobre la que actuar.
	if OS.has_feature("headless") or DisplayServer.get_name().to_lower() == "headless":
		return
	var mode := DisplayServer.window_get_mode()
	if mode != DisplayServer.WINDOW_MODE_FULLSCREEN and mode != DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _arm_web_fullscreen_on_first_input() -> void:
	if _web_fullscreen_armed:
		return
	_web_fullscreen_armed = true
	JavaScriptBridge.eval("""
(() => {
  if (window.__entreLineasFullscreenArmed) return;
  window.__entreLineasFullscreenArmed = true;
  const request = () => {
    const target = document.documentElement;
    const fn = target.requestFullscreen || target.webkitRequestFullscreen || target.msRequestFullscreen;
    if (fn && !document.fullscreenElement && !document.webkitFullscreenElement) {
      try {
        const result = fn.call(target);
        if (result && result.catch) result.catch(() => {});
      } catch (_) {}
    }
    window.removeEventListener('pointerdown', request, true);
    window.removeEventListener('touchstart', request, true);
    window.removeEventListener('keydown', request, true);
  };
  window.addEventListener('pointerdown', request, true);
  window.addEventListener('touchstart', request, true);
  window.addEventListener('keydown', request, true);
})();
""", true)


func _enforce_room_mute() -> void:
	if audio_manager == null or version_manager == null:
		return
	var track_id := str(audio_manager.get("current_music_id"))
	if track_id.is_empty():
		return
	var raw_mutes: Variant = version_manager.get("track_mutes")
	var raw_volumes: Variant = version_manager.get("track_volumes")
	if typeof(raw_mutes) != TYPE_DICTIONARY or typeof(raw_volumes) != TYPE_DICTIONARY:
		return
	var track_mutes: Dictionary = raw_mutes
	var track_volumes: Dictionary = raw_volumes
	var track_muted := bool(track_mutes.get(track_id, false))
	var track_volume := clampf(float(track_volumes.get(track_id, 1.0)), 0.0, 1.0)
	var global_muted := bool(audio_manager.call("is_music_muted")) if audio_manager.has_method("is_music_muted") else false
	var suspended := bool(audio_manager.call("is_music_suspended")) if audio_manager.has_method("is_music_suspended") else false
	var target_muted := global_muted or suspended or track_muted or track_volume <= 0.0
	var bus := AudioServer.get_bus_index("Music")
	if bus < 0:
		return
	# AudioManager puede refrescar el bus al avanzar diálogos, cambiar de pantalla
	# o suspender/reanudar música. Reaplicamos aquí el mute específico de la pista
	# para que esa preferencia de habitación nunca se pierda accidentalmente.
	if AudioServer.is_bus_mute(bus) != target_muted:
		AudioServer.set_bus_mute(bus, target_muted)


func enforce_room_audio_now() -> void:
	_enforce_room_mute()


func uses_default_fullscreen() -> bool:
	return DEFAULT_FULLSCREEN
