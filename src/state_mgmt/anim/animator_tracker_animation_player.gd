class_name FrayAnimatorTrackerAnimationPlayer
extends FrayAnimatorTracker

@export_node_path("AnimationPlayer") var anim_player_path: NodePath

var _anim_player: AnimationPlayer


func _get_animation_list_impl() -> PackedStringArray:
	return _anim_player.get_animation_list()


func _ready_impl() -> void:
	_anim_player = fn_get_node.call(anim_player_path)


func _process_impl(delta: float) -> void:
	if _anim_player.is_playing():
		if _anim_player.current_animation_position == 0:
			emit_anim_started(_anim_player.current_animation)

		emit_anim_updated(_anim_player.current_animation, _anim_player.current_animation_position)

		if _anim_player.current_animation_position + delta >= _anim_player.current_animation_length:
			emit_anim_finished(_anim_player.current_animation)
