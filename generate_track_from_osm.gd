extends SceneTree
# Generic headless track generator, reusable for any city.
# Usage:
#   godot --headless --script res://generate_track_from_osm.gd -- \
#     city_id=riyadh origin_lat=24.70808 origin_lon=46.67113 width=3600 length=4000 \
#     display_name=Riyadh
#
# Expects maps/<city_id>/<city_id>_osm_3d.geojson and
# maps/<city_id>/<city_id>_boundaries_3d.geojson to already exist
# (see geojson_to_3d.py for producing the former from raw Overpass/osmtogeojson output).

var city_id := "riyadh"
var origin_lat := 24.70808
var origin_lon := 46.67113
var width_m := 3600
var length_m := 4000
var display_name := "Riyadh"


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		var parts := arg.split("=", true, 1)
		if parts.size() != 2:
			continue
		var key := parts[0]
		var value := parts[1]
		match key:
			"city_id": city_id = value
			"origin_lat": origin_lat = value.to_float()
			"origin_lon": origin_lon = value.to_float()
			"width": width_m = value.to_int()
			"length": length_m = value.to_int()
			"display_name": display_name = value


func _initialize() -> void:
	_parse_args()
	print("=== config: city_id=", city_id, " origin=(", origin_lat, ",", origin_lon, ") size=", width_m, "x", length_m, " ===")

	var osm_path := "res://maps/%s/%s_osm_3d.geojson" % [city_id, city_id]
	var boundaries_path := "res://maps/%s/%s_boundaries_3d.geojson" % [city_id, city_id]
	var terrain_dir := "res://maps/%s/terrain3d" % city_id
	var scene_path := "res://scenes/races/%s.tscn" % city_id

	print("=== [1] loading base scene (orsay.tscn) ===")
	var base_scene: PackedScene = load("res://scenes/races/orsay.tscn")
	var root: Node3D = base_scene.instantiate()
	get_root().add_child(root)
	root.name = display_name

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

	print("=== [3] rewiring MapDataLoader for ", display_name, " ===")
	loader.osm_data_path = osm_path
	loader.boundaries_data_path = boundaries_path
	loader.latitude_origin = str(origin_lat)
	loader.longitude_origin = str(origin_lon)
	loader.elevation_origin = "0.0"
	loader.width_meters = width_m
	loader.length_meters = length_m

	print("=== [4] resetting terrain to flat (sized to actually cover the loaded data) ===")
	DirAccess.make_dir_recursive_absolute(terrain_dir)
	terrain.data_directory = terrain_dir
	terrain.vertex_spacing = 3.0
	for region in terrain.data.get_regions_active():
		terrain.data.remove_region(region, false)

	var bounds := _compute_world_bounds(osm_path, boundaries_path, width_m)
	var margin := 200.0
	var min_x: float = bounds[0] - margin
	var max_x: float = bounds[1] + margin
	var min_z: float = bounds[2] - margin
	var max_z: float = bounds[3] + margin
	var span_x := max_x - min_x
	var span_z := max_z - min_z
	var px_x := int(ceil(span_x / terrain.vertex_spacing))
	var px_z := int(ceil(span_z / terrain.vertex_spacing))
	print("terrain world bounds: x=[", min_x, ",", max_x, "] z=[", min_z, ",", max_z, "] -> image ", px_x, "x", px_z)

	var img := Image.create_empty(px_x, px_z, false, Image.FORMAT_RF)
	img.fill(Color(0.0, 0.0, 0.0, 0.0))
	var imgs: Array[Image] = []
	imgs.resize(3)
	imgs[0] = img # TYPE_HEIGHT
	terrain.data.import_images(imgs, Vector3(min_x, 0, min_z), 0.0, 1.0)
	terrain.data.save_directory(terrain_dir)
	print("terrain regions active: ", terrain.data.get_regions_active().size())
	await process_frame
	await process_frame

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
	print("roads done after ", waited, " physics ticks. can_build_roads=", osm_gen._can_build_roads)

	print("=== [7] generating buildings ===")
	osm_gen.reload_action(holder, 1) # ReloadKind.BUILDINGS
	await process_frame
	await process_frame

	print("=== [8] clearing stale Orsay-specific path/walls/jumps/arrows and building a real RacePath ===")
	await _rebuild_race_path(root, osm_path, width_m, bounds)

	print("=== [9] fixing node ownership ===")
	_fix_owner(root, root)

	print("=== [10] saving scene ===")
	DirAccess.make_dir_recursive_absolute("res://scenes/races")
	var packed := PackedScene.new()
	var err := packed.pack(root)
	print("pack error: ", err)
	var save_err := ResourceSaver.save(packed, scene_path)
	print("save error: ", save_err)

	print("=== DONE ===")
	quit()


const _GEOM_DEPTH := {
	"Point": 0, "LineString": 1, "MultiPoint": 1,
	"Polygon": 2, "MultiLineString": 2, "MultiPolygon": 3,
}

func _walk_bounds(coords, depth: int, width_m: int, bounds: Array) -> void:
	if depth == 0:
		var world_x: float = -coords[0] + width_m
		var world_z: float = coords[2]
		bounds[0] = min(bounds[0], world_x)
		bounds[1] = max(bounds[1], world_x)
		bounds[2] = min(bounds[2], world_z)
		bounds[3] = max(bounds[3], world_z)
	else:
		for c in coords:
			_walk_bounds(c, depth - 1, width_m, bounds)

## Returns [min_x, max_x, min_z, max_z] in world (post-flip) coordinates,
## covering every feature in both the OSM data and the boundaries file.
func _compute_world_bounds(osm_path: String, boundaries_path: String, width_m: int) -> Array:
	var bounds: Array = [INF, -INF, INF, -INF]
	for path in [osm_path, boundaries_path]:
		var file := FileAccess.open(path, FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		file.close()
		for f in data.features:
			var geom_type: String = f.geometry.type
			if not _GEOM_DEPTH.has(geom_type):
				continue
			var props: Dictionary = f.get("properties", {})
			# Size the terrain to the intended play area (the boundary
			# polygons) only, not the full OSM data — some matched ways
			# extend far past the query bbox (they just clip a corner),
			# which would blow the terrain image up to an unreasonable size.
			if not props.has("osk_boundary_type"):
				continue
			_walk_bounds(f.geometry.coordinates, _GEOM_DEPTH[geom_type], width_m, bounds)
	return bounds

## Picks the longest road (by preferred highway class) whose points stay
## entirely within [min_x,max_x]x[min_z,max_z] (world space, post-flip) —
## some matched ways extend far past the query bbox (they just clip a
## corner), which would place the race path/spawn point outside the terrain.
func _pick_best_road_points(osm_path: String, width_m: int, bounds: Array) -> Array:
	var file := FileAccess.open(osm_path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	var min_x: float = bounds[0]
	var max_x: float = bounds[1]
	var min_z: float = bounds[2]
	var max_z: float = bounds[3]
	var best: Array = []
	var priority := ["primary", "secondary", "tertiary", "residential", "unclassified"]
	for wanted in priority:
		for f in data.features:
			var props: Dictionary = f.properties
			if props.get("highway") != wanted or f.geometry.type != "LineString":
				continue
			var coords: Array = f.geometry.coordinates
			var in_bounds := true
			for c in coords:
				var wx: float = -c[0] + width_m
				var wz: float = c[2]
				if wx < min_x or wx > max_x or wz < min_z or wz > max_z:
					in_bounds = false
					break
			if in_bounds and coords.size() > best.size():
				best = coords
		if best.size() >= 4:
			break
	return best

func _rebuild_race_path(root: Node3D, osm_path: String, width_m: int, bounds: Array) -> void:
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

	var raw_points := _pick_best_road_points(osm_path, width_m, bounds)
	print("race path source points: ", raw_points.size())
	if raw_points.size() < 2:
		push_error("No usable road found for race path; leaving RacePath empty.")
		return

	# world x is mirrored: world_x = width_meters - raw_x (matches osm_data_generator.gd)
	var world_points: Array[Vector3] = []
	for c in raw_points:
		world_points.append(Vector3(-c[0] + width_m, 2.0, c[2]))

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
