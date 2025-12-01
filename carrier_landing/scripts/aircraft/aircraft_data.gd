extends Resource
class_name AircraftData

@export var aircraft_name: String
@export var nation: String

# Características físicas
@export var mass: float = 1000.0
@export var wing_area: float = 20.0
@export var max_engine_power: float = 5000.0

# Coeficientes aerodinámicos base
@export var base_lift_coefficient: float = 1.2
@export var base_drag_coefficient: float = 0.08
@export var parasitic_drag: float = 0.02

# Modificadores de flaps (0°, 15°, 30°, 45°)
@export var flap_lift_bonus: PackedFloat32Array = PackedFloat32Array(0.0, 0.15, 0.3, 0.45)
@export var flap_drag_penalty: PackedFloat32Array = PackedFloat32Array(0.0, 0.05, 0.1, 0.15)

# Tren de aterrizaje
@export var gear_drag_penalty: float = 0.05
@export var gear_retractable: bool = true

# Límites operacionales
@export var stall_speed: float = 30.0
@export var max_speed: float = 120.0
@export var critical_aoa: float = 15.0
@export var approach_speed_recommended: float = 40.0

# Handling
@export var pitch_rate: float = 12.0
@export var throttle_response: float = 0.5

# Sprites (se asignan en el editor)
@export var sprite_normal: Texture2D
@export var sprite_flaps_extended: Texture2D
@export var sprite_gear_down: Texture2D
