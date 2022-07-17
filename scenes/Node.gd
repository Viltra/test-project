extends Node

onready var enemies = get_tree().get_nodes_in_group("enemies")
onready var player = $player

func connect_to_enemies():
	for member in enemies:
		var ConnectingEnemy = member
		member.connect("enemy_died", player, "find_enemy")
		
func repath():
	  player.generate_path()
