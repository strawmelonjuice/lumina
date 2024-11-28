// Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
// Licensed under the BSD 3-Clause License. See the LICENSE file for more info.

import plinth/browser/element.{type Element}

@external(javascript, "../../elementactions_ffi.ts", "disableElement")
pub fn disable_element(a: Element) -> nil

@external(javascript, "../../elementactions_ffi.ts", "enableElement")
pub fn enable_element(a: Element) -> nil

@external(javascript, "../../elementactions_ffi.ts", "hideElement")
pub fn hide_element(a: Element) -> nil

@external(javascript, "../../elementactions_ffi.ts", "unHideElement")
pub fn show_element(a: Element) -> nil

@external(javascript, "../../elementactions_ffi.ts", "elementHidden")
pub fn element_hidden(a: Element) -> bool

@external(javascript, "../../elementactions_ffi.ts", "getWindowHost")
pub fn get_window_host() -> String
