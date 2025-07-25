package game

import "core:time"

CooldownTimer :: struct {
	last_tick  : time.Time,
	cooldown_s : i32,
}

cooldown_tick :: proc(timer : CooldownTimer) {

}
