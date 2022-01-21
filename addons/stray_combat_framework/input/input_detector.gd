extends Node

const BufferedInput = preload("buffered_input.gd")
const InputSequence = preload("sequence/input_sequence.gd")
const SequenceData = preload("sequence/sequence_data.gd")
const CombinationInput = preload("virtual_inputs/combination_input.gd")
const VirtualInput = preload("virtual_inputs/virtual_input.gd")
const ActionInput = preload("virtual_inputs/action_input.gd")
const JoystickInput = preload("virtual_inputs/joystick_input.gd")
const KeyboardInput = preload("virtual_inputs/keyboard_input.gd")
const MouseInput = preload("virtual_inputs/mouse_input.gd")

signal sequence_inputed(sequence_name)

var buffer_duration: float = 1

var _time_since_first_input: float
var _input_by_id: Dictionary
var _sequence_by_name: Dictionary
var _input_buffer: Array
var _released_combinations: Array


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	_check_for_inputs()
	_increment_held_input_time(delta)
	_check_for_sequence_matches()
	_handle_buffer_clearing(delta)


func is_input_pressed(id: int) -> bool:
	if not _input_by_id.has(id):
		push_warning("Input with id %d does not exist" % id)
		return false
	return _input_by_id[id].is_pressed()


func is_input_just_pressed(id: int) -> bool:
	if not _input_by_id.has(id):
		push_warning("Input with id %d does not exist" % id)
		return false
	return _input_by_id[id].is_just_pressed()


func is_input_just_released(id: int) -> bool:
	if not _input_by_id.has(id):
		push_warning("Input with id %d does not exist" % id)
		return false
	return _input_by_id[id].is_just_released()


func feed_input(id: int, time_held: float = 0.0, was_released: bool = true, owner_combination: CombinationInput = null) -> void:
	feed_input_at(-1, id, time_held, was_released, owner_combination)


func feed_input_at(time_stamp: int, id: int, time_held: float = 0.0, was_released: bool = true, owner_combination: CombinationInput = null) -> void:
	var fed_buffered_input := BufferedInput.new()
	fed_buffered_input.id = id
	fed_buffered_input.time_stamp = time_stamp
	fed_buffered_input.time_held = time_held
	fed_buffered_input.was_released = was_released
	fed_buffered_input.owner_combination = owner_combination

	if time_stamp <= 0:
		fed_buffered_input.time_stamp = OS.get_ticks_msec()
		_input_buffer.append(fed_buffered_input)
	else:
		var insertion_index = _input_buffer.size()

		for i in len(_input_buffer):
			var buffered_input: BufferedInput = _input_buffer[i]

			if fed_buffered_input.time_stamp < buffered_input.time_stamp:
				insertion_index = i
				break
		_input_buffer.insert(insertion_index, fed_buffered_input)


func register_sequence_from_data(name: String, main_sequence: SequenceData, dirty_sequences: Array = []) -> void:
	var input_sequence := InputSequence.new()
	input_sequence.set_sequence(main_sequence, dirty_sequences)
	register_sequence(name, input_sequence)


func register_sequence(name: String, input_sequence: InputSequence) -> void:
	if name.empty():
		push_warning("A sequence name must be given")
		return

	if _sequence_by_name.has(name):
		push_warning("A sequence with name '%s' already exists." % name)
		return

	_sequence_by_name[name] = input_sequence


func register_combination(id: int, input_ids: PoolIntArray) -> void:
	if id in input_ids:
		push_warning("Combination id can not be included in input ids")
		return
	
	if input_ids.size() < 2:
		push_warning("Combination must contain 2 or more inputs.")
		return

	var combination_input := CombinationInput.new()
	combination_input.input_map = _input_by_id
	combination_input.input_ids = input_ids
	combination_input.id = id
	bind_virtual_input(id, combination_input)


func bind_virtual_input(id: int, virtual_input: VirtualInput) -> void:
	_input_by_id[id] = virtual_input


func bind_action_input(id: int, action: String) -> void:
	var action_input := ActionInput.new()
	action_input.action = action
	action_input.id = id
	bind_virtual_input(id, action_input)


func bind_joystick_input(id: int, device: int, button: int) -> void:
	var joystick_input := JoystickInput.new()
	joystick_input.device = device
	joystick_input.button = button
	joystick_input.id = id
	bind_virtual_input(id, joystick_input)


func bind_keyboard_input(id: int, key: int) -> void:
	var keyboard_input := KeyboardInput.new()
	keyboard_input.key = key
	keyboard_input.id = id
	bind_virtual_input(id, keyboard_input)


func bind_mouse_input(id: int, button: int) -> void:
	var mouse_input := MouseInput.new()
	mouse_input.button = button
	_input_by_id[id] = mouse_input
	mouse_input.id = id
	bind_virtual_input(id, mouse_input)


func _feed_released_combination_components(input: CombinationInput, time_stamp: int) -> void:
	for id in input.input_ids:
		if is_input_pressed(id):
			feed_input_at(time_stamp, id, 0, false, input)


func _check_for_inputs() -> void:	
	for id in _input_by_id:
		var input := _input_by_id[id] as VirtualInput

		if input.is_just_pressed():
			var buffered_input := BufferedInput.new()
			buffered_input.id = id
			buffered_input.time_stamp = OS.get_ticks_msec()

			if input is CombinationInput:
				if not _input_buffer.empty():
					for i in len(input.input_ids):
						var most_recent_input: BufferedInput = _input_buffer.back()
						var is_inputted_quick_enough: bool = buffered_input.get_time_between(most_recent_input) < 0.02
						# Prevents some fed inputs from being registered as components
						var is_intended_component: bool = \
							most_recent_input.owner_combination == null or \
							most_recent_input.owner_combination == input
		
						if input.is_component(most_recent_input.id) and is_intended_component:
							if is_inputted_quick_enough:
								_input_buffer.pop_back()
						else:
							break
			_input_buffer.append(buffered_input)
		elif input.is_just_released():
			if input is CombinationInput:
				_released_combinations.append(input)
				call_deferred("_feed_released_combination_components", input, OS.get_ticks_msec())

		input.poll()


func _increment_held_input_time(delta: float) -> void:
	for buffered_input in _input_buffer:
		buffered_input = buffered_input as BufferedInput
		
		if not buffered_input.was_released and _input_by_id.has(buffered_input.id):
			if is_input_pressed(buffered_input.id):
				buffered_input.time_held += delta
			else:
				buffered_input.was_released = true


func _check_for_sequence_matches() -> void:
	for sequence_name in _sequence_by_name:
		var sequence = _sequence_by_name[sequence_name] as InputSequence
		if sequence.is_match(_input_buffer):
			emit_signal("sequence_inputed", sequence_name)


func _handle_buffer_clearing(delta: float) -> void:
	if not _input_buffer.empty():
		_time_since_first_input += delta

		if _time_since_first_input >= buffer_duration:
			# Keep most recently pressed inputs in buffer if they're still being pressed
			var carry_over_buffer: Array
			var buffered_combinations: Array
			var input_buffer_reverse_loop := range(_input_buffer.size() - 1, -1, -1)

			for i in input_buffer_reverse_loop:
				var buffered_input: BufferedInput = _input_buffer[i]
				var is_already_carried_over := false
				if not buffered_input.was_released:
					for input in carry_over_buffer:
						if buffered_input.id == input.id:
							is_already_carried_over = true
							break

				if not buffered_input.was_released and not is_already_carried_over:
					if _input_by_id[buffered_input.id] is CombinationInput:
						buffered_combinations.append(buffered_input)

					carry_over_buffer.push_front(buffered_input)

			# Remove combination component inputs from carry over
			if not carry_over_buffer.empty():
				var temp_buffer: Array

				for buffered_input in carry_over_buffer:
					var is_featured_in_combination: bool = false
					
					if not buffered_input in buffered_combinations:
						for buffered_combination in buffered_combinations:
							var combination_input: CombinationInput = _input_by_id[buffered_combination.id]
							if buffered_input.id in combination_input.input_ids:
								is_featured_in_combination = true
								break

					if not is_featured_in_combination:
						temp_buffer.append(buffered_input)

				carry_over_buffer = temp_buffer


			_input_buffer.clear()

			for sequence_name in _sequence_by_name:
				_sequence_by_name[sequence_name].clear_discovered_indexes()

			for buffered_input in carry_over_buffer:
				_input_buffer.append(buffered_input)
			
			_time_since_first_input = 0