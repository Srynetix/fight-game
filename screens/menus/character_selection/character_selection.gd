extends Node2D

onready var TITLE_SCREEN = load("res://screens/menus/main/main_menu.tscn")
onready var LEVEL_SELECTION_SCREEN = load("res://screens/menus/level_selection/level_selection.tscn")

func _ready():
    $back_button.connect("button_down", self, "_on_back_button_button_down")
    $start_button.connect("button_down", self, "_on_start_button_button_down")

func _on_back_button_button_down():
    get_tree().change_scene_to(TITLE_SCREEN)

func _on_start_button_button_down():
    get_tree().change_scene_to(LEVEL_SELECTION_SCREEN)