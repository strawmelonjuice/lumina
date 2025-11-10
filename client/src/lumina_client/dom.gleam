import gleam/dynamic/decode

/// Get the color scheme of the user's system (media query)
@external(javascript, "./dom_ffi.mjs", "get_color_scheme")
pub fn get_color_scheme() -> String

@external(javascript, "./dom_ffi.mjs", "classfoundintree")
pub fn classfoundintree(element: decode.Dynamic, class_name: String) -> Bool
