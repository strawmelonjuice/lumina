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
