extends Control


@onready var intro_panel: Control = %IntroPanel
@onready var continue_button: Button = %ContinueButton
@onready var mammals_zone: DropZone = %MammalsZone
@onready var reptiles_zone: DropZone = %ReptilesZone
@onready var birds_zone: DropZone = %BirdsZone

func _ready() -> void:
	intro_panel.show()
	continue_button.grab_focus()
	for zone in [mammals_zone, reptiles_zone, birds_zone]:
		zone.animal_dropped.connect(_on_animal_dropped)


func _on_continue_button_pressed() -> void:
	intro_panel.hide()

func _on_animal_dropped(category: String) -> void:
	print("Solto em: ", category)
