# Kyle Senebouttarath
# This an adapted Spring module for Godot from the Roblox Luau Spring module, originally
	# written by Quenty (James Onnen).

@tool
@icon("spring.svg")
class_name Spring
extends Object

var target: float = 0.0
var _time0 = Time.get_unix_time_from_system()
var _position = target
var _velocity = 0.0 * target
var _target = target
var _damper = 1.0
var _speed = 1.0

# ---------------------- METHODS ------------------------ #

func _init(initial: float = 0) -> void:
	_target = initial
	_position = initial
	_velocity = 0.0
	_time0 = Time.get_unix_time_from_system()


func impulse(velocity):
	self._set("velocity", velocity)


func _get(index: StringName) -> Variant:
	match index:
		"position", "p", "value":
			var result = _positionVelocity(Time.get_unix_time_from_system())
			return result[0]
		"velocity", "v":
			var result = _positionVelocity(Time.get_unix_time_from_system())
			return result[1]
		"target", "t":
			return _target
		"damper", "d":
			return _damper
		"speed", "s":
			return _speed
		_:
			return null


func _set(index: StringName, value: Variant) -> bool:
	var now: float = Time.get_unix_time_from_system()
	match index:
		"position", "p", "value":
			var result = _positionVelocity(now)
			_position = value
			_velocity = result[1]
		"velocity", "v":
			var result = _positionVelocity(now)
			_position = result[0]
			_velocity = value
		"target", "t":
			var result = _positionVelocity(now)
			_position = result[0]
			_velocity = result[1]
			_target = value
		"damper", "d":
			var result = _positionVelocity(now)
			_position = result[0]
			_velocity = result[1]
			_damper = clamp(value, 0, 1)
		"speed", "s":
			var result = _positionVelocity(now)
			_position = result[0]
			_velocity = result[1]
			_speed = max(0, value)
		_:
			pass
	_time0 = now
	return true


func _positionVelocity(now):
	var p0 = self._position
	var v0 = self._velocity
	var p1 = self._target
	var d = self._damper
	var s = self._speed

	var t = s*(now - self._time0)
	var d2 = d*d

	var h
	var si
	var co

	if d2 < 1:
		h = sqrt(1 - d2)
		var ep = exp(-d*t)/h
		co = ep * cos(h*t)
		si = ep * sin(h*t)
	elif d2 == 1:
		h = 1
		var ep = exp(-d*t)/h
		co = ep
		si = ep*t
	else:
		h = sqrt(d2 - 1)
		var u = exp((-d + h)*t)/(2*h)
		var v = exp((-d - h)*t)/(2*h)
		co = u + v
		si = u - v

	var a0 = h*co + d*si
	var a1 = 1 - (h*co + d*si)
	var a2 = si/s
	var b0 = -s*si
	var b1 = s*si
	var b2 = h*co - d*si

	return [a0*p0 + a1*p1 + a2*v0, b0*p0 + b1*p1 + b2*v0]





#
#
#func get_pos():
#	return _positionVelocity(Time.get_unix_time_from_system())[0]
#
#
#func get_velo():
#	return _positionVelocity(Time.get_unix_time_from_system())[1]
#
#
## Called when the node enters the scene tree for the first time.
#func _init(initial, speed, damper):
#	target = initial
#	_speed = speed
#	_damper = damper
#
