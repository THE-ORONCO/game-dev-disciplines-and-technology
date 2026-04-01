extends Timer

func _on_timeout():
	# print("Expired")
	var Frog = preload("res://jump-and-run/scenes/objects/frog.tscn")
	var mob_tmp = Frog.instantiate()
	var y = 200	
	var x = RandomNumberGenerator.new().randi_range(
		$MobRegionStart.global_position.x, 
		$MobRegionEnd.global_position.x)
	mob_tmp.position = Vector2(x, y)
	get_parent().get_node("Enemies").add_child(mob_tmp)
