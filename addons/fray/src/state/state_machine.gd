@icon("res://addons/fray/assets/icons/state_machine.svg")
class_name FrayStateMachine
extends Node
## Base Hierarchical State Machine
##
## This class wraps around the [FrayStateNodeStateMachine] and uses the [SceneTree] to
## process the state node.
## [br]
## The [method _get_root_impl] abstract method must be implemented in order to determine the root of this node.

enum AdvanceMode{
	PROCESS, ## Advance during the physics process
	PHYSICS, ## Advance during the idle process
	MANUAL, ## Advance manually
}

## The process mode of this state machine.
@export var advance_mode: AdvanceMode = AdvanceMode.PROCESS

## If true the combat state machine will be processing.
@export var active: bool = false


func _process(delta: float) -> void:
	if _can_process():
		get_root().process(delta)
		
		if advance_mode == AdvanceMode.PROCESS:
			advance()


func _physics_process(delta: float) -> void:
	if _can_process():
		get_root().physics_process(delta)

		if advance_mode == AdvanceMode.PHYSICS:
			advance()

## Used to manually advance the state machine.
func advance(input: Dictionary = {}, args: Dictionary = {}) -> void:
	if _can_process():
		_advance_impl()
		

func get_root() -> FrayStateNodeStateMachine:
	return _get_root_impl()


func _can_process() -> bool:
	return get_root() != null and active

## [code]Virtual method[/code] used to implement [method advance] method.
func _advance_impl(input: Dictionary = {}, args: Dictionary = {}) -> void:
	if get_root().current_node.is_empty():
		push_warning("Failed to advance. Current state not set.")
		return
	
	get_root().advance(input, args)

## [code]Abstract method[/code] used to implement [method get_root] method.
## [br]
## The return value of this method is used to determine what this state machine's
## current root node is.
func _get_root_impl() -> FrayStateNodeStateMachine:
	assert(false, "Method not implemented")
	return null