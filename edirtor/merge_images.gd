@tool
extends EditorScript

func _run():
	var editor = get_editor_interface()
	var paths = editor.get_selected_paths()
	if paths.size() == 2:
		var image1 = Image.new()
		image1.load(ProjectSettings.globalize_path(paths[0]))
		var image2 = Image.new()
		image2.load(ProjectSettings.globalize_path(paths[1]))
		image1.blend_rect(image2, Rect2i(Vector2i(0, 0), image1.get_size()), Vector2i(0, 0))
		image1.save_png("res://tiles/bank/bank-.png")
