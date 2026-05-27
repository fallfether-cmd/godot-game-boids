class_name Stat

var target: float
var value: float
var rate: float

func _init(target:float, value:float, rate:float):
	self.target = target
	self.value = value
	self.rate = rate

func tick(delta:float):
	value = lerp(value, target, delta*rate)
