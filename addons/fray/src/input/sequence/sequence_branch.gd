class_name FraySequenceBranch
extends Resource
## Contains data on the inputs required for a sequence to be recognized.

## Array holding the InputRequirements used to define this sequence.
var input_requirements: Array[FrayInputRequirement]

## If true the final input in the sequence is allowed to be triggered by a button release..
## Search "fighting game negative edge" for more info on the concept
var is_negative_edge_enabled: bool

## Returns new builder instance.
static func builder() -> Builder:
	return Builder.new()


class Builder:
	extends RefCounted
	## [FraySequenceBranch] builder.
	
	var _input_requirements: Array[FrayInputRequirement]
	var _is_negative_edge_enabled: bool
	
	## Returns newly constructed sequence branch.
	func build() -> FraySequenceBranch:
		var branch := FraySequenceBranch.new()
		branch.input_requirements = _input_requirements
		branch.is_negative_edge_enabled = _is_negative_edge_enabled
		return branch
	
	## Appends an input requirement to the end of this sequence
	## [br]
	## Returns a reference to this sequence branch.
	## [br][br]
	## [kbd]max_delay[/kbd] is the maximum time in seconds between two inputs. 
	## A negative delay means that an infinite amount of time is allowed between inputs.
	## This parameter has no effect on the first requirement of a sequence.
	## [br]
	## [kbd]min_time_held[/kbd] is the minimum time in seconds that the input is required to be held. 
	## Inputs with a non-zero time are considered to be "charged inputs" and will only match with releases, not presses.
	func then(input: StringName, max_delay := 200, min_time_held := 0) -> Builder:
		var input_requirement := FrayInputRequirement.new()
		input_requirement.input = input
		input_requirement.max_delay = max_delay
		input_requirement.min_time_held = min_time_held
		_input_requirements.append(input_requirement)
		return self


	## Used to neable negative edge.
	##
	## Returns a reference to this sequence path.
	## [br]
	## If true the final input in the sequence is allowed to be triggered by a button release..
	## Search "fighting game negative edge" for more info on the concept
	func enable_negative_edge() -> Builder:
		_is_negative_edge_enabled = true
		return self