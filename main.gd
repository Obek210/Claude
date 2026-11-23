extends Node2D

# ==============================================================================
# 1. KONFIGURATSIYA VA DOIMIYLAR
# ==============================================================================
const GAME_TITLE: String = "SHADOW DUEL: GOTHIC ARENA"
const SCREEN_W: float = 1280.0
const SCREEN_H: float = 720.0
const GROUND_Y: float = 610.0
const GRAVITY: float = 1950.0
const JUMP_VELOCITY: float = -760.0

# Agar qora siluet kerak bo'lsa true, rangli ko'rinish uchun false
const SHADOW_SILHOUETTE_MODE: bool = false

# Quvvat (energiya) tezliklari (bir soniyada)
const PASSIVE_ENERGY_RATE: float = 12.0
const FAST_CHARGE_ENERGY_RATE: float = 55.0

const CHAR_COUNT: int = 12
const STAGE_COUNT: int = 3
const ROUNDS_TO_WIN: int = 2
const MAX_ROUNDS: int = 3
const SAVE_PATH: String = "user://save.cfg"

# Personajlar nomlari inglizcha
const CHAR_NAMES: Array[String] = [
	"Shadow Blade", "Neon Gunner", "Steam Forge", "Forest Druid",
	"Cyber Samurai", "Abyss Pirate", "Chrono Assassin", "Lava Brute",
	"Plague Alchemist", "Solar Monk", "Iron Juggernaut", "Void Stalker"
]

const CHAR_PRICES: Array[int] = [
	0, 150, 250, 300,
	400, 500, 650, 800,
	950, 1100, 1300, 1500
]

# Arenalar nomlari inglizcha
const STAGE_NAMES: Array[String] = [
	"Gothic Cathedral", "Cursed Graveyard", "Eclipse Citadel"
]

# ==============================================================================
# 2. HOLATLAR VA O'ZGARUVCHILAR
# ==============================================================================
enum GameState {
	SPLASH,
	MAIN_MENU,
	CHAR_SELECT,
	STAGE_SELECT,
	SETTINGS,
	COUNTDOWN,
	FIGHTING,
	PAUSED,
	ROUND_TRANSITION,
	MATCH_OVER
}

enum AIState {
	IDLE_WAIT,
	APPROACH,
	RETREAT,
	CHARGE,
	BLOCK,
	DODGE,
	JUMP_AI,
	ATTACK,
	KICK,
	SPECIAL
}

var current_state: GameState = GameState.SPLASH
var state_before_pause: GameState = GameState.FIGHTING
var splash_timer: float = 1.6

var coins: int = 500
var unlocked_chars: Array[bool] = [
	true, false, false, false,
	false, false, false, false,
	false, false, false, false
]

var selected_player_idx: int = 0
var selected_enemy_idx: int = 1
var selected_stage_idx: int = 0

var music_enabled: bool = true
var sfx_enabled: bool = true
var difficulty: int = 1  # 0: Oson, 1: O'rta, 2: Qiyin

# Best of 3 Raund holati (bitta doimiy raqib barcha raundlarda qatnashadi)
var current_round: int = 1
var p1_round_wins: int = 0
var p2_round_wins: int = 0
var round_history: Array[String] = []

var countdown_timer: float = 3.0
var countdown_text: String = "3"
var round_transition_timer: float = 0.0
var round_timer: float = 99.0
var hitstop_timer: float = 0.0
var shake_timer: float = 0.0
var shake_intensity: float = 0.0
var match_result_text: String = ""

# Zarba va slash effektlari: har bir element [pos: Vector2, timer: float, max_time: float, is_special: bool, angle: float]
var hit_effects: Array = []

# Ekrandagi joystik va tugmalar holati
var touch_move_dir: float = 0.0
var touch_block_held: bool = false
var touch_charge_held: bool = false
var touch_jump_queued: bool = false
var touch_punch_queued: bool = false
var touch_kick_queued: bool = false
var touch_special_queued: bool = false
var touch_dodge_queued: bool = false

# O'yinchi (Player 1)
var p1_pos: Vector2 = Vector2(320.0, GROUND_Y)
var p1_vel_y: float = 0.0
var p1_hp: float = 100.0
var p1_max_hp: float = 100.0
var p1_energy: float = 0.0
var p1_max_energy: float = 100.0
var p1_facing: int = 1
var p1_action: String = "IDLE"
var p1_action_timer: float = 0.0
var p1_cooldown: float = 0.0
var p1_anim_time: float = 0.0
var p1_is_charging: bool = false
var p1_is_dodging: bool = false
var p1_is_blocking: bool = false

# Raqib (AI Enemy 2 — butun match davomida o'zgarmaydi)
var p2_pos: Vector2 = Vector2(960.0, GROUND_Y)
var p2_vel_y: float = 0.0
var p2_hp: float = 100.0
var p2_max_hp: float = 100.0
var p2_energy: float = 0.0
var p2_max_energy: float = 100.0
var p2_facing: int = -1
var p2_action: String = "IDLE"
var p2_action_timer: float = 0.0
var p2_cooldown: float = 0.0
var p2_anim_time: float = 0.0
var p2_ai_state: AIState = AIState.IDLE_WAIT
var p2_ai_timer: float = 0.7
var p2_is_charging: bool = false
var p2_is_dodging: bool = false
var p2_is_blocking: bool = false

# Teksturalar
var char_select_textures: Array[Texture2D] = []
var char_anim_textures: Array[Texture2D] = []
var stage_textures: Array[Texture2D] = []
var _margin_cache: Dictionary = {}
var splash_bg_tex: Texture2D = null
var app_icon_tex: Texture2D = null
var main_menu_bg_tex: Texture2D = null
var char_select_bg_tex: Texture2D = null
var stage_select_bg_tex: Texture2D = null
var settings_bg_tex: Texture2D = null

# UI Tugunlari
var ui_layer: CanvasLayer
var splash_container: Control
var menu_container: Control
var char_select_container: Control
var stage_select_container: Control
var settings_container: Control
var hud_container: Control
var pause_container: Control
var match_over_container: Control

var coins_label: Label
var round_info_label: Label
var round_history_label: Label
var p1_score_below_bar: Label
var p2_score_below_bar: Label
var p1_hp_bar: ProgressBar
var p2_hp_bar: ProgressBar
var p1_energy_bar: ProgressBar
var p2_energy_bar: ProgressBar
var timer_label: Label
var pause_icon_btn: Button
var countdown_label: Label
var p1_state_label: Label
var p2_state_label: Label
var match_over_label: Label

# Ovoz
var bgm_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

# ==============================================================================
# 3. ISHGA TUSHIRISH, SAQLASH, FONNI TOZALASH VA OVOZ
# ==============================================================================
func _ready() -> void:
	randomize()
	_load_save()
	_load_assets()
	_setup_audio()
	_build_ui()
	_switch_state(GameState.SPLASH)

func _load_save() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		coins = int(cfg.get_value("progress", "coins", 500))
		var loaded_unlocked: Variant = cfg.get_value("progress", "unlocked_chars", unlocked_chars)
		if loaded_unlocked is Array and loaded_unlocked.size() == CHAR_COUNT:
			for i in range(CHAR_COUNT):
				unlocked_chars[i] = bool(loaded_unlocked[i])
		unlocked_chars[0] = true
		selected_player_idx = clampi(int(cfg.get_value("progress", "selected_player_idx", 0)), 0, CHAR_COUNT - 1)
		if not unlocked_chars[selected_player_idx]:
			selected_player_idx = 0
		selected_stage_idx = clampi(int(cfg.get_value("progress", "selected_stage_idx", 0)), 0, STAGE_COUNT - 1)
		music_enabled = bool(cfg.get_value("settings", "music_enabled", true))
		sfx_enabled = bool(cfg.get_value("settings", "sfx_enabled", true))
		difficulty = clampi(int(cfg.get_value("settings", "difficulty", 1)), 0, 2)

func _write_save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "coins", coins)
	cfg.set_value("progress", "unlocked_chars", unlocked_chars)
	cfg.set_value("progress", "selected_player_idx", selected_player_idx)
	cfg.set_value("progress", "selected_stage_idx", selected_stage_idx)
	cfg.set_value("settings", "music_enabled", music_enabled)
	cfg.set_value("settings", "sfx_enabled", sfx_enabled)
	cfg.set_value("settings", "difficulty", difficulty)
	cfg.save(SAVE_PATH)

func _load_first_texture(paths: Array[String]) -> Texture2D:
	for p in paths:
		var candidates: Array[String] = [p]
		var fname: String = p.get_file()
		if fname.length() > 0:
			# Android'da fayl nomlari katta-kichik harfga sezgir: Char1.png va char1.png boshqa fayllar
			var cap: String = p.get_base_dir().path_join(fname.substr(0, 1).to_upper() + fname.substr(1))
			if cap != p:
				candidates.append(cap)
		for c in candidates:
			if ResourceLoader.exists(c):
				var res := load(c)
				if res is Texture2D:
					return res
	return null

func _prepare_anim_sheet(tex: Texture2D) -> Texture2D:
	if tex == null:
		return null
	var img := tex.get_image()
	if img == null:
		return tex
	if img.is_compressed():
		img.decompress()
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)

	var w := img.get_width()
	var h := img.get_height()
	var c0 := img.get_pixel(0, 0)
	var c1 := img.get_pixel(maxi(0, w - 1), 0)

	var corner_is_white := (c0.r > 0.92 and c0.g > 0.92 and c0.b > 0.92) or (c1.r > 0.92 and c1.g > 0.92 and c1.b > 0.92)
	var corner_is_black := (c0.r < 0.04 and c0.g < 0.04 and c0.b < 0.04) or (c1.r < 0.04 and c1.g < 0.04 and c1.b < 0.04)

	var white_count := 0
	var black_count := 0
	var sample_step := 4
	for sy in range(0, h, sample_step):
		for sx in range(0, w, sample_step):
			var sp := img.get_pixel(sx, sy)
			if sp.a > 0.1:
				if sp.r > 0.85 and sp.g > 0.85 and sp.b > 0.85:
					white_count += 1
				elif sp.r < 0.08 and sp.g < 0.08 and sp.b < 0.08:
					black_count += 1

	var has_white_blotches := (black_count > white_count * 2) and (white_count > 120)

	for y in range(h):
		for x in range(w):
			var px := img.get_pixel(x, y)
			if px.a <= 0.05:
				img.set_pixel(x, y, Color(0.0, 0.0, 0.0, 0.0))
				continue

			var is_bg := false
			if has_white_blotches and px.r > 0.78 and px.g > 0.78 and px.b > 0.78:
				is_bg = true
			elif corner_is_white and px.r > 0.90 and px.g > 0.90 and px.b > 0.90:
				is_bg = true
			elif (corner_is_black or has_white_blotches) and px.r < 0.05 and px.g < 0.05 and px.b < 0.05:
				is_bg = true

			if is_bg:
				img.set_pixel(x, y, Color(0.0, 0.0, 0.0, 0.0))
			elif SHADOW_SILHOUETTE_MODE:
				img.set_pixel(x, y, Color(0.02, 0.02, 0.03, px.a))

	return ImageTexture.create_from_image(img)

func _load_assets() -> void:
	app_icon_tex = _load_first_texture([
		"res://app_icon.png", "res://app_icon.jpg",
		"res://icon.png", "res://icon.jpg"
	])
	splash_bg_tex = _load_first_texture([
		"res://splash_bg.png", "res://splash_bg.jpg",
		"res://splash_fon.png", "res://splash_fon.jpg"
	])

	char_select_textures.clear()
	char_anim_textures.clear()
	for i in range(1, CHAR_COUNT + 1):
		var sel_raw := _load_first_texture([
			"res://char%d.png" % i,
			"res://char%d.jpg" % i,
			"res://char_%d.png" % i,
			"res://char_%d.jpg" % i,
			"res://char.%d.png" % i,
			"res://char.%d.jpg" % i
		])

		var anim_raw := _load_first_texture([
			"res://char_anim_%d.png" % i,
			"res://char_anim_%d.jpg" % i,
			"res://char.anim.%d.png" % i,
			"res://char.anim.%d.jpg" % i
		])

		var final_sel := sel_raw if sel_raw != null else anim_raw
		var final_anim := anim_raw if anim_raw != null else sel_raw

		char_select_textures.append(final_sel)
		char_anim_textures.append(final_anim)  # fon allaqachon rasmning o'zida olib tashlangan

	stage_textures.clear()
	for i in range(1, STAGE_COUNT + 1):
		stage_textures.append(_load_first_texture([
			"res://stage_%d.png" % i,
			"res://stage_%d.jpg" % i,
			"res://stage%d.png" % i,
			"res://stage%d.jpg" % i
		]))

	main_menu_bg_tex = _load_first_texture([
		"res://main_menu_bg.png", "res://main_menu_bg.jpg",
		"res://main_menyu_fon.png", "res://main_menyu_fon.jpg",
		"res://main menyu fon.png", "res://main menyu fon.jpg"
	])
	char_select_bg_tex = _load_first_texture([
		"res://char_select_bg.png", "res://char_select_bg.jpg",
		"res://character_choose_fon.png", "res://character_choose_fon.jpg",
		"res://character choose fon.png", "res://character choose fon.jpg"
	])
	stage_select_bg_tex = _load_first_texture([
		"res://stage_select_bg.png", "res://stage_select_bg.jpg",
		"res://arena_choose_fon.png", "res://arena_choose_fon.jpg",
		"res://arena choose fon.png", "res://arena choose fon.jpg"
	])
	settings_bg_tex = _load_first_texture([
		"res://settings_bg.png", "res://settings_bg.jpg",
		"res://settings_fon.png", "res://settings_fon.jpg",
		"res://sttings_fon.png", "res://sttings_fon.jpg",
		"res://sttings fon.png", "res://sttings fon.jpg",
		"res://settings fon.png", "res://settings fon.jpg"
	])

func _setup_audio() -> void:
	bgm_player = AudioStreamPlayer.new()
	add_child(bgm_player)
	var stream: AudioStream = null
	if ResourceLoader.exists("res://bgm.ogg"):
		var s := load("res://bgm.ogg")
		if s is AudioStream:
			stream = s
	elif ResourceLoader.exists("res://bgm.mp3"):
		var s := load("res://bgm.mp3")
		if s is AudioStream:
			stream = s

	if stream != null:
		if stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = true
		elif stream is AudioStreamMP3:
			(stream as AudioStreamMP3).loop = true
		bgm_player.stream = stream
		if music_enabled:
			bgm_player.play()

	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)

func _play_tone(freq: float, duration: float = 0.09) -> void:
	if not sfx_enabled or sfx_player == null:
		return
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050.0
	gen.buffer_length = maxf(0.05, duration)
	sfx_player.stream = gen
	sfx_player.play()
	var playback := sfx_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback != null:
		var frames := int(gen.mix_rate * duration)
		for i in range(frames):
			var env := 1.0 - (float(i) / float(maxi(1, frames)))
			var sample := sin(TAU * freq * float(i) / gen.mix_rate) * 0.22 * env
			playback.push_frame(Vector2(sample, sample))

# ==============================================================================
# 4. ASOSIY TSIKL (_process), SPLASH, SHAKE, EFEKTLAR VA PAUZA
# ==============================================================================
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_toggle_pause()

func _toggle_pause() -> void:
	if current_state in [GameState.FIGHTING, GameState.COUNTDOWN]:
		state_before_pause = current_state
		_clear_touch_inputs()
		_switch_state(GameState.PAUSED)
	elif current_state == GameState.PAUSED:
		_switch_state(state_before_pause)

func _clear_touch_inputs() -> void:
	touch_move_dir = 0.0
	touch_block_held = false
	touch_charge_held = false
	touch_jump_queued = false
	touch_punch_queued = false
	touch_kick_queued = false
	touch_special_queued = false
	touch_dodge_queued = false

func _trigger_shake(duration: float, intensity: float) -> void:
	shake_timer = maxf(shake_timer, duration)
	shake_intensity = maxf(shake_intensity, intensity)

func _spawn_hit_effect(pos: Vector2, is_special: bool) -> void:
	var life := 0.28 if is_special else 0.16
	var angle := randf_range(-0.65, 0.65)
	hit_effects.append([pos, life, life, is_special, angle])

func _update_effects(delta: float) -> void:
	if shake_timer > 0.0:
		shake_timer = maxf(0.0, shake_timer - delta)
		if shake_timer <= 0.0:
			shake_intensity = 0.0

	for i in range(hit_effects.size() - 1, -1, -1):
		var eff: Array = hit_effects[i]
		eff[1] = float(eff[1]) - delta
		if float(eff[1]) <= 0.0:
			hit_effects.remove_at(i)

func _process(delta: float) -> void:
	_update_effects(delta)

	if current_state == GameState.SPLASH:
		splash_timer -= delta
		if splash_timer <= 0.0:
			_switch_state(GameState.MAIN_MENU)
		queue_redraw()
		return

	if hitstop_timer > 0.0:
		hitstop_timer = maxf(0.0, hitstop_timer - delta)
		queue_redraw()
		return

	if current_state == GameState.COUNTDOWN:
		_apply_vertical_physics(delta)
		_process_countdown(delta)
	elif current_state == GameState.FIGHTING:
		_process_fighting(delta)
	elif current_state == GameState.ROUND_TRANSITION:
		_apply_vertical_physics(delta)
		_process_round_transition(delta)

	queue_redraw()

func _apply_vertical_physics(delta: float) -> void:
	if p1_pos.y < GROUND_Y or p1_vel_y < 0.0:
		p1_vel_y += GRAVITY * delta
		p1_pos.y += p1_vel_y * delta
		if p1_pos.y >= GROUND_Y:
			p1_pos.y = GROUND_Y
			p1_vel_y = 0.0
			if p1_action == "JUMP":
				p1_action = "IDLE"
	else:
		p1_pos.y = GROUND_Y
		p1_vel_y = 0.0

	if p2_pos.y < GROUND_Y or p2_vel_y < 0.0:
		p2_vel_y += GRAVITY * delta
		p2_pos.y += p2_vel_y * delta
		if p2_pos.y >= GROUND_Y:
			p2_pos.y = GROUND_Y
			p2_vel_y = 0.0
			if p2_action == "JUMP":
				p2_action = "IDLE"
	else:
		p2_pos.y = GROUND_Y
		p2_vel_y = 0.0

func _process_countdown(delta: float) -> void:
	countdown_timer -= delta
	if countdown_timer > 2.0:
		countdown_text = "3"
	elif countdown_timer > 1.0:
		countdown_text = "2"
	elif countdown_timer > 0.0:
		countdown_text = "1"
	elif countdown_timer > -0.65:
		countdown_text = "BOSHLANDI!"
	else:
		countdown_label.visible = false
		_switch_state(GameState.FIGHTING)
		return

	countdown_label.text = countdown_text
	countdown_label.visible = true

func _process_round_transition(delta: float) -> void:
	round_transition_timer -= delta
	if round_transition_timer <= 0.0:
		_setup_round(current_round + 1)

func _process_fighting(delta: float) -> void:
	round_timer = maxf(0.0, round_timer - delta)
	timer_label.text = str(int(ceil(round_timer)))

	if round_timer <= 0.0:
		if p1_hp >= p2_hp:
			_finish_round(true)
		else:
			_finish_round(false)
		return

	p1_facing = 1 if p2_pos.x >= p1_pos.x else -1
	p2_facing = 1 if p1_pos.x >= p2_pos.x else -1

	_update_player(delta)
	_update_enemy_ai(delta)
	_apply_vertical_physics(delta)
	_update_hud()

	if p1_hp <= 0.0:
		p1_action = "DIE"
		_finish_round(false)
	elif p2_hp <= 0.0:
		p2_action = "DIE"
		_finish_round(true)

# ==============================================================================
# 5. O'YINCHI BOSHQARUVI (TEZLASHGAN QUVVAT YIG'ISH TUGMASI BILAN)
# ==============================================================================
func _update_player(delta: float) -> void:
	p1_cooldown = maxf(0.0, p1_cooldown - delta)
	p1_anim_time += delta
	p1_is_charging = false
	p1_is_dodging = false
	p1_is_blocking = false

	var on_ground := p1_pos.y >= GROUND_Y - 0.5
	var want_fast_charge := (Input.is_key_pressed(KEY_C) or Input.is_key_pressed(KEY_SHIFT) or touch_charge_held) and on_ground

	if want_fast_charge:
		p1_energy = minf(p1_max_energy, p1_energy + FAST_CHARGE_ENERGY_RATE * delta)
	else:
		p1_energy = minf(p1_max_energy, p1_energy + PASSIVE_ENERGY_RATE * delta)

	if p1_action_timer > 0.0:
		p1_action_timer -= delta
		if p1_action == "DODGE":
			p1_is_dodging = true
			p1_pos.x -= float(p1_facing) * 390.0 * delta
		elif p1_action_timer <= 0.0:
			p1_action = "JUMP" if not on_ground else "IDLE"
		_clamp_positions()
		return

	if (Input.is_key_pressed(KEY_B) or Input.is_key_pressed(KEY_Q) or touch_block_held) and on_ground:
		p1_is_blocking = true
		p1_action = "BLOCK"
		return

	if want_fast_charge:
		p1_is_charging = true
		p1_action = "CHARGE"
		return

	var want_dodge := Input.is_action_just_pressed("ui_down") or Input.is_key_pressed(KEY_S) or touch_dodge_queued
	touch_dodge_queued = false
	if want_dodge and p1_cooldown <= 0.0 and on_ground:
		p1_action = "DODGE"
		p1_action_timer = 0.28
		p1_cooldown = 0.68
		p1_anim_time = 0.0
		p1_is_dodging = true
		_play_tone(540.0, 0.08)
		return

	var want_jump := Input.is_action_just_pressed("ui_up") or Input.is_key_pressed(KEY_W) or touch_jump_queued
	touch_jump_queued = false
	if want_jump and on_ground:
		p1_vel_y = JUMP_VELOCITY
		p1_action = "JUMP"
		p1_anim_time = 0.0
		_play_tone(460.0, 0.09)

	var want_special := Input.is_key_pressed(KEY_K) or Input.is_key_pressed(KEY_X) or touch_special_queued
	touch_special_queued = false
	if want_special and p1_energy >= p1_max_energy and p1_cooldown <= 0.0:
		p1_energy = 0.0
		p1_action = "SPECIAL"
		p1_action_timer = 0.45
		p1_cooldown = 0.75
		p1_anim_time = 0.0
		_play_tone(210.0, 0.18)
		_apply_hit(true, 30.0, 220.0, true)
		return

	var want_kick := Input.is_key_pressed(KEY_L) or Input.is_key_pressed(KEY_SPACE) or touch_kick_queued
	touch_kick_queued = false
	if want_kick and p1_cooldown <= 0.0:
		p1_action = "KICK"
		p1_action_timer = 0.30
		p1_cooldown = 0.48
		p1_anim_time = 0.0
		_play_tone(290.0, 0.10)
		_apply_hit(true, 16.0, 175.0, false)
		return

	var want_punch := Input.is_key_pressed(KEY_J) or Input.is_key_pressed(KEY_Z) or touch_punch_queued
	touch_punch_queued = false
	if want_punch and p1_cooldown <= 0.0:
		p1_action = "ATTACK"
		p1_action_timer = 0.24
		p1_cooldown = 0.38
		p1_anim_time = 0.0
		_play_tone(350.0, 0.08)
		_apply_hit(true, 12.0, 150.0, false)
		return

	var move_dir := touch_move_dir
	if move_dir == 0.0:
		if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
			move_dir -= 1.0
		if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
			move_dir += 1.0

	if move_dir != 0.0:
		p1_pos.x += move_dir * 270.0 * delta
		if p1_pos.y >= GROUND_Y - 0.5:
			p1_action = "WALK"
	else:
		if p1_pos.y >= GROUND_Y - 0.5 and p1_action != "JUMP":
			p1_action = "IDLE"

	_clamp_positions()

# ==============================================================================
# 6. SHADOW FIGHT USLUBIDAGI RAQIB AI
# ==============================================================================
func _update_enemy_ai(delta: float) -> void:
	p2_cooldown = maxf(0.0, p2_cooldown - delta)
	p2_anim_time += delta
	p2_is_charging = false
	p2_is_dodging = false
	p2_is_blocking = false

	var on_ground := p2_pos.y >= GROUND_Y - 0.5

	if p2_action_timer > 0.0:
		p2_action_timer -= delta
		if p2_action == "DODGE":
			p2_is_dodging = true
			p2_pos.x -= float(p2_facing) * 390.0 * delta
		elif p2_action == "BLOCK":
			p2_is_blocking = true
		elif p2_action_timer <= 0.0:
			p2_action = "JUMP" if not on_ground else "IDLE"
		_clamp_positions()
		return

	var dist: float = absf(p1_pos.x - p2_pos.x)
	p2_ai_timer -= delta

	if p1_action in ["ATTACK", "KICK", "SPECIAL"] and dist < 190.0 and p2_cooldown <= 0.0 and on_ground and p2_ai_state not in [AIState.DODGE, AIState.BLOCK]:
		var react_chance := (0.22 + float(difficulty) * 0.14) * delta * 8.0
		var r := randf()
		if r < react_chance * 0.6:
			_set_ai_state(AIState.DODGE, 0.30)
		elif r < react_chance:
			_set_ai_state(AIState.BLOCK, 0.45)

	if p2_ai_timer <= 0.0:
		_choose_next_ai_decision(dist)

	match p2_ai_state:
		AIState.IDLE_WAIT:
			if on_ground:
				p2_action = "IDLE"

		AIState.APPROACH:
			if dist > 130.0:
				p2_pos.x += float(p2_facing) * 235.0 * delta
				if on_ground:
					p2_action = "WALK"
			else:
				_set_ai_state(AIState.IDLE_WAIT, randf_range(0.35, 0.75))

		AIState.RETREAT:
			p2_pos.x -= float(p2_facing) * 215.0 * delta
			if on_ground:
				p2_action = "WALK"

		AIState.CHARGE:
			if on_ground:
				p2_is_charging = true
				p2_action = "CHARGE"
				p2_energy = minf(p2_max_energy, p2_energy + 45.0 * delta)
			if dist < 155.0 or p2_energy >= p2_max_energy:
				_set_ai_state(AIState.IDLE_WAIT, 0.3)

		AIState.BLOCK:
			if on_ground:
				p2_is_blocking = true
				p2_action = "BLOCK"

		AIState.DODGE:
			if p2_cooldown <= 0.0 and on_ground:
				p2_action = "DODGE"
				p2_action_timer = 0.30
				p2_cooldown = 0.85
				p2_anim_time = 0.0
				p2_is_dodging = true
				_play_tone(510.0, 0.08)
			_set_ai_state(AIState.IDLE_WAIT, 0.4)

		AIState.JUMP_AI:
			if on_ground:
				p2_vel_y = JUMP_VELOCITY
				p2_action = "JUMP"
				p2_anim_time = 0.0
				_play_tone(440.0, 0.09)
			_set_ai_state(AIState.IDLE_WAIT, 0.45)

		AIState.ATTACK:
			if dist <= 155.0 and p2_cooldown <= 0.0:
				p2_action = "ATTACK"
				p2_action_timer = 0.26
				p2_cooldown = 0.65
				p2_anim_time = 0.0
				_play_tone(320.0, 0.08)
				_apply_hit(false, 10.0 + float(difficulty) * 2.0, 155.0, false)
			_set_ai_state(AIState.IDLE_WAIT, randf_range(0.45, 0.95))

		AIState.KICK:
			if dist <= 180.0 and p2_cooldown <= 0.0:
				p2_action = "KICK"
				p2_action_timer = 0.32
				p2_cooldown = 0.75
				p2_anim_time = 0.0
				_play_tone(280.0, 0.10)
				_apply_hit(false, 14.0 + float(difficulty) * 2.0, 180.0, false)
			_set_ai_state(AIState.IDLE_WAIT, randf_range(0.50, 0.95))

		AIState.SPECIAL:
			if p2_energy >= p2_max_energy and dist <= 225.0 and p2_cooldown <= 0.0:
				p2_energy = 0.0
				p2_action = "SPECIAL"
				p2_action_timer = 0.48
				p2_cooldown = 0.95
				p2_anim_time = 0.0
				_play_tone(200.0, 0.18)
				_apply_hit(false, 26.0 + float(difficulty) * 3.0, 225.0, true)
			_set_ai_state(AIState.IDLE_WAIT, 0.6)

	_clamp_positions()

func _choose_next_ai_decision(dist: float) -> void:
	var roll := randf()
	if p2_energy >= p2_max_energy:
		if dist <= 220.0:
			_set_ai_state(AIState.SPECIAL, 0.4)
		else:
			_set_ai_state(AIState.APPROACH, 0.6)
		return

	if dist > 260.0:
		if roll < 0.30:
			_set_ai_state(AIState.CHARGE, randf_range(0.8, 1.4))
		elif roll < 0.55:
			_set_ai_state(AIState.IDLE_WAIT, randf_range(0.5, 1.1))
		elif roll < 0.85:
			_set_ai_state(AIState.APPROACH, randf_range(0.5, 0.9))
		else:
			_set_ai_state(AIState.JUMP_AI, 0.35)
	elif dist > 145.0:
		if roll < 0.32:
			_set_ai_state(AIState.IDLE_WAIT, randf_range(0.5, 1.0))
		elif roll < 0.62:
			_set_ai_state(AIState.APPROACH, randf_range(0.35, 0.65))
		elif roll < 0.77:
			_set_ai_state(AIState.KICK, 0.32)
		elif roll < 0.87:
			_set_ai_state(AIState.JUMP_AI, 0.35)
		elif roll < 0.94:
			_set_ai_state(AIState.RETREAT, randf_range(0.35, 0.6))
		else:
			_set_ai_state(AIState.BLOCK, randf_range(0.35, 0.6))
	else:
		if roll < 0.24:
			_set_ai_state(AIState.IDLE_WAIT, randf_range(0.4, 0.85))
		elif roll < 0.40:
			_set_ai_state(AIState.DODGE, 0.30)
		elif roll < 0.56:
			_set_ai_state(AIState.BLOCK, randf_range(0.35, 0.6))
		elif roll < 0.78:
			_set_ai_state(AIState.KICK, 0.32)
		else:
			_set_ai_state(AIState.ATTACK, 0.28)

func _set_ai_state(new_state: AIState, duration: float) -> void:
	p2_ai_state = new_state
	p2_ai_timer = duration

func _apply_hit(is_p1_attacker: bool, damage: float, hit_range: float, is_special: bool) -> void:
	var dist := absf(p1_pos.x - p2_pos.x)
	if dist > hit_range:
		return

	if is_p1_attacker:
		if p2_is_dodging:
			return
		var final_dmg := damage * (0.25 if p2_is_blocking else 1.0)
		p2_hp = maxf(0.0, p2_hp - final_dmg)
		p1_energy = minf(p1_max_energy, p1_energy + 18.0)
		p2_energy = minf(p2_max_energy, p2_energy + 10.0)
		if not p2_is_blocking:
			p2_action = "HURT"
			p2_action_timer = 0.22
			p2_anim_time = 0.0
		p2_pos.x += float(p1_facing) * (35.0 if is_special else 20.0)
		var hit_pt := Vector2((p1_pos.x + p2_pos.x) * 0.5, p2_pos.y - 125.0)
		_spawn_hit_effect(hit_pt, is_special)
	else:
		if p1_is_dodging:
			return
		var final_dmg := damage * (0.25 if p1_is_blocking else 1.0)
		p1_hp = maxf(0.0, p1_hp - final_dmg)
		p2_energy = minf(p2_max_energy, p2_energy + 18.0)
		p1_energy = minf(p1_max_energy, p1_energy + 10.0)
		if not p1_is_blocking:
			p1_action = "HURT"
			p1_action_timer = 0.22
			p1_anim_time = 0.0
		p1_pos.x += float(p2_facing) * (35.0 if is_special else 20.0)
		var hit_pt := Vector2((p1_pos.x + p2_pos.x) * 0.5, p1_pos.y - 125.0)
		_spawn_hit_effect(hit_pt, is_special)

	if is_special:
		hitstop_timer = 0.055
		_trigger_shake(0.24, 14.0)
	else:
		_trigger_shake(0.11, 6.0)

	_clamp_positions()

func _clamp_positions() -> void:
	p1_pos.x = clampf(p1_pos.x, 120.0, SCREEN_W - 120.0)
	p2_pos.x = clampf(p2_pos.x, 120.0, SCREEN_W - 120.0)
	p1_pos.y = minf(p1_pos.y, GROUND_Y)
	p2_pos.y = minf(p2_pos.y, GROUND_Y)

# ==============================================================================
# 7. AVTOMATIK RAUNDLAR + SHADOW FIGHT 2 (1 / 0) SANASHI
# ==============================================================================
func _start_new_match() -> void:
	_clear_touch_inputs()
	hit_effects.clear()
	shake_timer = 0.0
	var candidates: Array[int] = []
	for i in range(CHAR_COUNT):
		if i != selected_player_idx:
			candidates.append(i)
	selected_enemy_idx = candidates[randi() % candidates.size()]

	current_round = 1
	p1_round_wins = 0
	p2_round_wins = 0
	round_history.clear()
	_setup_round(1)

func _setup_round(round_num: int) -> void:
	_clear_touch_inputs()
	hit_effects.clear()
	current_round = round_num
	p1_pos = Vector2(320.0, GROUND_Y)
	p2_pos = Vector2(960.0, GROUND_Y)
	p1_vel_y = 0.0
	p2_vel_y = 0.0
	p1_hp = p1_max_hp
	p2_hp = p2_max_hp
	p1_energy = 0.0
	p2_energy = 0.0
	p1_action = "IDLE"
	p2_action = "IDLE"
	p1_action_timer = 0.0
	p2_action_timer = 0.0
	p1_anim_time = 0.0
	p2_anim_time = 0.0
	p2_ai_state = AIState.IDLE_WAIT
	p2_ai_timer = 0.65

	round_timer = 99.0
	countdown_timer = 3.0
	countdown_text = "3"
	_update_hud()
	_switch_state(GameState.COUNTDOWN)

func _finish_round(p1_won_round: bool) -> void:
	_clear_touch_inputs()
	if p1_won_round:
		p1_round_wins += 1
		round_history.append("R%d: 1-O'YINCHI" % current_round)
	else:
		p2_round_wins += 1
		round_history.append("R%d: %s" % [current_round, CHAR_NAMES[selected_enemy_idx]])

	_update_hud()

	if p1_round_wins >= ROUNDS_TO_WIN:
		coins += 200
		_write_save()
		match_result_text = "G'ALABA! (+200 TANGA)"
		match_over_label.text = match_result_text
		_switch_state(GameState.MATCH_OVER)
	elif p2_round_wins >= ROUNDS_TO_WIN:
		_write_save()
		match_result_text = "MAG'LUBIYAT — %s" % CHAR_NAMES[selected_enemy_idx]
		match_over_label.text = match_result_text
		_switch_state(GameState.MATCH_OVER)
	else:
		round_transition_timer = 1.35
		_switch_state(GameState.ROUND_TRANSITION)

# ==============================================================================
# 8. CHIZISH (_draw): TO'G'RI KESILGAN 10x9 SPRITESHEET VA QO'LI TUSHGAN IDLE
# ==============================================================================
func _draw() -> void:
	if current_state == GameState.SPLASH:
		_draw_fullscreen_bg(splash_bg_tex, Color(0.04, 0.03, 0.06))
		return

	if current_state == GameState.MAIN_MENU:
		_draw_fullscreen_bg(main_menu_bg_tex, Color(0.07, 0.06, 0.10))
		return
	elif current_state == GameState.CHAR_SELECT:
		_draw_fullscreen_bg(char_select_bg_tex, Color(0.08, 0.06, 0.12))
		return
	elif current_state == GameState.STAGE_SELECT:
		_draw_fullscreen_bg(stage_select_bg_tex, Color(0.06, 0.08, 0.11))
		return
	elif current_state == GameState.SETTINGS:
		_draw_fullscreen_bg(settings_bg_tex, Color(0.07, 0.07, 0.09))
		return

	var shake_offset := Vector2.ZERO
	if shake_timer > 0.0 and shake_intensity > 0.0:
		shake_offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)

	draw_set_transform(shake_offset, 0.0, Vector2.ONE)

	var bg_tex: Texture2D = null
	if selected_stage_idx >= 0 and selected_stage_idx < stage_textures.size():
		bg_tex = stage_textures[selected_stage_idx]

	if bg_tex != null:
		draw_texture_rect(bg_tex, Rect2(Vector2.ZERO, Vector2(SCREEN_W, SCREEN_H)), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, Vector2(SCREEN_W, SCREEN_H)), Color(0.08, 0.07, 0.11))
		draw_rect(Rect2(Vector2(0.0, GROUND_Y), Vector2(SCREEN_W, SCREEN_H - GROUND_Y)), Color(0.04, 0.04, 0.06))

	if current_state in [GameState.COUNTDOWN, GameState.FIGHTING, GameState.PAUSED, GameState.ROUND_TRANSITION, GameState.MATCH_OVER]:
		_draw_fighter_sprite(p1_pos, p1_facing, selected_player_idx, p1_action, p1_anim_time, p1_is_dodging)
		_draw_fighter_sprite(p2_pos, p2_facing, selected_enemy_idx, p2_action, p2_anim_time, p2_is_dodging)
		_draw_hit_effects()

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_hit_effects() -> void:
	for eff in hit_effects:
		var pos: Vector2 = eff[0]
		var t_left: float = float(eff[1])
		var t_max: float = float(eff[2])
		var is_special: bool = bool(eff[3])
		var angle: float = float(eff[4])
		var ratio := clampf(t_left / maxf(0.01, t_max), 0.0, 1.0)

		draw_set_transform(pos, angle, Vector2.ONE)
		if is_special:
			draw_circle(Vector2.ZERO, 52.0 * (1.2 - ratio * 0.4), Color(1.0, 0.45, 0.12, 0.45 * ratio))
			draw_rect(Rect2(Vector2(-85.0, -7.0), Vector2(170.0, 14.0)), Color(1.0, 0.92, 0.55, 0.95 * ratio))
			draw_rect(Rect2(Vector2(-12.0, -65.0), Vector2(24.0, 130.0)), Color(1.0, 0.35, 0.15, 0.85 * ratio))
		else:
			draw_circle(Vector2.ZERO, 26.0 * (1.2 - ratio * 0.3), Color(1.0, 0.85, 0.35, 0.55 * ratio))
			draw_rect(Rect2(Vector2(-48.0, -4.0), Vector2(96.0, 8.0)), Color(1.0, 1.0, 0.85, 0.90 * ratio))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_fullscreen_bg(tex: Texture2D, fallback_color: Color) -> void:
	if tex != null:
		draw_texture_rect(tex, Rect2(Vector2.ZERO, Vector2(SCREEN_W, SCREEN_H)), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, Vector2(SCREEN_W, SCREEN_H)), fallback_color)

func _draw_fighter_sprite(
	pos: Vector2,
	facing: int,
	char_idx: int,
	action: String,
	anim_t: float,
	dodging: bool
) -> void:
	var tex: Texture2D = null
	if char_idx >= 0 and char_idx < char_anim_textures.size():
		tex = char_anim_textures[char_idx]

	var tint := Color.WHITE
	if SHADOW_SILHOUETTE_MODE:
		tint = Color(0.03, 0.03, 0.04, 0.72 if dodging else 1.0)
	else:
		if action == "HURT":
			tint = Color(1.0, 0.55, 0.55, 1.0)
		elif dodging:
			tint = Color(0.85, 0.92, 1.0, 0.78)

	if tex != null:
		var src_rect := _get_sprite_frame_rect(tex, action, anim_t)
		var target_h := 255.0
		var scale_factor := target_h / maxf(1.0, src_rect.size.y)
		var target_w := src_rect.size.x * scale_factor

		draw_set_transform(pos, 0.0, Vector2(float(facing), 1.0))
		var dest_rect := Rect2(Vector2(-target_w * 0.5, -target_h), Vector2(target_w, target_h))
		draw_texture_rect_region(tex, dest_rect, src_rect, tint)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_rect(Rect2(Vector2(pos.x - 35.0, pos.y - 220.0), Vector2(70.0, 220.0)), tint)

# Spritesheet chegaralari oldindan hisoblangan (telefonda har kadrda skanerlash juda sekin)
const SHEET_MARGINS: Dictionary = {
	"Char_anim_1.png": Vector4(241, 76, 29, 14),
	"Char_anim_2.png": Vector4(353, 80, 27, 10),
	"Char_anim_3.png": Vector4(289, 90, 23, 14),
	"Char_anim_4.png": Vector4(239, 76, 15, 14),
	"Char_anim_5.png": Vector4(391, 70, 63, 30),
	"Char_anim_6.png": Vector4(313, 72, 13, 4),
	"Char_anim_7.png": Vector4(313, 70, 31, 14),
	"Char_anim_8.png": Vector4(293, 82, 21, 6),
	"Char_anim_9.png": Vector4(297, 74, 35, 14),
	"Char_anim_10.png": Vector4(267, 76, 21, 10),
	"Char_anim_11.png": Vector4(289, 70, 29, 10),
	"Char_anim_12.png": Vector4(283, 78, 33, 6)
}

# Spritesheetni aniqlab to'g'ri katakchaga kesish (10 ustun x 9 qator)
func _get_sprite_frame_rect(tex: Texture2D, action: String, anim_t: float) -> Rect2:
	var w := float(tex.get_width())
	var h := float(tex.get_height())

	var left_margin := 0.0
	var top_margin := 0.0
	var right_margin := 0.0
	var bottom_margin := 0.0

	var tex_key: int = tex.get_instance_id()
	var cached_margins: Variant = null
	if _margin_cache.has(tex_key):
		cached_margins = _margin_cache[tex_key]
	elif SHEET_MARGINS.has(tex.resource_path.get_file()):
		cached_margins = SHEET_MARGINS[tex.resource_path.get_file()]

	var img: Image = null
	if cached_margins == null:
		img = tex.get_image()
	if img != null and not img.is_empty():
		if img.is_compressed():
			img.decompress()
		if img.get_format() != Image.FORMAT_RGBA8:
			img.convert(Image.FORMAT_RGBA8)

		var iw := img.get_width()
		var ih := img.get_height()
		var min_x := iw
		var max_x := 0
		var min_y := ih
		var max_y := 0
		var found := false

		# Yuqoridagi 'Frame 1 .. Frame 10' sarlavha yozuvi bor-yo'qligini tekshirish uchun yuqori qismni o'tkazib yuborish
		var start_y := int(float(ih) * 0.05)
		for y in range(start_y, ih, 2):
			for x in range(0, iw, 2):
				var c := img.get_pixel(x, y)
				if c.a > 0.25 and (c.r > 0.14 or c.g > 0.14 or c.b > 0.14):
					found = true
					if x < min_x: min_x = x
					if x > max_x: max_x = x
					if y < min_y: min_y = y
					if y > max_y: max_y = y

		if found and max_x > min_x and max_y > min_y:
			left_margin = float(maxi(0, min_x - 3))
			right_margin = float(maxi(0, iw - max_x - 3))
			top_margin = float(maxi(0, min_y - 2))
			bottom_margin = float(maxi(0, ih - max_y - 2))
		_margin_cache[tex_key] = Vector4(left_margin, top_margin, right_margin, bottom_margin)
	elif cached_margins != null:
		var m: Vector4 = cached_margins
		left_margin = m.x
		top_margin = m.y
		right_margin = m.z
		bottom_margin = m.w

	var grid_w := maxf(10.0, w - left_margin - right_margin)
	var grid_h := maxf(10.0, h - top_margin - bottom_margin)
	var cols := 10
	var rows := 9
	var cell_w := grid_w / float(cols)
	var cell_h := grid_h / float(rows)

	var row_idx := 0
	var frame_idx := 0
	match action:
		"IDLE":
			row_idx = 0
			frame_idx = 1
		"WALK":
			row_idx = 1
			frame_idx = int(anim_t * 10.0) % cols
		"DODGE":
			row_idx = 2
			frame_idx = int(anim_t * 14.0) % cols
		"JUMP":
			row_idx = 3
			frame_idx = mini(cols - 1, int(anim_t * 10.0))
		"KICK":
			row_idx = 4
			frame_idx = mini(cols - 1, int(anim_t * 14.0))
		"ATTACK":
			row_idx = 4
			frame_idx = mini(cols - 1, int(anim_t * 15.0))
		"HURT":
			row_idx = 5
			frame_idx = mini(cols - 1, int(anim_t * 12.0))
		"DIE":
			row_idx = 6
			frame_idx = mini(cols - 1, int(anim_t * 10.0))
		"BLOCK":
			row_idx = 7
			frame_idx = mini(cols - 1, int(anim_t * 12.0))
		"CHARGE":
			row_idx = 8
			frame_idx = int(anim_t * 10.0) % cols
		"SPECIAL":
			row_idx = 8
			frame_idx = mini(cols - 1, int(anim_t * 12.0))

	var sx := left_margin + float(frame_idx) * cell_w
	var sy := top_margin + float(row_idx) * cell_h
	return Rect2(Vector2(sx, sy), Vector2(cell_w, cell_h))

# ==============================================================================
# 9. O'ZBEKCHA INTERFEYS, MENYU CHAR1..12 IKONKALARI VA JANG HUD
# ==============================================================================
func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	# --- SPLASH EKRAN ---
	splash_container = Control.new()
	splash_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(splash_container)

	if app_icon_tex != null:
		var splash_icon := TextureRect.new()
		splash_icon.position = Vector2(560, 170)
		splash_icon.size = Vector2(160, 160)
		splash_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		splash_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		splash_icon.texture = app_icon_tex
		splash_container.add_child(splash_icon)

	var splash_title := Label.new()
	splash_title.text = GAME_TITLE
	splash_title.position = Vector2(345, 365)
	splash_title.add_theme_font_size_override("font_size", 42)
	splash_container.add_child(splash_title)

	var splash_sub := Label.new()
	splash_sub.text = "YUKLANMOQDA..."
	splash_sub.position = Vector2(555, 435)
	splash_sub.add_theme_font_size_override("font_size", 22)
	splash_container.add_child(splash_sub)

	# --- ASOSIY MENYU ---
	menu_container = Control.new()
	menu_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(menu_container)

	if app_icon_tex != null:
		var menu_icon := TextureRect.new()
		menu_icon.position = Vector2(590, 28)
		menu_icon.size = Vector2(100, 100)
		menu_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		menu_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		menu_icon.texture = app_icon_tex
		menu_container.add_child(menu_icon)

	var title_lbl := Label.new()
	title_lbl.text = GAME_TITLE
	title_lbl.position = Vector2(355, 138)
	title_lbl.add_theme_font_size_override("font_size", 40)
	menu_container.add_child(title_lbl)

	coins_label = Label.new()
	coins_label.position = Vector2(40, 28)
	coins_label.add_theme_font_size_override("font_size", 24)
	ui_layer.add_child(coins_label)

	var btn_fight := _create_btn("JANGNI BOSHLASH", Vector2(465, 235), Vector2(350, 55))
	btn_fight.pressed.connect(_start_new_match)
	menu_container.add_child(btn_fight)

	var btn_chars := _create_btn("PERSONAJLAR (12 TA)", Vector2(465, 310), Vector2(350, 55))
	btn_chars.pressed.connect(func(): _switch_state(GameState.CHAR_SELECT))
	menu_container.add_child(btn_chars)

	var btn_stages := _create_btn("ARENALAR (3 TA)", Vector2(465, 385), Vector2(350, 55))
	btn_stages.pressed.connect(func(): _switch_state(GameState.STAGE_SELECT))
	menu_container.add_child(btn_stages)

	var btn_settings := _create_btn("SOZLAMALAR", Vector2(465, 460), Vector2(350, 55))
	btn_settings.pressed.connect(func(): _switch_state(GameState.SETTINGS))
	menu_container.add_child(btn_settings)

	# --- PERSONAJ TANLASH (CHAR1..12 RASMLARI BILAN) ---
	char_select_container = Control.new()
	char_select_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(char_select_container)

	var cs_title := Label.new()
	cs_title.text = "PERSONAJNI TANLANG (12)"
	cs_title.position = Vector2(475, 28)
	cs_title.add_theme_font_size_override("font_size", 32)
	char_select_container.add_child(cs_title)

	for i in range(CHAR_COUNT):
		var col := i % 4
		var row := int(i / 4)
		var bx := 140.0 + float(col) * 255.0
		var by := 90.0 + float(row) * 155.0

		var btn := _create_btn("", Vector2(bx, by), Vector2(235, 138))
		btn.name = "CharBtn_%d" % i
		btn.pressed.connect(_on_char_btn_pressed.bind(i))
		char_select_container.add_child(btn)

		var icon := TextureRect.new()
		icon.name = "CharIcon_%d" % i
		icon.position = Vector2(bx + 8.0, by + 8.0)
		icon.size = Vector2(82.0, 122.0)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if i < char_select_textures.size() and char_select_textures[i] != null:
			icon.texture = char_select_textures[i]
		char_select_container.add_child(icon)

	var cs_back := _create_btn("ASOSIY MENYU", Vector2(520, 625), Vector2(240, 48))
	cs_back.pressed.connect(func(): _switch_state(GameState.MAIN_MENU))
	char_select_container.add_child(cs_back)

	# --- ARENA TANLASH ---
	stage_select_container = Control.new()
	stage_select_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(stage_select_container)

	var ss_title := Label.new()
	ss_title.text = "ARENANI TANLANG"
	ss_title.position = Vector2(510, 45)
	ss_title.add_theme_font_size_override("font_size", 32)
	stage_select_container.add_child(ss_title)

	for i in range(STAGE_COUNT):
		var sy := 130.0 + float(i) * 135.0
		var btn := _create_btn("   " + STAGE_NAMES[i], Vector2(430, sy), Vector2(420, 110))
		btn.pressed.connect(func():
			selected_stage_idx = i
			_write_save()
			_switch_state(GameState.MAIN_MENU)
		)
		stage_select_container.add_child(btn)

		var thumb := TextureRect.new()
		thumb.position = Vector2(442, sy + 12.0)
		thumb.size = Vector2(130.0, 86.0)
		thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if i < stage_textures.size() and stage_textures[i] != null:
			thumb.texture = stage_textures[i]
		stage_select_container.add_child(thumb)

	var ss_back := _create_btn("ASOSIY MENYU", Vector2(520, 570), Vector2(240, 50))
	ss_back.pressed.connect(func(): _switch_state(GameState.MAIN_MENU))
	stage_select_container.add_child(ss_back)

	# --- SOZLAMALAR ---
	settings_container = Control.new()
	settings_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(settings_container)

	var st_title := Label.new()
	st_title.text = "SOZLAMALAR"
	st_title.position = Vector2(540, 80)
	st_title.add_theme_font_size_override("font_size", 32)
	settings_container.add_child(st_title)

	var btn_music := _create_btn("MUSIQA: " + ("YONIQ" if music_enabled else "O'CHIQ"), Vector2(480, 190), Vector2(320, 55))
	btn_music.pressed.connect(func():
		music_enabled = not music_enabled
		btn_music.text = "MUSIQA: " + ("YONIQ" if music_enabled else "O'CHIQ")
		if bgm_player.stream != null:
			if music_enabled:
				bgm_player.play()
			else:
				bgm_player.stop()
		_write_save()
	)
	settings_container.add_child(btn_music)

	var btn_sfx := _create_btn("TOVUSHLAR: " + ("YONIQ" if sfx_enabled else "O'CHIQ"), Vector2(480, 270), Vector2(320, 55))
	btn_sfx.pressed.connect(func():
		sfx_enabled = not sfx_enabled
		btn_sfx.text = "TOVUSHLAR: " + ("YONIQ" if sfx_enabled else "O'CHIQ")
		_write_save()
	)
	settings_container.add_child(btn_sfx)

	var diff_names: Array[String] = ["OSON", "O'RTA", "QIYIN"]
	var btn_diff := _create_btn("RAQIB DARAJASI: " + diff_names[difficulty], Vector2(480, 350), Vector2(320, 55))
	btn_diff.pressed.connect(func():
		difficulty = (difficulty + 1) % 3
		btn_diff.text = "RAQIB DARAJASI: " + diff_names[difficulty]
		_write_save()
	)
	settings_container.add_child(btn_diff)

	var st_back := _create_btn("ASOSIY MENYU", Vector2(520, 480), Vector2(240, 50))
	st_back.pressed.connect(func(): _switch_state(GameState.MAIN_MENU))
	settings_container.add_child(st_back)

	# --- JANG HUD INTERFEYSI ---
	hud_container = Control.new()
	hud_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(hud_container)

	round_info_label = Label.new()
	round_info_label.position = Vector2(580, 10)
	round_info_label.add_theme_font_size_override("font_size", 20)
	hud_container.add_child(round_info_label)

	p1_hp_bar = ProgressBar.new()
	p1_hp_bar.position = Vector2(60, 42)
	p1_hp_bar.size = Vector2(460, 26)
	p1_hp_bar.value = 100.0
	hud_container.add_child(p1_hp_bar)

	p2_hp_bar = ProgressBar.new()
	p2_hp_bar.position = Vector2(760, 42)
	p2_hp_bar.size = Vector2(460, 26)
	p2_hp_bar.value = 100.0
	hud_container.add_child(p2_hp_bar)

	timer_label = Label.new()
	timer_label.text = "99"
	timer_label.position = Vector2(616, 36)
	timer_label.add_theme_font_size_override("font_size", 32)
	hud_container.add_child(timer_label)

	pause_icon_btn = _create_btn("||", Vector2(614, 74), Vector2(52, 34))
	pause_icon_btn.pressed.connect(_toggle_pause)
	hud_container.add_child(pause_icon_btn)

	p1_score_below_bar = Label.new()
	p1_score_below_bar.position = Vector2(60, 72)
	p1_score_below_bar.add_theme_font_size_override("font_size", 22)
	hud_container.add_child(p1_score_below_bar)

	p2_score_below_bar = Label.new()
	p2_score_below_bar.position = Vector2(1175, 72)
	p2_score_below_bar.add_theme_font_size_override("font_size", 22)
	hud_container.add_child(p2_score_below_bar)

	p1_energy_bar = ProgressBar.new()
	p1_energy_bar.position = Vector2(60, 102)
	p1_energy_bar.size = Vector2(260, 14)
	p1_energy_bar.value = 0.0
	hud_container.add_child(p1_energy_bar)

	p2_energy_bar = ProgressBar.new()
	p2_energy_bar.position = Vector2(960, 102)
	p2_energy_bar.size = Vector2(260, 14)
	p2_energy_bar.value = 0.0
	hud_container.add_child(p2_energy_bar)

	round_history_label = Label.new()
	round_history_label.position = Vector2(520, 112)
	round_history_label.add_theme_font_size_override("font_size", 16)
	hud_container.add_child(round_history_label)

	p1_state_label = Label.new()
	p1_state_label.position = Vector2(60, 122)
	hud_container.add_child(p1_state_label)

	p2_state_label = Label.new()
	p2_state_label.position = Vector2(1010, 122)
	hud_container.add_child(p2_state_label)

	countdown_label = Label.new()
	countdown_label.text = "3"
	countdown_label.position = Vector2(540, 240)
	countdown_label.add_theme_font_size_override("font_size", 84)
	hud_container.add_child(countdown_label)

	# --- CHAP PASTDA JOYSTIK (< CHAP / O'NG >) ---
	var btn_left := _create_btn("< CHAP", Vector2(45, 525), Vector2(105, 85))
	btn_left.button_down.connect(func(): touch_move_dir = -1.0)
	btn_left.button_up.connect(func(): if touch_move_dir < 0.0: touch_move_dir = 0.0)
	hud_container.add_child(btn_left)

	var btn_right := _create_btn("O'NG >", Vector2(165, 525), Vector2(105, 85))
	btn_right.button_down.connect(func(): touch_move_dir = 1.0)
	btn_right.button_up.connect(func(): if touch_move_dir > 0.0: touch_move_dir = 0.0)
	hud_container.add_child(btn_right)

	# --- O'NG PASTDA HARAKAT TUGMALARI (TEZLASHGAN QUVVAT YIG'ISH BILAN) ---
	var btn_punch := _create_btn("ZARBA", Vector2(835, 465), Vector2(104, 66))
	btn_punch.pressed.connect(func(): touch_punch_queued = true)
	hud_container.add_child(btn_punch)

	var btn_kick := _create_btn("TEPISH", Vector2(946, 465), Vector2(104, 66))
	btn_kick.pressed.connect(func(): touch_kick_queued = true)
	hud_container.add_child(btn_kick)

	var btn_jump := _create_btn("SAKRASH", Vector2(1057, 465), Vector2(104, 66))
	btn_jump.pressed.connect(func(): touch_jump_queued = true)
	hud_container.add_child(btn_jump)

	var btn_special := _create_btn("MAXSUS", Vector2(1168, 465), Vector2(104, 66))
	btn_special.pressed.connect(func(): touch_special_queued = true)
	hud_container.add_child(btn_special)

	var btn_block := _create_btn("BLOK", Vector2(946, 542), Vector2(104, 66))
	btn_block.button_down.connect(func(): touch_block_held = true)
	btn_block.button_up.connect(func(): touch_block_held = false)
	hud_container.add_child(btn_block)

	var btn_dodge := _create_btn("CHAP BER", Vector2(1057, 542), Vector2(104, 66))
	btn_dodge.pressed.connect(func(): touch_dodge_queued = true)
	hud_container.add_child(btn_dodge)

	var btn_charge := _create_btn("QUVVAT YIG'ISH", Vector2(1168, 542), Vector2(104, 66))
	btn_charge.button_down.connect(func(): touch_charge_held = true)
	btn_charge.button_up.connect(func(): touch_charge_held = false)
	hud_container.add_child(btn_charge)

	# --- PAUZA MENYUSI ---
	pause_container = Control.new()
	pause_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(pause_container)

	var pause_lbl := Label.new()
	pause_lbl.text = "PAUZA"
	pause_lbl.position = Vector2(575, 190)
	pause_lbl.add_theme_font_size_override("font_size", 42)
	pause_container.add_child(pause_lbl)

	var btn_resume := _create_btn("DAVOM ETTIRISH", Vector2(500, 275), Vector2(280, 52))
	btn_resume.pressed.connect(func(): _switch_state(state_before_pause))
	pause_container.add_child(btn_resume)

	var btn_pause_menu := _create_btn("ASOSIY MENYU", Vector2(500, 345), Vector2(280, 52))
	btn_pause_menu.pressed.connect(func(): _switch_state(GameState.MAIN_MENU))
	pause_container.add_child(btn_pause_menu)

	# --- MATCH TUGASHI ---
	match_over_container = Control.new()
	match_over_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(match_over_container)

	match_over_label = Label.new()
	match_over_label.position = Vector2(430, 220)
	match_over_label.add_theme_font_size_override("font_size", 38)
	match_over_container.add_child(match_over_label)

	var btn_rematch := _create_btn("QAYTA O'YNASH", Vector2(485, 315), Vector2(310, 55))
	btn_rematch.pressed.connect(_start_new_match)
	match_over_container.add_child(btn_rematch)

	var btn_to_menu := _create_btn("ASOSIY MENYU", Vector2(485, 390), Vector2(310, 55))
	btn_to_menu.pressed.connect(func(): _switch_state(GameState.MAIN_MENU))
	match_over_container.add_child(btn_to_menu)

func _create_btn(txt: String, pos: Vector2, sz: Vector2) -> Button:
	var b := Button.new()
	b.text = txt
	b.position = pos
	b.size = sz
	return b

func _switch_state(new_state: GameState) -> void:
	current_state = new_state
	if new_state == GameState.SPLASH:
		splash_timer = 1.6
	splash_container.visible = (new_state == GameState.SPLASH)
	menu_container.visible = (new_state == GameState.MAIN_MENU)
	char_select_container.visible = (new_state == GameState.CHAR_SELECT)
	stage_select_container.visible = (new_state == GameState.STAGE_SELECT)
	settings_container.visible = (new_state == GameState.SETTINGS)
	hud_container.visible = (new_state in [GameState.COUNTDOWN, GameState.FIGHTING, GameState.PAUSED, GameState.ROUND_TRANSITION, GameState.MATCH_OVER])
	pause_container.visible = (new_state == GameState.PAUSED)
	match_over_container.visible = (new_state == GameState.MATCH_OVER)

	coins_label.visible = (new_state != GameState.SPLASH)
	coins_label.text = "TANGALAR: %d" % coins
	if new_state == GameState.CHAR_SELECT:
		_refresh_char_buttons()

func _refresh_char_buttons() -> void:
	for i in range(CHAR_COUNT):
		var btn := char_select_container.get_node("CharBtn_%d" % i) as Button
		var icon := char_select_container.get_node("CharIcon_%d" % i) as TextureRect
		if i < char_select_textures.size() and char_select_textures[i] != null:
			icon.texture = char_select_textures[i]
		if unlocked_chars[i]:
			var mark := " [TANLANGAN]" if i == selected_player_idx else ""
			btn.text = "      %s%s" % [CHAR_NAMES[i], mark]
		else:
			btn.text = "      %s\n      OLISH: %d" % [CHAR_NAMES[i], CHAR_PRICES[i]]

func _on_char_btn_pressed(idx: int) -> void:
	if unlocked_chars[idx]:
		selected_player_idx = idx
		_write_save()
	else:
		if coins >= CHAR_PRICES[idx]:
			coins -= CHAR_PRICES[idx]
			unlocked_chars[idx] = true
			selected_player_idx = idx
			coins_label.text = "TANGALAR: %d" % coins
			_write_save()
	_refresh_char_buttons()

func _update_hud() -> void:
	p1_hp_bar.value = p1_hp
	p2_hp_bar.value = p2_hp
	p1_energy_bar.value = p1_energy
	p2_energy_bar.value = p2_energy
	p1_state_label.text = "%s [%s]" % [CHAR_NAMES[selected_player_idx], p1_action]
	p2_state_label.text = "%s [%s]" % [CHAR_NAMES[selected_enemy_idx], p2_action]

	round_info_label.text = "RAUND %d" % current_round

	if p1_round_wins > p2_round_wins:
		p1_score_below_bar.text = "1"
		p2_score_below_bar.text = "0"
	elif p2_round_wins > p1_round_wins:
		p1_score_below_bar.text = "0"
		p2_score_below_bar.text = "1"
	else:
		p1_score_below_bar.text = "0"
		p2_score_below_bar.text = "0"

	round_history_label.text = " | ".join(round_history) if round_history.size() > 0 else ""
