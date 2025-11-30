extends Resource
class_name WeatherData

@export var weather_name: String = "Clear"
@export var air_density_modifier: float = 1.0
@export_range(0.0, 1.0) var visibility: float = 1.0
@export var base_wind_speed: float = 3.0
@export var wind_direction: float = 0.0
@export_range(0.0, 1.0) var turbulence_intensity: float = 0.1
@export var gust_frequency: float = 0.0
@export var gust_strength: float = 0.0
@export_range(0.0, 1.0) var rain_intensity: float = 0.0
@export var deck_friction_modifier: float = 1.0
