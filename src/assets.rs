/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */
#![allow(dead_code)]


#[cfg(not(windows))]
pub const STR_ASSETS_INDEX_HTML: &str = include_str!("./assets/index.html");
#[cfg(windows)]
pub const STR_ASSETS_INDEX_HTML: &str = include_str!(".\\assets\\index.html");

#[cfg(not(windows))]
pub const STR_ASSETS_HOME_HTML: &str = include_str!("./assets/timeline.handlebars");
#[cfg(windows)]
pub const STR_ASSETS_HOME_HTML: &str = include_str!(".\\assets\\timeline.handlebars");

#[cfg(not(windows))]
pub const STR_CLEAN_CONFIG_TOML: &str = include_str!("./assets/initial_config.toml");
#[cfg(windows)]
pub const STR_CLEAN_CONFIG_TOML: &str = include_str!(".\\assets\\initial_config.toml");

#[cfg(not(windows))]
pub const STR_ASSETS_MAIN_MIN_JS: &str = include_str!("../target/generated/js/main.min.js");
#[cfg(windows)]
pub const STR_ASSETS_MAIN_MIN_JS: &str = include_str!("..\\target\\generated\\js\\main.min.js");

#[cfg(not(windows))]
pub const STR_GENERATED_MAIN_MIN_CSS: &str = include_str!("../target/generated/css/main.min.css");
#[cfg(windows)]
pub const STR_GENERATED_MAIN_MIN_CSS: &str =
    include_str!("..\\target\\generated\\css\\main.min.css");
type Fontbytes = &'static [u8];
#[derive()]
pub(crate) struct Fonts {
    pub(crate) josefin_sans: Fontbytes,
    pub(crate) fira_sans: Fontbytes,
    pub(crate) gantari: Fontbytes,
    pub(crate) syne: Fontbytes,
}
#[cfg(windows)]
pub(crate) fn fonts() -> Fonts {
    Fonts {
        josefin_sans: (include_bytes!(
            ".\\assets\\fonts\\Josefin_Sans\\JosefinSans-VariableFont_wght.ttf"
        )),
        fira_sans: (include_bytes!(".\\assets\\fonts\\Fira_Sans\\FiraSans-Regular.ttf")),
        gantari: (include_bytes!(".\\assets\\fonts\\Gantari\\Gantari-VariableFont_wght.ttf")),
        syne: (include_bytes!(".\\assets\\fonts\\Syne\\Syne-VariableFont_wght.ttf")),
    }
}
#[cfg(not(windows))]
pub(crate) fn fonts() -> Fonts {
    Fonts {
        josefin_sans: (include_bytes!(
            "./assets/fonts/Josefin_Sans/JosefinSans-VariableFont_wght.ttf"
        )),
        fira_sans: (include_bytes!("./assets/fonts/Fira_Sans/FiraSans-Regular.ttf")),
        gantari: (include_bytes!("./assets/fonts/Gantari/Gantari-VariableFont_wght.ttf")),
        syne: (include_bytes!("./assets/fonts/Syne/Syne-VariableFont_wght.ttf")),
    }
}
