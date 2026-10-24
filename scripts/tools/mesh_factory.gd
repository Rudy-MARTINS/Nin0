@tool
class_name MeshFactory
extends RefCounted
## Génération de maillages simples et arrondis (boîtes biseautées, tubes, feuilles).
## Évite l'aspect « blocs de test » sans dépendre d'un logiciel de modélisation.
## Les maillages identiques sont mis en cache et partagés.

static var _cache := {}


## Boîte aux arêtes arrondies. `radius` est limité à la moitié de la plus petite dimension.
static func rounded_box(size: Vector3, radius: float, steps := 3) -> ArrayMesh:
	var half := size * 0.5
	radius = clampf(radius, 0.0005, minf(half.x, minf(half.y, half.z)))
	var key := "rbox:%s:%.4f:%d" % [size, radius, steps]
	if _cache.has(key):
		return _cache[key]

	var inner := half - Vector3.ONE * radius
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	# Chaque face : normale, axe U, axe V.
	var faces := [
		[Vector3.RIGHT, Vector3.BACK, Vector3.UP],
		[Vector3.LEFT, Vector3.FORWARD, Vector3.UP],
		[Vector3.UP, Vector3.RIGHT, Vector3.FORWARD],
		[Vector3.DOWN, Vector3.RIGHT, Vector3.BACK],
		[Vector3.BACK, Vector3.LEFT, Vector3.UP],
		[Vector3.FORWARD, Vector3.RIGHT, Vector3.UP],
	]
	for face in faces:
		var normal: Vector3 = face[0]
		var u_axis: Vector3 = face[1]
		var v_axis: Vector3 = face[2]
		var u_half := absf(u_axis.dot(half))
		var v_half := absf(v_axis.dot(half))
		var n_half := absf(normal.dot(half))
		var u_samples := _bevel_samples(u_half, radius, steps)
		var v_samples := _bevel_samples(v_half, radius, steps)
		var base := vertices.size()
		for v in v_samples:
			for u in u_samples:
				var p: Vector3 = normal * n_half + u_axis * u + v_axis * v
				var clamped := p.clamp(-inner, inner)
				var dir := (p - clamped).normalized()
				vertices.append(clamped + dir * radius)
				normals.append(dir)
				uvs.append(Vector2(u, -v))
		var row := u_samples.size()
		# Godot : faces avant en ordre horaire (produit vectoriel opposé à la normale).
		var flip := v_axis.cross(u_axis).dot(normal) > 0.0
		for j in v_samples.size() - 1:
			for i in row - 1:
				var a := base + j * row + i
				var b := a + 1
				var c := a + row
				var d := c + 1
				if flip:
					indices.append_array([a, b, c, b, d, c])
				else:
					indices.append_array([a, c, b, b, c, d])

	var mesh := _make_mesh(vertices, normals, uvs, indices)
	_cache[key] = mesh
	return mesh


static func _bevel_samples(half: float, radius: float, steps: int) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	for i in steps + 1:
		samples.append(-half + radius * (1.0 - cos(PI * 0.5 * i / steps)))
	for i in steps + 1:
		samples.append(half - radius * (1.0 - sin(PI * 0.5 * i / steps)))
	return samples


## Tube passant par une suite de points (câbles). Pas de mise en cache.
static func tube(points: PackedVector3Array, radius: float, sides := 6) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var count := points.size()
	if count < 2:
		return ArrayMesh.new()
	var length := 0.0
	var previous_side := Vector3.ZERO
	for i in count:
		var tangent: Vector3
		if i == 0:
			tangent = points[1] - points[0]
		elif i == count - 1:
			tangent = points[i] - points[i - 1]
		else:
			tangent = points[i + 1] - points[i - 1]
		tangent = tangent.normalized()
		if i > 0:
			length += points[i].distance_to(points[i - 1])
		# Repère stable le long du tube.
		var side := previous_side
		if side == Vector3.ZERO or absf(side.dot(tangent)) > 0.99:
			side = tangent.cross(Vector3.UP if absf(tangent.y) < 0.9 else Vector3.RIGHT).normalized()
		side = (side - tangent * side.dot(tangent)).normalized()
		previous_side = side
		var up := tangent.cross(side).normalized()
		for s in sides + 1:
			var angle := TAU * s / sides
			var n := side * cos(angle) + up * sin(angle)
			vertices.append(points[i] + n * radius)
			normals.append(n)
			uvs.append(Vector2(float(s) / sides, length))
	var row := sides + 1
	for i in count - 1:
		for s in sides:
			var a := i * row + s
			var b := a + 1
			var c := a + row
			var d := c + 1
			indices.append_array([a, c, b, b, c, d])
	return _make_mesh(vertices, normals, uvs, indices)


## Surface de révolution autour de l'axe Y. `profile` : points (rayon, hauteur) de bas en haut.
## Dupliquer un point crée une arête vive.
static func lathe(profile: PackedVector2Array, segments := 24) -> ArrayMesh:
	var key := "lathe:%s:%d" % [profile, segments]
	if _cache.has(key):
		return _cache[key]
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var count := profile.size()
	var length := 0.0
	for i in count:
		var normal_2d := Vector2.ZERO
		if i > 0 and profile[i].distance_to(profile[i - 1]) > 0.00001:
			var d := profile[i] - profile[i - 1]
			normal_2d += Vector2(d.y, -d.x).normalized()
		if i < count - 1 and profile[i + 1].distance_to(profile[i]) > 0.00001:
			var d := profile[i + 1] - profile[i]
			normal_2d += Vector2(d.y, -d.x).normalized()
		normal_2d = normal_2d.normalized()
		if i > 0:
			length += profile[i].distance_to(profile[i - 1])
		for s in segments + 1:
			var angle := TAU * s / segments
			var dir := Vector3(cos(angle), 0.0, sin(angle))
			vertices.append(dir * profile[i].x + Vector3.UP * profile[i].y)
			normals.append((dir * normal_2d.x + Vector3.UP * normal_2d.y).normalized())
			uvs.append(Vector2(float(s) / segments, length))
	var row := segments + 1
	for i in count - 1:
		for s in segments:
			var a := i * row + s
			var b := a + 1
			var c := a + row
			var d := c + 1
			indices.append_array([a, b, c, b, d, c])
	var mesh := _make_mesh(vertices, normals, uvs, indices)
	_cache[key] = mesh
	return mesh


## Profil de roue/pneu : cylindre d'axe Y aux bords arrondis (à tourner pour l'axe X).
static func tire_profile(radius: float, width: float, round_radius: float, steps := 4) -> PackedVector2Array:
	var profile := PackedVector2Array([Vector2(0.0, -width * 0.5)])
	var half := width * 0.5
	for i in steps + 1:
		var a := -PI * 0.5 + PI * 0.5 * i / steps
		profile.append(Vector2(radius - round_radius + cos(a) * round_radius, -half + round_radius + sin(a) * round_radius))
	for i in steps + 1:
		var a := PI * 0.5 * i / steps
		profile.append(Vector2(radius - round_radius + cos(a) * round_radius, half - round_radius + sin(a) * round_radius))
	profile.append(Vector2(0.0, half))
	return profile


## Feuille stylisée (losange incurvé à deux faces), pointe vers +Z.
static func leaf(length: float, width: float) -> ArrayMesh:
	var key := "leaf:%.3f:%.3f" % [length, width]
	if _cache.has(key):
		return _cache[key]
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var segments := 6
	for i in segments + 1:
		var t := float(i) / segments
		var w := sin(t * PI) * width * 0.5 * (1.0 - t * 0.3)
		var z := t * length
		var bend := -sin(t * PI * 0.5) * length * 0.15
		for side in [-1.0, 0.0, 1.0]:
			var dip := 0.0 if side == 0.0 else width * 0.12
			vertices.append(Vector3(side * w, bend - dip, z))
			normals.append(Vector3(-side * 0.3, 1.0, 0.0).normalized())
			uvs.append(Vector2(side * 0.5 + 0.5, t))
	for i in segments:
		var a := i * 3
		for k in 2:
			var p := a + k
			indices.append_array([p, p + 1, p + 3, p + 1, p + 4, p + 3])
	var mesh := _make_mesh(vertices, normals, uvs, indices)
	_cache[key] = mesh
	return mesh


static func _make_mesh(vertices: PackedVector3Array, normals: PackedVector3Array,
		uvs: PackedVector2Array, indices: PackedInt32Array) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
