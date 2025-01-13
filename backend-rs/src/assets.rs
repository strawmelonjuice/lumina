/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */

pub const STR_ASSETS_INDEX_HTML: &str = include_str!("../frontend_assets/html/index.html");
pub const STR_ASSETS_LOGIN_HTML: &str = include_str!("../frontend_assets/html/login.html");
pub const STR_ASSETS_SIGNUP_HTML: &str = include_str!("../frontend_assets/html/signup.html");
pub const STR_ASSETS_HOME_HTML: &str = include_str!("../frontend_assets/html/home.html");
pub const STR_CLEAN_CUSTOMSTYLES_CSS: &str =
    include_str!("../frontend_assets/styles/initial_customstyles.css");

pub const STR_ASSETS_APPJS: &str = include_str!("../generated/js/app.js");
pub const STR_ASSETS_APPJS_MAP: &str = include_str!("../generated/js/app.js.map");

pub const STR_GENERATED_MAIN_MIN_CSS: &str = include_str!("../generated/css/main.min.css");

type Fontbytes = &'static [u8];
pub struct Fonts {
    pub josefin_sans: Fontbytes,
    pub fira_sans: Fontbytes,
    pub gantari: Fontbytes,
    pub syne: Fontbytes,
}

pub fn fonts() -> Fonts {
    Fonts {
        josefin_sans: include_bytes!(
            "../frontend_assets/fonts/Josefin_Sans/JosefinSans-VariableFont_wght.ttf"
        ),
        fira_sans: include_bytes!("../frontend_assets/fonts/Fira_Sans/FiraSans-Regular.ttf"),
        gantari: include_bytes!("../frontend_assets/fonts/Gantari/Gantari-VariableFont_wght.ttf"),
        syne: include_bytes!("../frontend_assets/fonts/Syne/Syne-VariableFont_wght.ttf"),
    }
}

pub const STR_ASSETS_LOGO_SVG: &str = include_str!("../frontend_assets/svg/luminalogo-1.svg");

pub const STR_ASSETS_BTN_NEW_SVG: &str = include_str!("../frontend_assets/svg/add.svg");

pub const STR_ASSETS_BTN_PUSH_SVG: &str = include_str!("../frontend_assets/svg/push.svg");

pub const STR_ASSETS_BTN_COMMENT_SVG: &str = include_str!("../frontend_assets/svg/comment.svg");

pub const STR_ASSETS_BTN_BOOST_SVG: &str = include_str!("../frontend_assets/svg/boost.svg");

pub const STR_ASSETS_GREEN_CHECK_SVG: &str = include_str!("../frontend_assets/svg/green_check.svg");

pub const STR_ASSETS_SPINNER_SVG: &str = include_str!("../frontend_assets/svg/spinner.svg");

pub const STR_ASSETS_RED_CROSS_SVG: &str = include_str!("../frontend_assets/svg/red_cross.svg");
pub const STR_ASSETS_ANON_SVG: &str = include_str!("../frontend_assets/svg/avatar1.svg");

pub fn vec_string_assets_anons_svg() -> Vec<String> {
    vec![
        STR_ASSETS_ANON_SVG.to_string(),
        include_str!("../frontend_assets/svg/avatar2.svg").to_string(),
        include_str!("../frontend_assets/svg/avatar3.svg").to_string(),
        include_str!("../frontend_assets/svg/avatar4.svg").to_string(),
        include_str!("../frontend_assets/svg/avatar5.svg").to_string(),
        include_str!("../frontend_assets/svg/avatar6.svg").to_string(),
    ]
}

pub const BYTES_ASSETS_LOGO_PNG: &[u8] = include_bytes!("../frontend_assets/png/luminalogo-1.png");

pub const STR_ASSETS_EDITOR_WINDOW_HTML: &str = include_str!("../frontend_assets/html/writer.html");

pub const STR_ASSETS_POST_RENDERS_HANDLEBARS: &str =
    include_str!("../frontend_assets/handlebars/postrender.handlebars");
