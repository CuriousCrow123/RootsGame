extends GutTest
## Unit tests for PlayerController save/load contract.


func test_save_data_structure() -> void:
	var player: PlayerController = PlayerController.new()
	add_child_autofree(player)
	player.global_position = Vector3(1.0, 2.0, 3.0)

	var data: Dictionary = player.get_save_data()
	assert_has(data, "position")
	assert_has(data, "facing_direction")
	var pos: Dictionary = data["position"]
	var pos_x: float = pos["x"]
	var pos_y: float = pos["y"]
	var pos_z: float = pos["z"]
	assert_almost_eq(pos_x, 1.0, 0.01)
	assert_almost_eq(pos_y, 2.0, 0.01)
	assert_almost_eq(pos_z, 3.0, 0.01)
	var facing: String = data["facing_direction"]
	assert_eq(facing, "down", "Default facing should be down")


func test_load_save_data_roundtrip() -> void:
	var player: PlayerController = PlayerController.new()
	add_child_autofree(player)
	player.global_position = Vector3(5.0, 0.0, -3.0)

	var save_data: Dictionary = player.get_save_data()

	var player2: PlayerController = PlayerController.new()
	add_child_autofree(player2)
	player2.load_save_data(save_data)

	assert_almost_eq(float(player2.global_position.x), 5.0, 0.01)
	assert_almost_eq(float(player2.global_position.z), -3.0, 0.01)


func test_save_key() -> void:
	var player: PlayerController = PlayerController.new()
	add_child_autofree(player)
	assert_eq(player.get_save_key(), "player")
