tool
extends "detection_box_2d.gd"
## docstring

#inner classes

signal hit_detected()

#enums

const BOX_COLOR = Color("0088ff")

var HitBox2D: GDScript = load("hit_box_2d.gd") 

#exported variables

#public variables

#private variables

#onready variables


#optional built-in virtual _init method

func _ready() -> void:
	modulate = BOX_COLOR

func _process(_delta: float) -> void:
	if Engine.editor_hint:
		modulate = BOX_COLOR
		return

#public methods

#private methods

func _on_area_entered(area: Area2D) -> void:
	if area is HitBox2D.new():
		emit_signal("hit_detected")
