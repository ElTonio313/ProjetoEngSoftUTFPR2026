extends HBoxContainer
## Controles de som reutilizáveis e compactos: botão de mudo + controle de volume.

const TEXT_ON := "Som: ligado"
const TEXT_OFF := "Som: mudo"
const KNOB_COLOR := Color(0.105882, 0.368627, 0.12549)

@onready var mute_button: Button = %MuteButton
@onready var volume_slider: HSlider = %VolumeSlider

var _bus: int = 0


func _ready() -> void:
	_bus = AudioServer.get_bus_index("Master")
	if GameState != null and GameState.has_method("style_compact_button"):
		GameState.style_compact_button(mute_button)
	_style_slider()

	volume_slider.set_value_no_signal(db_to_linear(AudioServer.get_bus_volume_db(_bus)))
	mute_button.set_pressed_no_signal(AudioServer.is_bus_mute(_bus))
	_refresh()

	mute_button.toggled.connect(_on_mute_toggled)
	volume_slider.value_changed.connect(_on_volume_changed)


func _on_mute_toggled(muted: bool) -> void:
	AudioServer.set_bus_mute(_bus, muted)
	if muted and GameState != null and GameState.has_method("stop_speaking"):
		GameState.stop_speaking()
	_refresh()


func _on_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(_bus, linear_to_db(maxf(value, 0.0001)))


func _refresh() -> void:
	var muted := mute_button.button_pressed
	var raw_text := TEXT_OFF if muted else TEXT_ON
	mute_button.text = GameState.format_text(raw_text) if GameState != null else raw_text.to_upper()
	volume_slider.editable = not muted


func _style_slider() -> void:
	var knob := _make_knob(KNOB_COLOR, 28)
	volume_slider.add_theme_icon_override("grabber", knob)
	volume_slider.add_theme_icon_override("grabber_highlight", knob)
	volume_slider.add_theme_icon_override("grabber_disabled", _make_knob(Color(0.6, 0.6, 0.6), 28))

	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.76, 0.80, 0.75)
	track.set_corner_radius_all(6)
	track.content_margin_top = 5
	track.content_margin_bottom = 5
	volume_slider.add_theme_stylebox_override("slider", track)

	var filled := StyleBoxFlat.new()
	filled.bg_color = Color(0.180392, 0.545098, 0.219608)
	filled.set_corner_radius_all(6)
	filled.content_margin_top = 5
	filled.content_margin_bottom = 5
	volume_slider.add_theme_stylebox_override("grabber_area", filled)
	volume_slider.add_theme_stylebox_override("grabber_area_highlight", filled)


func _make_knob(color: Color, knob_size: int) -> ImageTexture:
	var image := Image.create(knob_size, knob_size, false, Image.FORMAT_RGBA8)
	var center := (knob_size - 1) / 2.0
	for y in knob_size:
		for x in knob_size:
			var distance := Vector2(x, y).distance_to(Vector2(center, center))
			var alpha := clampf(center + 0.5 - distance, 0.0, 1.0)
			var px_col := Color.WHITE if distance > center - 2.2 else color
			image.set_pixel(x, y, Color(px_col.r, px_col.g, px_col.b, alpha))
	return ImageTexture.create_from_image(image)
