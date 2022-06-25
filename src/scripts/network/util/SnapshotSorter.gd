extends Node


class_name SnapshotSorter
static func sort(a, b):
	if a.time < b.time:
		return true
	return false
