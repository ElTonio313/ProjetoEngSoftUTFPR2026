extends Control


@onready var intro_panel: Control = %IntroPanel
@onready var continue_button: Button = %ContinueButton


func _ready() -> void:
	intro_panel.show()
	continue_button.grab_focus()


func _on_continue_button_pressed() -> void:
	intro_panel.hide()
