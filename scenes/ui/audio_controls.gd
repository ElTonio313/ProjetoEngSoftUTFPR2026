extends HBoxContainer
## Controles de som reutilizáveis: botão de mudo + controle de volume.
##
## Eles mexem no barramento "Master" do AudioServer, que é global e continua
## valendo ao trocar de cena. Por isso o menu, a Fase 1 e a Fase 2 podem
## instanciar esta mesma cena (scenes/ui/AudioControls.tscn) e todos mostram
## o mesmo estado.

const TEXT_ON := "Som: ligado"
const TEXT_OFF := "Som: mudo"
const KNOB_COLOR := Color(0.101960786, 0.101960786, 0.101960786)

@onready var mute_button: Button = %MuteButton
@onready var volume_slider: HSlider = %VolumeSlider

var _bus: int = 0


func _ready() -> void:
	_bus = AudioServer.get_bus_index("Master")
	_style_slider()

	# Começa mostrando o estado atual (pode ter sido mudado em outra tela).
	volume_slider.set_value_no_signal(db_to_linear(AudioServer.get_bus_volume_db(_bus)))
	mute_button.set_pressed_no_signal(AudioServer.is_bus_mute(_bus))
	_refresh()

	mute_button.toggled.connect(_on_mute_toggled)
	volume_slider.value_changed.connect(_on_volume_changed)


func _on_mute_toggled(muted: bool) -> void:
	AudioServer.set_bus_mute(_bus, muted)
	_refresh()


func _on_volume_changed(value: float) -> void:
	# 0.0001 (= -80 dB) evita o valor infinito e é inaudível.
	AudioServer.set_bus_volume_db(_bus, linear_to_db(maxf(value, 0.0001)))


func _refresh() -> void:
	var muted := mute_button.button_pressed
	mute_button.text = TEXT_OFF if muted else TEXT_ON
	volume_slider.editable = not muted


## Deixa o controle de volume grande e fácil de acertar com o mouse.
func _style_slider() -> void:
	var knob := _make_knob(KNOB_COLOR, 40)
	volume_slider.add_theme_icon_override("grabber", knob)
	volume_slider.add_theme_icon_override("grabber_highlight", knob)
	volume_slider.add_theme_icon_override("grabber_disabled", _make_knob(Color(0.6, 0.6, 0.6), 40))

	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.69, 0.69, 0.69)
	track.set_corner_radius_all(6)
	track.content_margin_top = 6
	track.content_margin_bottom = 6
	volume_slider.add_theme_stylebox_override("slider", track)

	var filled := StyleBoxFlat.new()
	filled.bg_color = Color(0.1, 0.5, 0.2)
	filled.set_corner_radius_all(6)
	filled.content_margin_top = 6
	filled.content_margin_bottom = 6
	volume_slider.add_theme_stylebox_override("grabber_area", filled)
	volume_slider.add_theme_stylebox_override("grabber_area_highlight", filled)


func _make_knob(color: Color, size: int) -> ImageTexture:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := (size - 1) / 2.0
	for y in size:
		for x in size:
			var distance := Vector2(x, y).distance_to(Vector2(center, center))
			var alpha := clampf(center + 0.5 - distance, 0.0, 1.0)  # borda suave
			image.set_pixel(x, y, Color(color, alpha))
	return ImageTexture.create_from_image(image)
