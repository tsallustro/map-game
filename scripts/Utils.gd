class_name Utils

static func get_gradient_value_ryg(value : int, min_value : int, max_value : int) -> Color:
	if min_value == max_value:
		return Color.YELLOW

	var t := float(value - min_value) / float(max_value - min_value)
	t = clamp(t, 0.0, 1.0)

	if t <= 0.5:
		# Red → Yellow
		return Color.RED.lerp(Color.YELLOW, t / 0.5)
	else:
		# Yellow → Green
		return Color.YELLOW.lerp(Color.GREEN, (t - 0.5) / 0.5)
