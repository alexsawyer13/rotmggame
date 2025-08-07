package game

import ma "vendor:miniaudio"

AudioContext :: struct {
	ctx : ma.context_type,
}

make_audio :: proc() -> bool {
	if ma.context_init(nil, 0, nil, &g_audio.ctx) != .SUCCESS {
		return false
	}

//	ma.context_get_devices(&g_audio.ctx, )

	return true
}


delete_audio :: proc() {

}
