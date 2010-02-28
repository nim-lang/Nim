import cairo

var surface = image_surface_create(FORMAT_ARGB32, 240, 80)
var cr = create(surface)

select_font_face(cr, "serif", FONT_SLANT_NORMAL, 
                              FONT_WEIGHT_BOLD)
set_font_size(cr, 32.0)
set_source_rgb(cr, 0.0, 0.0, 1.0)
move_to(cr, 10.0, 50.0)
show_text(cr, "Hello, world")
destroy(cr)
discard write_to_png(surface, "hello.png")
destroy(surface)

