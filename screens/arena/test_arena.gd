extends Node

onready var virtual_input = $virtual_input

func get_player_ui(player_id):
    var container = $hud/vbox/hbox
    var player_identifier = "p{id}".format({'id': player_id})
    return container.get_node(player_identifier)


func update_damages(target):
    var player_id = target.PlayerID
    var player_ui = get_player_ui(player_id)
    var damages = target.current_damages

    player_ui.get_node('label_damage').text = "{dmgs}%".format({"dmgs": damages})


func update_inputs(buffer):
    var inputs_ui = $hud/vbox/inputs
    inputs_ui.text = "Inputs: " + buffer


func _ready():
    $players/player.connect("damage_update", self, "update_damages")
    $players/player.input_system.connect("buffer_update", self, "update_inputs")
    $players/ai.connect("damage_update", self, "update_damages")

    # Set virtual input
    if not virtual_input.Disabled:
        $players/player.input_system.set_virtual_input(virtual_input)

    $game_zone.connect("body_exited", self, "_on_game_zone_body_exited")

func _on_joystick_moved(movement, force):
    $players/player.input_system.handle_virtual_joystick(movement, force)

func _on_button_pressed(button):
    $players/player.input_system.handle_virtual_button(button)

func _on_game_zone_body_exited(body):
    if body.is_in_group("character"):
        print("CHARACTER FELL")
        body.queue_free()