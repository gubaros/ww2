extends Node
class_name GameManager

@export_file("*.tres") var default_weather_path := "res://resources/weather_presets/clear.tres"
@export_file("*.tres") var default_aircraft_path := "res://resources/aircraft_configs/swordfish.tres"

var current_weather: WeatherData
var current_aircraft: AircraftData

func _ready() -> void:
    randomize()
    _ensure_input_map()
    _load_default_resources()

func _load_default_resources() -> void:
    if ResourceLoader.exists(default_weather_path):
        var weather_res: Resource = ResourceLoader.load(default_weather_path)
        if weather_res is WeatherData:
            current_weather = weather_res
    if current_weather == null:
        current_weather = WeatherData.new()
    if ResourceLoader.exists(default_aircraft_path):
        var aircraft_res: Resource = ResourceLoader.load(default_aircraft_path)
        if aircraft_res is AircraftData:
            current_aircraft = aircraft_res
    if current_aircraft == null:
        current_aircraft = AircraftData.new()

func set_weather(weather: WeatherData) -> void:
    current_weather = weather

func set_aircraft(aircraft: AircraftData) -> void:
    current_aircraft = aircraft

func _ensure_input_map() -> void:
    var key_bindings := {
        "throttle_up": [KEY_W],
        "throttle_down": [KEY_S],
        "pitch_up": [KEY_UP],
        "pitch_down": [KEY_DOWN],
        "flaps_up": [KEY_Q],
        "flaps_down": [KEY_E],
        "toggle_gear": [KEY_G],
        "pause": [KEY_ESCAPE]
    }

    for action in key_bindings.keys():
        if not InputMap.has_action(action):
            InputMap.add_action(action)
        for keycode in key_bindings[action]:
            var event := InputEventKey.new()
            event.physical_keycode = keycode
            event.keycode = keycode
            InputMap.action_add_event(action, event)

    var joy_bindings := {
        "throttle_up": [{"axis": JOY_AXIS_TRIGGER_RIGHT, "invert": false}],
        "throttle_down": [{"axis": JOY_AXIS_TRIGGER_LEFT, "invert": false}],
        "pitch_up": [{"axis": JOY_AXIS_LEFT_Y, "invert": true}],
        "pitch_down": [{"axis": JOY_AXIS_LEFT_Y, "invert": false}]
    }

    for action in joy_bindings.keys():
        if not InputMap.has_action(action):
            InputMap.add_action(action)
        for config in joy_bindings[action]:
            var joy_event := InputEventJoypadMotion.new()
            joy_event.axis = config[\"axis\"]
            joy_event.device = 0
            joy_event.axis_value = -1.0 if config.get(\"invert\", false) else 1.0
            InputMap.action_add_event(action, joy_event)
*** End of File