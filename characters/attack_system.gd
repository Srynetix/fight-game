extends Node

"""Attack system."""

var BASE_HIT_VELOCITY = Vector2(300, -50)

var ATTACKS = {
    "low": {
        "dmg": 2,
        "knockback": 0.1,
    },
    "mid": {
        "dmg": 2,
        "knockback": 0.2,
    },
    "high": {
        "dmg": 5,
        "knockback": 1.1
    }
}

# Public API

func get_data_from_attack(attack_type):
    """Get data from attack."""
    if attack_type in ATTACKS:
        return ATTACKS[attack_type]

    return {
        "dmg": 0,
        "knockback": 0
    }


func calculate_impulse_from_attack(target, attack_data):
    """Calculate impulse from attack."""
    var total_dmgs = target.current_damages
    var knockback = attack_data["knockback"]

    var coef = 1 + (total_dmgs / 100.0) * (knockback)
    return BASE_HIT_VELOCITY * coef