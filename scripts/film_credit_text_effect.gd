class_name FilmCreditTextEffect
extends Node

const PRESET_PATH := "res://data/film_credit_presets.json"
const FILM_SHADER := preload("res://assets/shaders/film_credit_35mm.gdshader")

var _target: CanvasItem
var _preset_name := ""
var _material: ShaderMaterial
var _rng := RandomNumberGenerator.new()
var _motion: Dictionary = {}
var _base_position := Vector2.ZERO
var _base_rotation := 0.0
var _base_scale := Vector2.ONE
var _current_offset := Vector2.ZERO
var _target_offset := Vector2.ZERO
var _current_rotation_deg := 0.0
var _target_rotation_deg := 0.0
var _current_scale_delta := 0.0
var _target_scale_delta := 0.0
var _retarget_in := 0.0
var _captured_base := false


static func attach(target: CanvasItem, preset_name: String = "subtle_35mm_titles") -> Node:
    if target == null:
        return null
    var effect := FilmCreditTextEffect.new()
    effect._target = target
    effect._preset_name = preset_name
    target.add_child(effect)
    return effect


func _ready() -> void:
    if _target == null:
        _target = get_parent() as CanvasItem
    if _target == null:
        queue_free()
        return

    var preset := _load_preset(_preset_name)
    _apply_shader_preset(preset.get("shader", {}) as Dictionary)
    _motion = (preset.get("motion", {}) as Dictionary).duplicate(true)
    _rng.randomize()
    set_process(bool(_motion.get("enabled", true)))
    await get_tree().process_frame
    _capture_base_transform()


func _load_preset(requested_name: String) -> Dictionary:
    var fallback := _fallback_preset()
    if not FileAccess.file_exists(PRESET_PATH):
        return fallback
    var raw := FileAccess.get_file_as_string(PRESET_PATH)
    var parsed: Variant = JSON.parse_string(raw)
    if typeof(parsed) != TYPE_DICTIONARY:
        return fallback
    var root := parsed as Dictionary
    var presets: Variant = root.get("presets", {})
    if typeof(presets) != TYPE_DICTIONARY:
        return fallback
    var presets_dict := presets as Dictionary
    var selected_name := requested_name.strip_edges()
    if selected_name.is_empty():
        selected_name = str(root.get("default_preset", "subtle_35mm_titles"))
    var selected: Variant = presets_dict.get(selected_name, null)
    if typeof(selected) != TYPE_DICTIONARY:
        return fallback
    return selected as Dictionary


func _apply_shader_preset(shader_values: Dictionary) -> void:
    _material = ShaderMaterial.new()
    _material.shader = FILM_SHADER
    for parameter_name in shader_values.keys():
        _material.set_shader_parameter(str(parameter_name), shader_values[parameter_name])
    _target.material = _material


func _capture_base_transform() -> void:
    if not (_target is Control):
        return
    var control := _target as Control
    _base_position = control.position
    _base_rotation = control.rotation
    _base_scale = control.scale
    control.pivot_offset = control.size * 0.5
    _captured_base = true
    _choose_next_motion_target()


func _process(delta: float) -> void:
    if not _captured_base or not (_target is Control):
        return
    if not bool(_motion.get("enabled", true)):
        return

    var control := _target as Control
    control.pivot_offset = control.size * 0.5

    _retarget_in -= delta
    if _retarget_in <= 0.0:
        _choose_next_motion_target()

    var smoothing := maxf(0.1, float(_motion.get("smoothing", 10.0)))
    var blend := 1.0 - exp(-smoothing * delta)
    _current_offset = _current_offset.lerp(_target_offset, blend)
    _current_rotation_deg = lerpf(_current_rotation_deg, _target_rotation_deg, blend)
    _current_scale_delta = lerpf(_current_scale_delta, _target_scale_delta, blend)

    control.position = _base_position + _current_offset
    control.rotation = _base_rotation + deg_to_rad(_current_rotation_deg)
    control.scale = _base_scale * (1.0 + _current_scale_delta)


func _choose_next_motion_target() -> void:
    var jitter_px := maxf(0.0, float(_motion.get("jitter_px", 1.2)))
    var rotation_deg := maxf(0.0, float(_motion.get("rotation_deg", 0.04)))
    var scale_variation := maxf(0.0, float(_motion.get("scale_variation", 0.0012)))
    var min_interval := maxf(0.03, float(_motion.get("refresh_min_seconds", 0.07)))
    var max_interval := maxf(min_interval, float(_motion.get("refresh_max_seconds", 0.17)))

    _target_offset = Vector2(
        _rng.randf_range(-jitter_px, jitter_px),
        _rng.randf_range(-jitter_px, jitter_px)
    )
    _target_rotation_deg = _rng.randf_range(-rotation_deg, rotation_deg)
    _target_scale_delta = _rng.randf_range(-scale_variation, scale_variation)
    _retarget_in = _rng.randf_range(min_interval, max_interval)


func _fallback_preset() -> Dictionary:
    return {
        "shader": {
            "grain_enabled": true,
            "grain_intensity": 0.024,
            "grain_fps": 18.0,
            "chromatic_aberration_enabled": true,
            "chromatic_aberration_px": 0.85,
            "soft_focus_enabled": true,
            "soft_focus_amount": 0.14,
            "soft_focus_radius_px": 0.70,
            "halation_enabled": true,
            "halation_intensity": 0.10,
            "halation_radius_px": 1.25,
            "flicker_enabled": true,
            "flicker_intensity": 0.012,
            "flicker_speed": 7.5,
            "color_bleed_enabled": true,
            "color_bleed_intensity": 0.065,
            "color_bleed_radius_px": 0.90,
            "dust_enabled": true,
            "dust_intensity": 0.006,
            "scratches_enabled": true,
            "scratches_intensity": 0.003,
            "exposure_variation_enabled": true,
            "exposure_variation_intensity": 0.010,
            "exposure_variation_speed": 1.7
        },
        "motion": {
            "enabled": true,
            "jitter_px": 1.2,
            "rotation_deg": 0.04,
            "scale_variation": 0.0012,
            "refresh_min_seconds": 0.07,
            "refresh_max_seconds": 0.17,
            "smoothing": 10.5
        }
    }
