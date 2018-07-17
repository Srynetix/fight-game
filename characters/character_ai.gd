extends "res://characters/character.gd"

onready var attack_timer = $attack_timer

var PLAYER_LENGTH_THRESHOLD = 40
var ATTACK_DELAY = 0.35     # secs

var attack_at_next_turn = false

func _ready():
    attack_timer.wait_time = ATTACK_DELAY
    attack_timer.connect("timeout", self, "_on_attack_timer_timeout")


func detect_players():
    var output_characters = []
    var characters = get_tree().get_nodes_in_group("character")
    for c in characters:
        if c != self:
            output_characters.append(c)

    return output_characters


func handle_input():
    # Reset inputs
    self.is_input_right_pressed = false
    self.is_input_left_pressed = false
    self.is_input_jump_just_pressed = false
    self.is_input_attack_just_pressed = false

    # Attacking
    if attack_timer.time_left > 0:
        return

    var players = self.detect_players()
    var first = players[0]

    var p_vec = first.position - position
    var p_direction = p_vec.normalized()
    var p_length = p_vec.length()

    if abs(p_length) > PLAYER_LENGTH_THRESHOLD:
        if p_direction.x > 0:
            self.is_input_right_pressed = true
        else:
            self.is_input_left_pressed = true
    else:
        attack_timer.start()

    if self.attack_at_next_turn:
        self.is_input_attack_just_pressed = true
        self.attack_at_next_turn = false


func _on_attack_timer_timeout():
    self.attack_at_next_turn = true
