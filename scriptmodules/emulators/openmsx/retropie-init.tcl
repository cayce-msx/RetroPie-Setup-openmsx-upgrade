namespace eval retropie {

proc init {} {
    set rom_name [guess_title]
    set config_dir [file normalize "$::env(OPENMSX_USER_DATA)/joystick"]

    # sanitize the rom name
    regsub -all {[:><?\"\/\\|*]} $rom_name "" rom_name

    # auto-configure joystick(s), but only if present
    # openMSX automatically loads the plugged in joysticks in 'autoplug.tcl'
    # but does not map them
    if {![info exists ::msxjoystick1_config]} {
        return
    }

    # MSX supports 2 joysticks. Map the first two found host controllers.
    set joy_idx 1
    foreach joy_id [openmsx_info joystick] {
        set host_controller_info [openmsx_info joystick $joy_id]
        set joy_name [dict get $host_controller_info "name"]
        regsub -all {[:><?\"\/\\|*]} $joy_name "" joy_name

        if { !($rom_name eq "") } {
            if { [ file exists "$config_dir/game/$rom_name.tcl" ] } {
                # map game-specific joystick configuration
                load_config_joystick $joy_idx $joy_id $rom_name "$config_dir/game/$rom_name.tcl"
                return
            }
        }

        if { [file exists "$config_dir/$joy_name.tcl"] } {
            load_config_joystick $joy_idx $joy_id $joy_name "$config_dir/$joy_name.tcl"
            incr joy_idx
        }

        if { $joy_idx > 2 } break
    }
}

proc load_config_joystick { joy_idx joy_id conf_name conf_script } {
    source "$conf_script"
    # check for the joypad auto-configuration function
    if { [info procs "auto_config_joypad"] == "" } {
        return
    }
    auto_config_joypad $joy_idx $joy_id
    message "Loaded joystick$joy_idx configuration for '$conf_name'"
}

}; # namespace: retropie

after boot retropie::init
