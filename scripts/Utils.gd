class_name Utils

static func get_gradient_value_ryg(value: int, min_value: int, max_value: int) -> Color:
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

static func get_month_name_from_int(month: int) -> String:
	return [
		"", "January", "February", "March", "April", "May", "June",
		"July", "August", "September", "October", "November", "December"
	][month]

# Returns a positive if date1>date2, negative if date1<date2, or zero if date1=date2
static func compare_date(date1: Dictionary, date2: Dictionary) -> int:
	var d1_unix = Time.get_unix_time_from_datetime_dict(date1)
	var d2_unix = Time.get_unix_time_from_datetime_dict(date2)
	return d1_unix - d2_unix
