tool
extends Node2D
## Node used to switch between HitState2D children
## 
## @desc:
##		When a HitState2D child is activated all others will be deactivate.
##		This is a convinience tool for enforcing discrete hit states.

const ChildChangeDetector = preload("res://addons/fray/lib/helpers/child_change_detector.gd")
const HitState2D = preload("hit_state_2d.gd")
const Hitbox2D = preload("hitbox_2d.gd")

signal hitbox_intersected(detector_hitbox, detected_hitbox)
signal hitbox_seperated(detector_hitbox, detected_hitbox)

const NONE = "None "

export var source: NodePath

## String name of currently active state
var current_state: String = NONE setget set_current_state

onready var _source: Node
var _cc_detector: ChildChangeDetector


func _ready() -> void:
	_source = get_node_or_null(source)
	
	for child in get_children():
		if child is HitState2D:
			child.set_hitbox_source(_source)
			child.connect("hitbox_intersected", self, "_on_Hitstate_hitbox_intersected")
			child.connect("hitbox_seperated", self, "_on_Hitstate_hitbox_seperated")
			
	set_current_state(current_state)


func _get_configuration_warning() -> String:
	for child in get_children():
		if child is HitState2D:
			return ""
	
	return "This node has no hit states so there is nothing to switch between. Consider adding a HitState2D as a child."
	

func _enter_tree() -> void:
	if Engine.editor_hint:
		_cc_detector = ChildChangeDetector.new(self)
		_cc_detector.connect("child_changed", self, "_on_ChildChangeDetector_child_changed")


func _get_property_list() -> Array:
	var properties: Array = []
	var hit_states: PoolStringArray = [NONE]
	
	for child in get_children():
		if child is HitState2D:
			hit_states.append(child.name)
	
	properties.append({
		"name": "current_state",
		"type": TYPE_STRING,
		"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": hit_states.join(",")
	})
	
	return properties

## Returns a reference to the hit state with the given name if it exists.
func get_state_obj(state: String) -> HitState2D:
	var hit_state := get_node_or_null(current_state) as HitState2D
	return hit_state

## Returns a reference to the current state. Returns null if no state is set.
## Shorthand for switcher.get_state_obj(switcher.current_state)
func get_current_state_obj() -> HitState2D:
	return get_state_obj(current_state)

## Setter for 'current_state' property
func set_current_state(value: String) -> void:
	current_state = value

	for child in get_children():
		if child is HitState2D and child.name != current_state:
			child.deactivate()

	if current_state != NONE and is_inside_tree():
		var hit_state: HitState2D = get_current_state_obj()
		hit_state.activate()


func _on_ChildChangeDetector_child_changed(node: Node, change: int) -> void:
	if node is HitState2D and change != ChildChangeDetector.Change.REMOVED:
		if not node.is_connected("activated", self, "_on_HitState_activated"):
			node.connect("activated", self, "_on_HitState_activated", [node])
	property_list_changed_notify()


func _on_Hitstate_hitbox_intersected(detector_hitbox: Hitbox2D, detected_hitbox: Hitbox2D) -> void:
	emit_signal("hitbox_intersected", detector_hitbox, detected_hitbox)


func _on_Hitstate_hitbox_seperated(detector_hitbox: Hitbox2D, detected_hitbox: Hitbox2D) -> void:
	emit_signal("hitbox_seperated", detector_hitbox, detected_hitbox)


func _on_HitState_activated(activated_hitstate: HitState2D) -> void:
	set_current_state(activated_hitstate.name)