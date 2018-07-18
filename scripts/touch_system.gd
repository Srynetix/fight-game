extends Node

# Called when all touches have been released
signal touches_released()
# Called when one touch has been released
signal touch_released(idx)

const DEBUG_TOUCHES = false

class TouchData:
    """Touch data structure."""
    var touch_idx
    var touch_position
    var last_position
    var drag_speed
    var drag_relative
    var event_type

    func _init(idx, pos):
        self.touch_idx = idx
        self.touch_position = pos
        self.last_position = pos
        self.drag_speed = Vector2(0, 0)
        self.drag_relative = Vector2(0, 0)
        self.event_type = "touch"

# Current touches
var current_touches = {}

func debug_touches():
    """Print current touches in the console."""
    for touch_key in current_touches:
        var touch_data = current_touches[touch_key]
        print("{id} - {pos}".format({
            "id": touch_data.touch_idx,
            "pos": touch_data.last_position,
        }))

func _detect_all_touches_release():
    """Detect if all touches have been released."""
    if len(current_touches) == 0:
        emit_signal("touches_released")

func _get_or_create_touch_data(idx, pos):
    """Get or create touch data, from an index and a position."""
    if idx in current_touches:
        var touch_data = current_touches[idx]
        return touch_data
    else:
        return TouchData.new(idx, pos)

# Public API

func detect_touch_in_rect(rect):
    """Detect if there is a touch position in a rect."""
    for touch_idx in self.current_touches:
        var touch_data = self.current_touches[touch_idx]
        if touch_data.event_type == "touch":
            if rect.has_point(touch_data.last_position):
                if DEBUG_TOUCHES:
                    print("detected " + str(touch_data.touch_idx) + " type " + touch_data.event_type)
                return touch_data

    return null

func handle_input(event):
    """Handle touch input."""
    if event is InputEventScreenTouch:
        var idx = event.index
        var position = event.position
        var pressed = event.pressed

        var touch_data = _get_or_create_touch_data(idx, position)

        if pressed:
            if DEBUG_TOUCHES:
                print("pressed " + str(idx) + " at " + str(position))
            self.current_touches[idx] = touch_data
        else:
            if DEBUG_TOUCHES:
                print("released " + str(idx) + " at " + str(position))
            self.current_touches.erase(idx)
            emit_signal("touch_released", idx)

        # Detect all touches release
        self._detect_all_touches_release()

    if event is InputEventScreenDrag:
        var idx = event.index
        var position = event.position

        if DEBUG_TOUCHES:
            print("drag " + str(idx) + " at " + str(position))

        if idx in current_touches:
            var touch_data = current_touches[idx]
            touch_data.last_position = position
            touch_data.drag_relative = event.relative
            touch_data.drag_speed = event.speed
            touch_data.event_type = "drag"
            current_touches[idx] = touch_data