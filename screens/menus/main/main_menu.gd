extends Node2D

var CHARACTER_SELECTION = load("res://screens/menus/character_selection/character_selection.tscn")

func _ready():
    $training_button.connect("button_down", self, "_on_training_button_button_down")

func _on_training_button_button_down():
    get_tree().change_scene_to(CHARACTER_SELECTION)



