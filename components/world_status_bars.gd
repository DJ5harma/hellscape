extends Node3D
class_name WorldStatusBars

const BAR_WIDTH := 64
const BAR_HEIGHT := 6

var tracked_actor: Node
var max_health := 1.0
var max_energy := 0.0
var health_sprite: Sprite3D
var energy_sprite: Sprite3D
var health_texture: ImageTexture
var energy_texture: ImageTexture
var health_image: Image
var energy_image: Image
var last_health_ratio := -1.0
var last_energy_ratio := -1.0
var update_timer := 0.0

func setup(actor: Node, health_limit: float, energy_limit := 0.0) -> void:
	tracked_actor = actor
	max_health = maxf(health_limit, 1.0)
	max_energy = maxf(energy_limit, 0.0)
	_build()

func _build() -> void:
	position = Vector3(0.0, 1.35, 0.0)
	health_image = _create_image(Color("#381c24"), Color("#e84e5b"))
	health_texture = ImageTexture.create_from_image(health_image)
	health_sprite = _create_sprite(health_texture, 0.0)
	_update_health(1.0)
	if max_energy > 0.0:
		energy_image = _create_image(Color("#1c2440"), Color("#4d8dff"))
		energy_texture = ImageTexture.create_from_image(energy_image)
		energy_sprite = _create_sprite(energy_texture, -0.12)
		_update_energy(1.0)

func _process(delta: float) -> void:
	if not is_instance_valid(tracked_actor):
		return
	update_timer -= delta
	if update_timer > 0.0:
		return
	update_timer = 0.05
	var health_ratio := clampf(float(tracked_actor.health) / max_health, 0.0, 1.0)
	if absf(health_ratio - last_health_ratio) > 0.001:
		_update_health(health_ratio)
	if is_instance_valid(energy_sprite):
		var energy_ratio := clampf(float(tracked_actor.energy) / max_energy, 0.0, 1.0)
		if absf(energy_ratio - last_energy_ratio) > 0.005:
			_update_energy(energy_ratio)

func _create_image(background: Color, fill: Color) -> Image:
	var image := Image.create(BAR_WIDTH, BAR_HEIGHT, false, Image.FORMAT_RGBA8)
	image.fill(background)
	return image

func _create_sprite(texture: ImageTexture, y_offset: float) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.texture = texture
	sprite.position = Vector3(0.0, y_offset, 0.0)
	sprite.pixel_size = 0.012
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.no_depth_test = true
	sprite.render_priority = 20
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	return sprite

func _update_health(ratio: float) -> void:
	last_health_ratio = ratio
	_update_image(health_image, health_texture, ratio, Color("#381c24"), Color("#e84e5b"))

func _update_energy(ratio: float) -> void:
	last_energy_ratio = ratio
	_update_image(energy_image, energy_texture, ratio, Color("#1c2440"), Color("#4d8dff"))

func _update_image(image: Image, texture: ImageTexture, ratio: float, background: Color, fill: Color) -> void:
	image.fill(background)
	var filled_width := maxi(1, roundi(float(BAR_WIDTH) * ratio))
	image.fill_rect(Rect2i(0, 0, filled_width, BAR_HEIGHT), fill)
	texture.update(image)
