cmake_minimum_required(VERSION 3.13.4)
project(doom)

set(CMAKE_C_FLAGS "-Oz -Ofast -Wl,--allow-undefined")

add_executable(doom
src/am_map.c
src/doomdef.c
src/f_wipe.c
src/i_main.c
src/i_system.c
src/m_cheat.c
src/m_random.c
src/p_enemy.c
src/p_map.c
src/p_pspr.c
src/p_spec.c
src/p_user.c
src/r_main.c
src/r_things.c
src/st_stuff.c
src/w_wad.c
src/d_items.c
src/doomstat.c
src/g_game.c
src/i_net.c
src/i_video.c
src/m_fixed.c
src/m_swap.c
src/p_floor.c
src/p_maputl.c
src/p_saveg.c
src/p_switch.c
src/r_bsp.c
src/r_plane.c
src/sounds.c
src/tables.c
src/z_zone.c
src/d_main.c
src/dstrings.c
src/hu_lib.c
src/info.c
src/m_argv.c
src/m_menu.c
src/p_ceilng.c
src/p_inter.c
src/p_mobj.c
src/p_setup.c
src/p_telept.c
src/r_data.c
src/r_segs.c
src/s_sound.c
src/v_video.c
src/d_net.c
src/f_finale.c
src/hu_stuff.c
src/i_sound.c
src/m_bbox.c
src/m_misc.c
src/p_doors.c
src/p_lights.c
src/p_plats.c
src/p_sight.c
src/p_tick.c
src/r_draw.c
src/r_sky.c
src/st_lib.c
src/wi_stuff.c
)

target_compile_options(doom PRIVATE "-Wno-everything")
target_include_directories(doom PRIVATE ../../include)
