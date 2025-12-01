extends RigidBody2D
class_name AircraftController

@export var aircraft_data: AircraftData

signal stall_warning(active: bool)
signal speed_changed(speed: float)
signal altitude_changed(altitude: float)

@onready var aero_engine: AerodynamicsEngine = $AerodynamicsEngine
@onready var sprite: Sprite2D = $Sprite2D
@onready var gear_sprite: Sprite2D = $GearSprite
@onready var engine_audio: AudioStreamPlayer2D = $EngineAudio

enum State { FLYING, APPROACHING, LANDED, CRASHED }
var current_state: State = State.FLYING

var input_throttle: float = 0.6
var input_pitch: float = 0.0
var target_flap_setting: int = 0

func _ready() -> void:
    if aero_engine and aircraft_data:
        aero_engine.aircraft_data = aircraft_data
        aero_engine.weather_data = GameManager.current_weather
        aero_engine.gear_extended = not aircraft_data.gear_retractable
    if aircraft_data:
        mass = aircraft_data.mass
    _update_sprites()

func _physics_process(delta: float) -> void:
    if current_state in [State.CRASHED, State.LANDED]:
        return
    _handle_input(delta)
    _apply_physics(delta)
    _update_sprites()
    _emit_flight_data()

func _handle_input(delta: float) -> void:
    var throttle_input := Input.get_axis("throttle_down", "throttle_up")
    var throttle_rate := aircraft_data.throttle_response if aircraft_data else 0.5
    input_throttle = clamp(input_throttle + throttle_input * delta * throttle_rate, 0.0, 1.0)

    input_pitch = Input.get_axis("pitch_down", "pitch_up")

    if Input.is_action_just_pressed("flaps_up"):
        target_flap_setting = clamp(target_flap_setting - 1, 0, 3)
    if Input.is_action_just_pressed("flaps_down"):
        target_flap_setting = clamp(target_flap_setting + 1, 0, 3)

    if Input.is_action_just_pressed("toggle_gear") and aircraft_data and aircraft_data.gear_retractable and aero_engine:
        aero_engine.gear_extended = not aero_engine.gear_extended

    if aero_engine:
        aero_engine.throttle = input_throttle
        aero_engine.flap_setting = target_flap_setting

func _apply_physics(delta: float) -> void:
    var pitch_torque := input_pitch * (aircraft_data.pitch_rate if aircraft_data else 10.0)
    apply_torque(pitch_torque)

    if aero_engine:
        aero_engine.pitch = rotation
        aero_engine.velocity = linear_velocity
        aero_engine.angular_velocity = angular_velocity
    var forces := aero_engine.calculate_forces(delta) if aero_engine else {
        "lift": Vector2.ZERO,
        "drag": Vector2.ZERO,
        "thrust": Vector2.ZERO,
        "weight": Vector2.ZERO,
        "wind": Vector2.ZERO
    }
    apply_central_force(forces.lift)
    apply_central_force(forces.drag)
    apply_central_force(forces.thrust)
    apply_central_force(forces.weight)
    apply_central_force(forces.wind)

func _update_sprites() -> void:
    if gear_sprite:
        gear_sprite.visible = aero_engine.gear_extended
    if engine_audio:
        engine_audio.pitch_scale = 0.8 + (input_throttle * 0.5)

func _emit_flight_data() -> void:
    var airspeed := linear_velocity.length()
    emit_signal("speed_changed", airspeed)
    emit_signal("altitude_changed", -global_position.y)
    emit_signal("stall_warning", aero_engine.is_stalling() if aero_engine else false)
*** End of File