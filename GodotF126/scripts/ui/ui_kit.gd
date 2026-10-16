class_name UiKit
extends RefCounted
## Ayudantes para armar interfaz por código con el estilo del juego (menús).


static func make_label(text: String, font_size: int, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


## anchors = (left, top, right, bottom); offsets en píxeles, mismo orden.
static func place(control: Control, anchors: Vector4, offsets: Vector4) -> void:
	control.anchor_left = anchors.x
	control.anchor_top = anchors.y
	control.anchor_right = anchors.z
	control.anchor_bottom = anchors.w
	control.offset_left = offsets.x
	control.offset_top = offsets.y
	control.offset_right = offsets.z
	control.offset_bottom = offsets.w


## Botón de menú: fondo oscuro translúcido con borde izquierdo del color `accent`.
static func make_button(text: String, accent: Color, min_size: Vector2 = Vector2(300, 54), font_size: int = 26) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color(0.9, 0.9, 0.92))
	for state in ["font_hover_color", "font_focus_color", "font_pressed_color"]:
		button.add_theme_color_override(state, Color.WHITE)
	apply_button_style(button, accent)
	button.mouse_entered.connect(button.grab_focus)
	return button


static func apply_button_style(button: Button, accent: Color) -> void:
	button.add_theme_stylebox_override("normal", button_style(Color(0, 0, 0, 0.45), Color(accent, 0.35), 6, 0))
	button.add_theme_stylebox_override("hover", button_style(Color(0, 0, 0, 0.6), accent, 6, 2))
	button.add_theme_stylebox_override("focus", button_style(Color(0, 0, 0, 0.6), accent, 6, 2))
	button.add_theme_stylebox_override("pressed", button_style(accent.darkened(0.5), accent, 6, 2))


static func button_style(background: Color, accent: Color, left_border: int, border: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = accent
	style.border_width_left = maxi(left_border, border)
	style.border_width_top = border
	style.border_width_right = border
	style.border_width_bottom = border
	style.content_margin_left = 22
	style.content_margin_right = 22
	return style


static func number_text(value) -> String:
	return str(int(value)) if value is float else str(value)
