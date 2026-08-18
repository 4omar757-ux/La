extends SceneTree

const ORIGIN_LAT := 24.70808
const ORIGIN_LON := 46.67113
const WIDTH_M := 3600
const LENGTH_M := 4000

func _initialize() -> void:
	print("=== [1] loading base scene (orsay.tscn) ===")
	var base_scene: PackedScene = load("res://scenes/races/orsay.tscn")
	var root: Node3D = base_scene.instantiate()
	get_root().add_child(root)
	root.name = "Riyadh"

	await process_frame
	await process_frame

	var loader = root.get_node("MapDataLoader")
	var holder: Node3D = root.get_node("ProceduralDataHolder")
	var terrain: Terrain3D = root.get_node("Terrain3D")
	var osm_gen = loader.get_node("OSMDataGenerator")
	var boundaries_gen = loader.get_node("BoundariesGenerator")

	print("=== [2] clearing Orsay-specific generated content ===")
	if holder.has_node("OSMData"):
		holder.get_node("OSMData").free()
	await process_frame

	print("=== [3] rewiring MapDataLoader for Riyadh ===")
	loader.osm_data_path = "res://maps/riyadh/riyadh_osm_3d.geojson"
	loader.boundaries_data_path = "res://maps/riyadh/riyadh_boundaries_3d.geojson"
	loader.latitude_origin = str(ORIGIN_LAT)
	loader.longitude_origin = str(ORIGIN_LON)
	loader.elevation_origin = "0.0"
	loader.width_meters = WIDTH_M
	loader.length_meters = LENGTH_M

	print("=== [4] resetting terrain to flat ===")
	DirAccess.make_dir_recursive_absolute("res://maps/riyadh/terrain3d")
	terrain.data_directory = "res://maps/riyadh/terrain3d"
	for region in terrain.data.get_regions_active():
		terrain.data.remove_region(region, false)
	var img := Image.create_empty(512, 512, false, Image.FORMAT_RF)
	img.fill(Color(0.0, 0.0, 0.0, 0.0))
	var imgs: Array[Image] = []
	imgs.resize(3)
	imgs[0] = img # TYPE_HEIGHT
	terrain.data.import_images(imgs, Vector3(-1800, 0, -1800), 0.0, 1.0)
	terrain.data.save_directory("res://maps/riyadh/terrain3d")
	print("terrain regions active: ", terrain.data.get_regions_active().size())

	print("=== [5] generating boundaries ===")
	boundaries_gen.reload_action(holder)
	await process_frame
	print("boundaries is_loaded: ", boundaries_gen.is_loaded)

	print("=== [6] generating roads (may take a while) ===")
	osm_gen.reload_action(holder, 0) # ReloadKind.ROADS
	await physics_frame
	var waited := 0
	while osm_gen._can_build_roads and waited < 20000:
		await physics_frame
		waited += 1
		if waited % 200 == 0:
			print("  ...waiting on roads, physics tick ", waited, " built=", osm_gen._road_points_built, "/", osm_gen._road_points_to_build.size())
	print("roads done after ", waited, " physics ticks. can_build_roads=", osm_gen._can_build_roads, " built=", osm_gen._road_points_built, "/", osm_gen._road_points_to_build.size())

	print("=== [7] generating buildings ===")
	osm_gen.reload_action(holder, 1) # ReloadKind.BUILDINGS
	await process_frame
	await process_frame

	print("=== [10] clearing stale Orsay-specific path/walls/jumps/arrows and building a real RacePath ===")
	await _rebuild_race_path(root)

	print("=== [8] fixing node ownership ===")
	_fix_owner(root, root)

	print("=== [9] saving scene ===")
	DirAccess.make_dir_recursive_absolute("res://scenes/races")
	var packed := PackedScene.new()
	var err := packed.pack(root)
	print("pack error: ", err)
	var save_err := ResourceSaver.save(packed, "res://scenes/races/riyadh.tscn")
	print("save error: ", save_err)

	print("=== DONE ===")
	quit()


func _pick_best_road_points() -> Array:
	var file := FileAccess.open("res://maps/riyadh/riyadh_osm_3d.geojson", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	var best: Array = []
	var priority := ["primary", "secondary", "tertiary", "residential", "unclassified"]
	for wanted in priority:
		for f in data.features:
			var props: Dictionary = f.properties
			if props.get("highway") == wanted and f.geometry.type == "LineString":
				var coords: Array = f.geometry.coordinates
				if coords.size() > best.size():
					best = coords
		if best.size() >= 4:
			break
	return best

func _rebuild_race_path(root: Node3D) -> void:
	var checkpoints: Node3D = root.get_node("Checkpoints")
	var race_path: Path3D = checkpoints.get_node("RacePath")
	var loop_checkpoints: Node3D = checkpoints.get_node("LoopCheckpoints")
	var track_checkpoints: Node3D = checkpoints.get_node("TrackCheckpoints")
	var walls: Node3D = root.get_node("Walls")
	var jumps: Node3D = root.get_node("Jumps")
	var arrows: Node3D = root.get_node("Arrows")
	var spawner = root.get_node("PlayerSpawner")

	for n in [race_path, loop_checkpoints, track_checkpoints, walls, jumps, arrows]:
		for child in n.get_children():
			n.remove_child(child)
			child.queue_free()
	await process_frame
	await process_frame

	var raw_points := _pick_best_road_points()
	print("race path source points: ", raw_points.size())
	if raw_points.size() < 2:
		push_error("No usable road found for race path; leaving RacePath empty.")
		return

	# world x is mirrored: world_x = width_meters - raw_x (matches osm_data_generator.gd)
	var world_points: Array[Vector3] = []
	for c in raw_points:
		world_points.append(Vector3(-c[0] + WIDTH_M, 2.0, c[2]))

	var prev_node: RacePathNode = null
	var first_node: RacePathNode = null
	for i in range(world_points.size()):
		var rpn := RacePathNode.new()
		rpn.name = "RacePathNode%d" % i
		rpn.range_radius = 10.0
		race_path.add_child(rpn)
		rpn.owner = null # fixed up later
		rpn.global_position = world_points[i]
		if prev_node != null:
			rpn.predecessor = prev_node
			prev_node.successor = rpn
		else:
			first_node = rpn
		prev_node = rpn

	race_path.starting_node = first_node

	# spawn the player at the first race path point, facing the second point
	var spawn_pos: Vector3 = world_points[0] + Vector3(0, 1.0, 0)
	var look_target: Vector3 = world_points[1]
	var basis := Basis.looking_at(look_target - spawn_pos, Vector3.UP)
	spawner.transform = Transform3D(basis, spawn_pos)


# RoadSegment nodes (road-generator addon) are regenerated at runtime by
# RoadContainer._ready() -> rebuild_segments(true), and their script's
# _init() requires a constructor argument Godot's scene loader can't supply
# on deserialize. They must stay owner=null so PackedScene.pack() skips them.
const _ROAD_SEGMENT_SCRIPT_PATH := "res://addons/road-generator/nodes/road_segment.gd"

func _fix_owner(node: Node, root: Node) -> void:
	for child in node.get_children():
		var script: Script = child.get_script()
		if script != null and script.resource_path == _ROAD_SEGMENT_SCRIPT_PATH:
			continue
		if child.owner == null and child != root:
			child.owner = root
		_fix_owner(child, root)
