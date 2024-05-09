/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */
#![allow(dead_code)]

build_const!("assets");
pub const STR_ASSETS_INDEX_HTML: &str = STR_ASSETS_INDEX_HTML_;
// pub const STR_ASSETS_INDEX_HTML: &str = include_str!("../target/generated/html/index.html");
pub const STR_ASSETS_LOGIN_HTML: &str = include_str!("assets/html/login.html");
pub const STR_ASSETS_SIGNUP_HTML: &str = include_str!("assets/html/signup.html");

pub const STR_ASSETS_HOME_HTML: &str = include_str!("assets/html/home.html");

pub const STR_CLEAN_CONFIG_TOML: &str = include_str!("assets/toml/initial_config.toml");

pub const STR_CLEAN_CUSTOMSTYLES_CSS: &str = include_str!("assets/styles/initial_customstyles.css");

pub const STR_ASSETS_PREFETCH_JS: &str = include_str!("../target/generated/js/prefetch.min.js");

pub const STR_ASSETS_INDEX_JS: &str = include_str!("../target/generated/js/site-index.min.js");
pub const STR_ASSETS_HOME_JS: &str = include_str!("../target/generated/js/site-home.min.js");
pub const STR_ASSETS_LOGIN_JS: &str = include_str!("../target/generated/js/login.min.js");
pub const STR_ASSETS_SIGNUP_JS: &str = include_str!("../target/generated/js/signup.min.js");

pub const STR_GENERATED_MAIN_MIN_CSS: &str = include_str!("../target/generated/css/main.min.css");

type Fontbytes = &'static [u8];
pub(crate) struct Fonts {
    pub(crate) josefin_sans: Fontbytes,
    pub(crate) fira_sans: Fontbytes,
    pub(crate) gantari: Fontbytes,
    pub(crate) syne: Fontbytes,
}

pub(crate) fn fonts() -> Fonts {
    Fonts {
        josefin_sans: include_bytes!("assets/fonts/Josefin_Sans/JosefinSans-VariableFont_wght.ttf"),
        fira_sans: include_bytes!("assets/fonts/Fira_Sans/FiraSans-Regular.ttf"),
        gantari: include_bytes!("assets/fonts/Gantari/Gantari-VariableFont_wght.ttf"),
        syne: include_bytes!("assets/fonts/Syne/Syne-VariableFont_wght.ttf"),
    }
}

pub const STR_ASSETS_LOGO_SVG: &str = include_str!("assets/svg/ephewlogo-1.svg");

pub const STR_ASSETS_GREEN_CHECK_SVG: &str = include_str!("assets/svg/green_check.svg");

pub const STR_ASSETS_SPINNER_SVG: &str = include_str!("assets/svg/spinner.svg");

pub const STR_ASSETS_RED_CROSS_SVG: &str = include_str!("assets/svg/red_cross.svg");
pub const STR_ASSETS_ANON_SVG: &str = include_str!("assets/svg/avatar1.svg");


pub fn vec_string_assets_anons_svg() -> Vec<String> {
	vec!(STR_ASSETS_ANON_SVG.to_string(),
	include_str!("assets/svg/avatar2.svg").to_string(),
	include_str!("assets/svg/avatar3.svg").to_string(),
	include_str!("assets/svg/avatar4.svg").to_string(),
	include_str!("assets/svg/avatar5.svg").to_string(),
	include_str!("assets/svg/avatar6.svg").to_string())
}

pub const BYTES_ASSETS_LOGO_PNG: &[u8] = include_bytes!("assets/png/ephewlogo-1.png");

pub const STR_NODE_MOD_AXIOS_MIN_JS: &str = include_str!("../node_modules/axios/dist/axios.min.js");
pub const STR_NODE_MOD_AXIOS_MIN_JS_MAP: &str =
    include_str!("../node_modules/axios/dist/axios.min.js.map");

pub const STR_ASSETS_HOME_SIDE_HANDLEBARS: &str = include_str!("assets/handlebars/home-side.handlebars");
