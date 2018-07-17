extends "res://characters/character.gd"


func get_input_action(name):
    return "p{id}_{name}".format({'id': self.PlayerID, 'name': name})

func handle_input():
    self.is_input_left_pressed = Input.is_action_pressed(get_input_action('left'))
    self.is_input_right_pressed = Input.is_action_pressed(get_input_action('right'))
    self.is_input_jump_just_pressed = Input.is_action_just_pressed(get_input_action('jump'))
    self.is_input_attack_just_pressed = Input.is_action_just_pressed(get_input_action('attack'))