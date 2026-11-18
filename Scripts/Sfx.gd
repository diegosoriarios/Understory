extends RefCounted

## Fire-and-forget sound helper that works whether or not the Sound autoload
## identifier is available (e.g. scripts compiled with `--script`).


static func play(sound: String, pitch := 1.0, volume_db := 0.0) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var bus: Variant = tree.root.get_node_or_null("Sound")
	if bus:
		bus.play(sound, pitch, volume_db)
