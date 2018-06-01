extends Node2D

onready var TEST_ARENA_SCREEN = load("res://screens/arena/test_arena.tscn")
onready var CHARACTER_SELECTION_SCREEN = load("res://screens/menus/character_selection/character_selection.tscn")

func _ready():
    $back_button.connect("button_down", self, "_on_back_button_button_down")
    $start_button.connect("button_down", self, "_on_start_button_button_down")

func _on_back_button_button_down():
    get_tree().change_scene_to(CHARACTER_SELECTION_SCREEN)

func _on_start_button_button_down():
    get_tree().change_scene_to(TEST_ARENA_SCREEN)