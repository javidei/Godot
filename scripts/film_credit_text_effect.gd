class_name FilmCreditTextEffect
extends Node

const PRESET_PATH := "res://data/film_credit_presets_compare_0925.json"
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


# Desde 0.9.25 los presets de comparación pueden contener solo diferencias.
# Siempre partimos del fallback, aplicamos el preset por defecto y finalmente
# los overrides del preset solicitado.
func _load_preset(requested_name: String) -> Dictionary:
    var result := _fallback_preset()
    if not FileAccess.file_exists(PRESET_PATH):
        return result

    var raw := FileAccess.get_file_as_string(PRESET_PATH)
    var parsed: Variant = JSON.parse_string(raw)
    if typeof(parsed) != TYPE_DICTIONARY:
        return result

    var root := parsed as Dictionary
    var presets_value: Variant = root.get("presets", {})
    if typeof(presets_value) != TYPE_DICTIONARY:
        return result
    var presets := presets_value as Dictionary

    var default_name := str(root.get("default_preset", "subtle_35mm_titles"))
    var default_value: Variant = presets.get(default_name, null)
    if typeof(default_value) == TYPE_DICTIONARY:
        result = _merge_preset(result, default_value as Dictionary)

    var selected_name := requested_name.strip_edges()
    if selected_name.is_empty():
        selected_name = default_name
    if selected_name == default_name:
        return result

    var selected: Variant = presets.get(selected_name, null)
    if typeof(selected) == TYPE_DICTIONARY:
        result = _merge_preset(result, selected as Dictionary)
    return result


func _merge_preset(base: Dictionary, overrides: Dictionary) -> Dictionary:
    var merged := base.duplicate(true)
    for key_value in overrides.keys():
        var key := str(key_value)
        var override_value: Variant = overrides[key_value]
        if key == "shader" or key == "motion":
            var section: Dictionary = {}
            var existing: Variant = merged.get(key, {})
            if typeof(existing) == TYPE_DICTIONARY:
                section = (existing as Dictionary).duplicate(true)
            if typeof(override_value) == TYPE_DICTIONARY:
                for parameter in (override_value as Dictionary).keys():
                    section[parameter] = (override_value as Dictionary)[parameter]
            merged[key] = section
        else:
            merged[key] = override_value
    return merged


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

    var smoothing := maxf(0.1, float(_motion.get("smoothing", 4.8)))
    var blend := 1.0 - exp(-smoothing * delta)
    _current_offset = _current_offset.lerp(_target_offset, blend)
    _current_rotation_deg = lerpf(_current_rotation_deg, _target_rotation_deg, blend)
    _current_scale_delta = lerpf(_current_scale_delta, _target_scale_delta, blend)

    control.position = _base_position + _current_offset
    control.rotation = _base_rotation + deg_to_rad(_current_rotation_deg)
    control.scale = _base_scale * (1.0 + _current_scale_delta)


func _choose_next_motion_target() -> void:
    var jitter_px := maxf(0.0, float(_motion.get("jitter_px", 0.28)))
    var rotation_deg := maxf(0.0, float(_motion.get("rotation_deg", 0.008)))
    var scale_variation := maxf(0.0, float(_motion.get("scale_variation", 0.00025)))
    var min_interval := maxf(0.03, float(_motion.get("refresh_min_seconds", 0.18)))
    var max_interval := maxf(min_interval, float(_motion.get("refresh_max_seconds", 0.45)))

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
            "grain_intensity": 0.04,
            "grain_fps": 18.0,
            "chromatic_aberration_enabled": true,
            "chromatic_aberration_px": 1.2,
            "soft_focus_enabled": true,
            "soft_focus_amount": 0.20,
            "soft_focus_radius_px": 0.85,
            "halation_enabled": true,
            "halation_intensity": 0.16,
            "halation_radius_px": 1.45,
            "flicker_enabled": true,
            "flicker_intensity": 0.007,
            "flicker_speed": 6.5,
            "color_bleed_enabled": true,
            "color_bleed_intensity": 0.09,
            "color_bleed_radius_px": 1.05,
            "dust_enabled": true,
            "dust_intensity": 0.0045,
            "scratches_enabled": true,
            "scratches_intensity": 0.0015,
            "exposure_variation_enabled": true,
            "exposure_variation_intensity": 0.007,
            "exposure_variation_speed": 1.5
        },
        "motion": {
            "enabled": true,
            "jitter_px": 0.28,
            "rotation_deg": 0.008,
            "scale_variation": 0.00025,
            "refresh_min_seconds": 0.18,
            "refresh_max_seconds": 0.45,
            "smoothing": 4.8
        }
    }
