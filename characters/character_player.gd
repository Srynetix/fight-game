extends "res://characters/character.gd"

func _handle_character_input():
    """Handle character input."""
    self.input_system.handle_player_keys()