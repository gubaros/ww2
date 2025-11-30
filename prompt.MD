# Prompt: Carrier Landing WWII - Godot 4.x Game Development

## Contexto del Proyecto

Estoy desarrollando un juego 2D en **Godot 4.x** llamado "Carrier Landing" ambientado en la Segunda Guerra Mundial. El jugador debe aterrizar distintos aviones de la época en portaaviones, con física realista que simula aerodinámica, clima y características únicas de cada aeronave.

---

## Concepto del Juego

- **Género:** Simulador arcade de aterrizaje 2D
- **Vista:** Perfil lateral (side-scrolling)
- **Objetivo:** Aterrizar exitosamente en el portaaviones controlando velocidad, actitud (pitch), flaps y tren de aterrizaje
- **Progresión:** Dificultad incremental mediante aviones más complejos y condiciones climáticas adversas

---

## Mecánicas de Control del Jugador

El piloto controla:

1. **Throttle (Acelerador):** 0% a 100% - Controla empuje del motor
2. **Pitch (Actitud):** Inclinar nariz arriba/abajo
3. **Flaps:** Posiciones discretas (0°, 15°, 30°, 45°) - Aumentan sustentación y arrastre
4. **Tren de aterrizaje:** Extendido/Retraído - Añade arrastre cuando está abajo

---

## Sistema de Física Aerodinámica

### Fuerzas a Simular

```
SUSTENTACIÓN (Lift):
L = 0.5 * ρ * V² * S * CL
- ρ (rho): Densidad del aire (afectada por clima)
- V: Velocidad relativa al viento
- S: Superficie alar
- CL: Coeficiente de sustentación (varía con ángulo de ataque y flaps)

ARRASTRE (Drag):
D = 0.5 * ρ * V² * S * CD
- CD: Coeficiente de arrastre (aumenta con flaps extendidos, tren abajo)

EMPUJE (Thrust):
T = Potencia_Motor * Throttle * Eficiencia

PESO (Weight):
W = Masa * Gravedad
```

### Ángulo de Ataque (AoA)

- Diferencia entre dirección del movimiento y orientación del avión
- Afecta directamente CL y CD
- AoA excesivo = pérdida de sustentación (stall)

### Curva de Sustentación Simplificada

```
CL aumenta linealmente con AoA hasta ~15°
Después de ~15-18° (crítico): STALL - CL cae drásticamente
Flaps desplazan la curva hacia arriba y reducen velocidad de stall
```

---

## Estructura del Proyecto Godot

```
carrier_landing/
├── project.godot
├── assets/
│   ├── sprites/
│   │   ├── aircraft/
│   │   │   ├── f4f_wildcat.png
│   │   │   ├── swordfish.png
│   │   │   ├── zero.png
│   │   │   └── tbf_avenger.png
│   │   ├── carrier/
│   │   │   └── carrier_deck.png
│   │   ├── environment/
│   │   │   ├── sea.png
│   │   │   ├── clouds.png
│   │   │   └── rain.png
│   │   └── ui/
│   ├── audio/
│   │   ├── engine_loop.ogg
│   │   ├── wind.ogg
│   │   └── landing_success.ogg
│   └── fonts/
├── scenes/
│   ├── main.tscn
│   ├── game/
│   │   ├── game_world.tscn
│   │   ├── aircraft.tscn
│   │   ├── carrier.tscn
│   │   └── landing_zone.tscn
│   ├── ui/
│   │   ├── hud.tscn
│   │   ├── main_menu.tscn
│   │   ├── aircraft_select.tscn
│   │   └── game_over.tscn
│   └── components/
│       ├── flaps.tscn
│       └── landing_gear.tscn
├── scripts/
│   ├── aircraft/
│   │   ├── aircraft_controller.gd      # Control principal del avión
│   │   ├── aerodynamics_engine.gd      # Cálculos de física
│   │   ├── aircraft_data.gd            # Resource con stats del avión
│   │   └── aircraft_state_machine.gd   # Estados: flying, landing, crashed
│   ├── environment/
│   │   ├── weather_system.gd           # Sistema de clima
│   │   ├── wind_controller.gd          # Viento y turbulencia
│   │   └── sea_animation.gd
│   ├── carrier/
│   │   ├── carrier_controller.gd
│   │   └── arresting_wire.gd           # Cables de frenado
│   ├── systems/
│   │   ├── game_manager.gd             # Singleton - Estado del juego
│   │   ├── score_system.gd
│   │   ├── progression_manager.gd
│   │   └── input_manager.gd
│   └── ui/
│       ├── hud_controller.gd
│       └── instruments.gd              # Velocímetro, altímetro, etc.
├── resources/
│   ├── aircraft_configs/
│   │   ├── f4f_wildcat.tres
│   │   ├── swordfish.tres
│   │   ├── zero.tres
│   │   └── tbf_avenger.tres
│   └── weather_presets/
│       ├── clear.tres
│       ├── windy.tres
│       ├── stormy.tres
│       └── night.tres
└── autoload/
    └── globals.gd
```

---

## Especificaciones de Aviones (Resources)

### aircraft_data.gd (Clase Resource)

```gdscript
class_name AircraftData
extends Resource

@export var aircraft_name: String
@export var nation: String  # "USA", "UK", "Japan"

# Características físicas
@export var mass: float  # kg
@export var wing_area: float  # m²
@export var max_engine_power: float  # Newtons

# Coeficientes aerodinámicos base
@export var base_lift_coefficient: float
@export var base_drag_coefficient: float
@export var parasitic_drag: float

# Modificadores de flaps
@export var flap_lift_bonus: Array[float]  # [0°, 15°, 30°, 45°]
@export var flap_drag_penalty: Array[float]

# Tren de aterrizaje
@export var gear_drag_penalty: float
@export var gear_retractable: bool

# Límites operacionales
@export var stall_speed: float  # m/s sin flaps
@export var max_speed: float
@export var critical_aoa: float  # Ángulo de stall en grados
@export var approach_speed_recommended: float

# Handling
@export var pitch_rate: float  # Velocidad de rotación
@export var throttle_response: float  # Qué tan rápido responde el motor

# Sprites
@export var sprite_normal: Texture2D
@export var sprite_flaps_extended: Texture2D
@export var sprite_gear_down: Texture2D
```

### Configuraciones de Ejemplo

```
FAIREY SWORDFISH (Biplano - Fácil)
- Nación: UK
- Masa: 2,200 kg
- Velocidad de stall: 25 m/s
- Velocidad de aproximación: 35 m/s
- Tren fijo (no retráctil)
- Muy estable, perdona errores
- Respuesta lenta

F4F WILDCAT (Medio)
- Nación: USA
- Masa: 3,400 kg
- Velocidad de stall: 35 m/s
- Velocidad de aproximación: 45 m/s
- Tren retráctil
- Estable pero más rápido

A6M ZERO (Difícil)
- Nación: Japan
- Masa: 2,400 kg
- Velocidad de stall: 32 m/s
- Velocidad de aproximación: 42 m/s
- Muy ágil pero inestable
- Respuesta rápida, fácil de sobre-corregir

TBF AVENGER (Experto)
- Nación: USA
- Masa: 7,800 kg
- Velocidad de stall: 40 m/s
- Velocidad de aproximación: 55 m/s
- Pesado, inercia alta
- Difícil de frenar
```

---

## Sistema de Clima y Ambiente

### Variables Climáticas

```gdscript
class_name WeatherData
extends Resource

@export var weather_name: String
@export var air_density_modifier: float  # 1.0 = normal
@export var visibility: float  # 0.0 a 1.0
@export var base_wind_speed: float  # m/s
@export var wind_direction: float  # grados
@export var turbulence_intensity: float  # 0.0 a 1.0
@export var gust_frequency: float  # Ráfagas por minuto
@export var gust_strength: float
@export var rain_intensity: float  # 0.0 a 1.0
@export var deck_friction_modifier: float  # Cubierta mojada = menos fricción
```

### Presets de Clima

```
DESPEJADO (Clear)
- Densidad: 1.0
- Visibilidad: 1.0
- Viento base: 3 m/s
- Turbulencia: 0.1
- Sin lluvia

VENTOSO (Windy)
- Densidad: 1.0
- Visibilidad: 0.9
- Viento base: 12 m/s
- Turbulencia: 0.4
- Ráfagas frecuentes

TORMENTA (Stormy)
- Densidad: 1.05
- Visibilidad: 0.5
- Viento base: 20 m/s
- Turbulencia: 0.8
- Lluvia: 0.9
- Cubierta resbaladiza

NOCHE (Night)
- Visibilidad: 0.3
- Solo luces del portaaviones visibles
```

---

## Scripts Principales

### aerodynamics_engine.gd

```gdscript
class_name AerodynamicsEngine
extends Node

var aircraft_data: AircraftData
var weather_data: WeatherData

# Estado actual
var velocity: Vector2 = Vector2.ZERO
var angular_velocity: float = 0.0
var pitch: float = 0.0  # Radianes

# Controles
var throttle: float = 0.0  # 0.0 a 1.0
var flap_setting: int = 0  # 0, 1, 2, 3 (índice del array)
var gear_extended: bool = false

# Constantes
const GRAVITY: float = 9.81
const AIR_DENSITY_SEA_LEVEL: float = 1.225  # kg/m³

func calculate_forces(delta: float) -> Dictionary:
    var forces = {
        "lift": Vector2.ZERO,
        "drag": Vector2.ZERO,
        "thrust": Vector2.ZERO,
        "weight": Vector2.ZERO,
        "wind": Vector2.ZERO
    }
    
    # Velocidad relativa al aire (considerando viento)
    var wind_vector = _get_wind_vector()
    var airspeed_vector = velocity - wind_vector
    var airspeed = airspeed_vector.length()
    
    if airspeed < 0.1:
        return forces
    
    # Ángulo de ataque
    var velocity_angle = airspeed_vector.angle()
    var angle_of_attack = pitch - velocity_angle
    
    # Densidad del aire modificada por clima
    var air_density = AIR_DENSITY_SEA_LEVEL * weather_data.air_density_modifier
    
    # Presión dinámica
    var dynamic_pressure = 0.5 * air_density * airspeed * airspeed
    
    # Coeficientes con modificadores
    var cl = _calculate_lift_coefficient(angle_of_attack)
    var cd = _calculate_drag_coefficient(angle_of_attack)
    
    # Fuerzas
    var lift_magnitude = dynamic_pressure * aircraft_data.wing_area * cl
    var drag_magnitude = dynamic_pressure * aircraft_data.wing_area * cd
    
    # Dirección de las fuerzas
    var lift_direction = airspeed_vector.normalized().rotated(-PI/2)
    var drag_direction = -airspeed_vector.normalized()
    
    forces.lift = lift_direction * lift_magnitude
    forces.drag = drag_direction * drag_magnitude
    forces.thrust = Vector2.RIGHT.rotated(pitch) * aircraft_data.max_engine_power * throttle
    forces.weight = Vector2.DOWN * aircraft_data.mass * GRAVITY
    forces.wind = _calculate_turbulence()
    
    return forces

func _calculate_lift_coefficient(aoa: float) -> float:
    var aoa_deg = rad_to_deg(aoa)
    var base_cl = aircraft_data.base_lift_coefficient
    
    # Curva de sustentación simplificada
    var cl = base_cl * sin(2 * aoa)
    
    # Bonus de flaps
    cl += aircraft_data.flap_lift_bonus[flap_setting]
    
    # Stall check
    var effective_critical_aoa = aircraft_data.critical_aoa + (flap_setting * 2)
    if abs(aoa_deg) > effective_critical_aoa:
        # Post-stall: caída dramática
        var stall_factor = 1.0 - ((abs(aoa_deg) - effective_critical_aoa) / 10.0)
        cl *= clamp(stall_factor, 0.2, 1.0)
    
    return cl

func _calculate_drag_coefficient(aoa: float) -> float:
    var cd = aircraft_data.base_drag_coefficient
    cd += aircraft_data.parasitic_drag
    
    # Drag inducido (aumenta con sustentación)
    var cl = _calculate_lift_coefficient(aoa)
    cd += (cl * cl) / (PI * 6.0)  # Aspect ratio aproximado de 6
    
    # Penalización de flaps
    cd += aircraft_data.flap_drag_penalty[flap_setting]
    
    # Penalización de tren de aterrizaje
    if gear_extended:
        cd += aircraft_data.gear_drag_penalty
    
    return cd

func _get_wind_vector() -> Vector2:
    var base_wind = Vector2.RIGHT.rotated(deg_to_rad(weather_data.wind_direction))
    base_wind *= weather_data.base_wind_speed
    return base_wind

func _calculate_turbulence() -> Vector2:
    var turbulence = Vector2.ZERO
    if weather_data.turbulence_intensity > 0:
        turbulence.x = randf_range(-1, 1) * weather_data.turbulence_intensity * 50
        turbulence.y = randf_range(-1, 1) * weather_data.turbulence_intensity * 30
    return turbulence

func is_stalling() -> bool:
    var airspeed = (velocity - _get_wind_vector()).length()
    var stall_speed = aircraft_data.stall_speed
    # Flaps reducen velocidad de stall
    stall_speed -= flap_setting * 2
    return airspeed < stall_speed
```

### aircraft_controller.gd

```gdscript
class_name AircraftController
extends RigidBody2D

@export var aircraft_data: AircraftData

@onready var aero_engine: AerodynamicsEngine = $AerodynamicsEngine
@onready var sprite: Sprite2D = $Sprite2D
@onready var gear_sprite: Sprite2D = $GearSprite
@onready var engine_audio: AudioStreamPlayer2D = $EngineAudio

# Estado
enum State { FLYING, APPROACHING, LANDED, CRASHED }
var current_state: State = State.FLYING

# Input buffering
var input_throttle: float = 0.5
var input_pitch: float = 0.0
var target_flap_setting: int = 0

func _ready():
    aero_engine.aircraft_data = aircraft_data
    aero_engine.weather_data = GameManager.current_weather
    _update_sprites()

func _physics_process(delta: float):
    if current_state == State.CRASHED or current_state == State.LANDED:
        return
    
    _handle_input(delta)
    _apply_physics(delta)
    _update_sprites()
    _check_landing()

func _handle_input(delta: float):
    # Throttle (gradual)
    var throttle_input = Input.get_axis("throttle_down", "throttle_up")
    input_throttle = clamp(input_throttle + throttle_input * delta * 0.5, 0.0, 1.0)
    
    # Pitch
    input_pitch = Input.get_axis("pitch_down", "pitch_up")
    
    # Flaps (discreto)
    if Input.is_action_just_pressed("flaps_up"):
        target_flap_setting = clamp(target_flap_setting - 1, 0, 3)
    if Input.is_action_just_pressed("flaps_down"):
        target_flap_setting = clamp(target_flap_setting + 1, 0, 3)
    
    # Tren de aterrizaje
    if Input.is_action_just_pressed("toggle_gear"):
        if aircraft_data.gear_retractable:
            aero_engine.gear_extended = not aero_engine.gear_extended
    
    # Aplicar a motor aerodinámico
    aero_engine.throttle = input_throttle
    aero_engine.flap_setting = target_flap_setting

func _apply_physics(delta: float):
    # Rotación (pitch control)
    var pitch_torque = input_pitch * aircraft_data.pitch_rate
    apply_torque(pitch_torque)
    
    # Actualizar pitch en el motor
    aero_engine.pitch = rotation
    aero_engine.velocity = linear_velocity
    
    # Calcular y aplicar fuerzas aerodinámicas
    var forces = aero_engine.calculate_forces(delta)
    
    apply_central_force(forces.lift)
    apply_central_force(forces.drag)
    apply_central_force(forces.thrust)
    apply_central_force(forces.weight)
    apply_central_force(forces.wind)

func _update_sprites():
    # Actualizar sprite según configuración
    if aero_engine.gear_extended:
        gear_sprite.visible = true
    else:
        gear_sprite.visible = false
    
    # Audio del motor proporcional al throttle
    engine_audio.pitch_scale = 0.8 + (input_throttle * 0.6)

func _check_landing():
    pass  # Implementar detección de colisión con portaaviones

# Señales para UI
signal stall_warning
signal speed_changed(speed: float)
signal altitude_changed(altitude: float)
```

---

## Sistema de Aterrizaje y Puntuación

### Criterios de Aterrizaje Exitoso

```
1. Tren de aterrizaje extendido
2. Velocidad vertical < umbral (no golpear la cubierta)
3. Velocidad horizontal dentro de rango aceptable
4. Ángulo de pitch apropiado (no de nariz o cola)
5. Posición dentro de la zona de aterrizaje
6. Enganchar cable de frenado (opcional, bonus)
```

### Sistema de Puntuación

```
PUNTUACIÓN BASE: 1000 puntos

BONIFICACIONES:
+ Aterrizaje perfecto (centro de zona): +500
+ Enganchar primer cable: +300
+ Velocidad óptima: +200
+ Sin rebotes: +100
+ Clima adverso multiplicador: x1.5 a x2.0

PENALIZACIONES:
- Velocidad excesiva: -100 a -300
- Aterrizaje duro: -200
- Fuera de zona (pero en cubierta): -400
- Olvidar tren de aterrizaje: CRASH
```

---

## Input Map (project.godot)

```
[input]
throttle_up = Key W, Gamepad Right Trigger
throttle_down = Key S, Gamepad Left Trigger
pitch_up = Key Up Arrow, Gamepad Left Stick Up
pitch_down = Key Down Arrow, Gamepad Left Stick Down
flaps_up = Key Q
flaps_down = Key E
toggle_gear = Key G
pause = Key Escape, Gamepad Start
```

---

## HUD - Elementos de Interfaz

```
┌─────────────────────────────────────────────────────────┐
│  [Velocímetro]    [Altímetro]    [Indicador de Viento] │
│      85 kts          150 ft         ← 12 kts          │
│                                                         │
│  [Indicador AoA]   [Throttle]    [Estado Flaps/Gear]   │
│      ▲ 5°            75%          FLAPS: 15° GEAR: ▼   │
│                                                         │
│                                                         │
│  ════════════════════════════════════════════════════  │
│              ~~~~ PORTAAVIONES ~~~~                    │
│  ════════════════════════════════════════════════════  │
│                                                         │
│  [STALL WARNING]  (parpadea en rojo cuando aplica)     │
└─────────────────────────────────────────────────────────┘
```

---

## Flujo del Juego

```
MAIN MENU
    │
    ├── Nueva Partida
    │       │
    │       ├── Seleccionar Avión (desbloqueables)
    │       │
    │       └── Seleccionar Misión/Clima
    │               │
    │               └── GAMEPLAY
    │                       │
    │                       ├── Éxito → Puntuación → Desbloqueos
    │                       │
    │                       └── Crash → Retry / Menú
    │
    ├── Hangar (ver aviones desbloqueados)
    │
    ├── Tutorial
    │
    └── Opciones
```

---

## Requisitos Técnicos

- **Godot Version:** 4.2+ 
- **Rendering:** Compatibility (para máxima compatibilidad móvil)
- **Target Platforms:** iOS, Android
- **Resolución base:** 1920x1080 (escalar para móvil)
- **Touch Controls:** Implementar joystick virtual y botones táctiles

---

## Notas de Implementación

1. **Empezar por:** Sistema de física → Avión básico volando → Controles
2. **Luego:** Portaaviones y detección de aterrizaje → Sistema de puntuación
3. **Después:** UI/HUD → Múltiples aviones → Sistema de clima
4. **Pulir:** Efectos visuales → Audio → Progresión y desbloqueos
5. **Final:** Touch controls → Testing en dispositivos → Optimización

---

## Prompt de Inicio para Cursor

Cuando abras este proyecto en Cursor, podés usar este prompt inicial:

> "Estoy creando un juego de aterrizaje de aviones WWII en Godot 4.x siguiendo la especificación de este documento. Empecemos creando la estructura base del proyecto y el script `aerodynamics_engine.gd` con el sistema de física completo. El juego es 2D con vista lateral y necesito simular sustentación, arrastre, empuje y peso, con modificadores para flaps, tren de aterrizaje y condiciones climáticas."

---
