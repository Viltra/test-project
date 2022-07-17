extends Area2D

var player = null
var reached_destination: bool

func can_see_player():
	return player != null

func _on_PlayerDetection_body_entered(body):
	player = body
	body.reached_destination = true
func _on_PlayerDetection_body_exited(_body):
	player = null
