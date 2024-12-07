extends CanvasLayer

var strength : float = 0.0
var noise : Noise
var noise_coord : float = 0.0

func trigger_shake(v : float):
	strength = v

func _ready() -> void:
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.frequency = 0.2
	noise.seed = randi()

func _process(delta: float) -> void:
	strength = lerp(strength, 0.0, 5.0 * delta)
	if strength > 0:
		noise_coord += 30.0 * delta
		offset = Vector2(noise.get_noise_2d(17.0, noise_coord), noise.get_noise_2d(93.0, noise_coord)) * strength
