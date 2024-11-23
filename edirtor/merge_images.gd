@tool
extends EditorScript

func get_combination(n : int, src : Array, got : Array, all : Array):
	if n == 0:
		if !got.is_empty():
			all.append(got)
		return
	for j in src.size():
		get_combination(n - 1, src.slice(j + 1), got + [src[j]], all)

func get_combinations(array : Array, m : int):
	var all = []
	for i in range(m, array.size()):
		get_combination(i, array, [], all)
	all.append(array)
	return all

func parent_path(path : String):
	return path.substr(0, path.rfind("/"))

func merge_images(path : String, files : Array, save_name : String):
	var final_image = Image.new()
	final_image.load(ProjectSettings.globalize_path(path + "/" + files[0]))
	for i in range(1, files.size()):
		var image = Image.new()
		image.load(ProjectSettings.globalize_path(path + "/" + files[i]))
		final_image.blend_rect(image, Rect2i(Vector2i(0, 0), final_image.get_size()), Vector2i(0, 0))
	final_image.save_png(path + "/" + save_name)

func _run():
	var editor = get_editor_interface()
	var paths = editor.get_selected_paths()
	if paths.size() == 1:
		var path = paths[0]
		var base_tiles = []
		if DirAccess.dir_exists_absolute(path):
			var files = DirAccess.get_files_at(path)
			for f in files:
				if f.ends_with(".png"):
					base_tiles.append(f)
		if base_tiles.size() == 6:
			var combs = get_combinations(base_tiles, 2)
			for comb in combs:
				var fn = ""
				for f in comb:
					if !fn.is_empty():
						fn += "_"
					fn += f.substr(0, f.rfind("."))
				fn += ".png"
				merge_images(path, comb, fn)
	elif paths.size() == 2:
		merge_images(parent_path(paths[0]), paths, "merged.png")
