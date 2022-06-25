extends Node

class_name Vault

var _vault : Array = []
var _vault_size : int = NetworkConfig.DEFAULT_VAULT_SIZE

func get_by_id(id : String) -> Snapshot:
	for snapshot in _vault:
		if(snapshot.id == id):
			return snapshot

	push_error("Snapshot with id %s not found in vault" % id)
	return null

func clear() -> void:
	_vault = []

func get_latest_snapshot() -> Snapshot:
	return _vault[_vault.size() - 1]

func get_surrounding_snapshots(time : int) -> Array:
	var sorted_vault = _vault.sort_custom(SnapshotSorter, "sort")
	for i in len(sorted_vault):
		var before_snapshot = null
		if i > 0:
			before_snapshot = sorted_vault[i - 1]
		var snapshot = sorted_vault[i]
		if(snapshot.time == time):
			return [snapshot, snapshot] #TODO: maybe change this to be more understandable
		else:
			return [before_snapshot, snapshot]
	
	return [sorted_vault[sorted_vault.size() - 1], null]
			

func get_closest_snapshot(time: int) -> Snapshot:
	var sorted_vault = _vault.sort_custom(SnapshotSorter, "sort")
	for i in len(sorted_vault):
		var before_snapshot = null
		if i > 0:
			before_snapshot = sorted_vault[i - 1]
		var snapshot = sorted_vault[i]
		if(snapshot.time == time):
			return snapshot
		else:
			if time - before_snapshot.time <= snapshot.time:
				return before_snapshot
			else:
				return snapshot
	
	return sorted_vault[sorted_vault.size() - 1]

func add(snapshot : Snapshot) -> void:
	_vault.append(snapshot)
	var sorted_vault = _vault.sort_custom(SnapshotSorter, "sort")
	if sorted_vault.size() > _vault_size:
		_vault = sorted_vault.pop_front()

func size() -> int:
	return _vault.size()

func set_max_size(vault_size : int) -> void:
	_vault_size = vault_size

func max_size() -> int:
	return _vault_size
