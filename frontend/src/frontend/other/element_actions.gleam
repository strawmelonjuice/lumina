// Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
// Licensed under the BSD 3-Clause License. See the LICENSE file for more info.

import plinth/browser/element.{type Element}

@external(javascript, "../../elementactions_ffi.mts", "disableElement")
pub fn disable_element(a: Element) -> nil

@external(javascript, "../../elementactions_ffi.mts", "enableElement")
pub fn enable_element(a: Element) -> nil
