extends Node
class_name AerodynamicsEngine

var aircraft_data: AircraftData
var weather_data: WeatherData

var velocity: Vector2 = Vector2.ZERO
var angular_velocity: float = 0.0
var pitch: float = 0.0

var throttle: float = 0.0
var flap_setting: int = 0
var gear_extended: bool = false

const GRAVITY := 9.81
const AIR_DENSITY_SEA_LEVEL := 1.225

func calculate_forces(delta: float) -> Dictionary:
    if aircraft_data == null or weather_data == null:
        return _empty_forces()

    var forces := _empty_forces()
    var wind_vector := _get_wind_vector()
    var airspeed_vector := velocity - wind_vector
    var airspeed := airspeed_vector.length()

    if airspeed < 0.1:
        forces.weight = Vector2.DOWN * aircraft_data.mass * GRAVITY
        forces.thrust = Vector2.RIGHT.rotated(pitch) * aircraft_data.max_engine_power * throttle
        forces.wind = _calculate_turbulence(delta)
        return forces

    var angle_of_attack := _get_angle_of_attack(airspeed_vector)
    var air_density := AIR_DENSITY_SEA_LEVEL * weather_data.air_density_modifier
    var dynamic_pressure := 0.5 * air_density * airspeed * airspeed

    var cl := _calculate_lift_coefficient(angle_of_attack)
    var cd := _calculate_drag_coefficient(angle_of_attack, cl)

    var lift_magnitude := dynamic_pressure * aircraft_data.wing_area * cl
    var drag_magnitude := dynamic_pressure * aircraft_data.wing_area * cd

    var lift_direction := airspeed_vector.normalized().rotated(-PI / 2.0)
    var drag_direction := -airspeed_vector.normalized()

    forces.lift = lift_direction * lift_magnitude
    forces.drag = drag_direction * drag_magnitude
    forces.thrust = Vector2.RIGHT.rotated(pitch) * aircraft_data.max_engine_power * clamp(throttle, 0.0, 1.0)
    forces.weight = Vector2.DOWN * aircraft_data.mass * GRAVITY
    forces.wind = _calculate_turbulence(delta)

    return forces

func is_stalling() -> bool:
    if aircraft_data == null:
        return false
    var airspeed := (velocity - _get_wind_vector()).length()
    var stall_speed := aircraft_data.stall_speed - (flap_setting * 2.0)
    return airspeed < max(stall_speed, 5.0)

func _get_angle_of_attack(airspeed_vector: Vector2) -> float:
    var velocity_angle := airspeed_vector.angle()
    return wrapf(pitch - velocity_angle, -PI, PI)

func _calculate_lift_coefficient(aoa: float) -> float:
    var aoa_deg := rad_to_deg(aoa)
    var base_cl := aircraft_data.base_lift_coefficient
    var cl := base_cl * sin(2.0 * aoa)

    cl += _sample_array(aircraft_data.flap_lift_bonus, flap_setting)

    var effective_critical := aircraft_data.critical_aoa + (flap_setting * 2.0)
    if abs(aoa_deg) > effective_critical:
        var stall_factor := 1.0 - ((abs(aoa_deg) - effective_critical) / 10.0)
        cl *= clamp(stall_factor, 0.15, 1.0)

    return cl

func _calculate_drag_coefficient(aoa: float, cl: float) -> float:
    var cd := aircraft_data.base_drag_coefficient + aircraft_data.parasitic_drag
    cd += (cl * cl) / (PI * 6.0)
    cd += _sample_array(aircraft_data.flap_drag_penalty, flap_setting)
    if gear_extended:
        cd += aircraft_data.gear_drag_penalty
    cd += clamp(abs(aoa) * 0.02, 0.0, 0.4)
    return cd

func _get_wind_vector() -> Vector2:
    if weather_data == null:
        return Vector2.ZERO
    var base_wind := Vector2.RIGHT.rotated(deg_to_rad(weather_data.wind_direction))
    base_wind *= weather_data.base_wind_speed
    return base_wind

func _calculate_turbulence(delta: float) -> Vector2:
    if weather_data == null or weather_data.turbulence_intensity <= 0.0:
        return Vector2.ZERO
    var noise := Vector2(
        randf_range(-1.0, 1.0),
        randf_range(-1.0, 1.0)
    )
    noise.x *= weather_data.turbulence_intensity * 40.0
    noise.y *= weather_data.turbulence_intensity * 20.0

    if weather_data.gust_frequency > 0.0:
        var gust_chance := weather_data.gust_frequency * delta / 60.0
        if randf() < gust_chance:
            noise += Vector2(randf_range(-weather_data.gust_strength, weather_data.gust_strength), 0.0)
    return noise

func _sample_array(values, index: int) -> float:
    if values == null:
        return 0.0
    var count := values.size()
    if count == 0:
        return 0.0
    var safe_index := clamp(index, 0, count - 1)
    return values[safe_index]

func _empty_forces() -> Dictionary:
    return {
        "lift": Vector2.ZERO,
        "drag": Vector2.ZERO,
        "thrust": Vector2.ZERO,
        "weight": Vector2.ZERO,
        "wind": Vector2.ZERO
    }
