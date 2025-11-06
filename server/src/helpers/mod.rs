pub mod events;

use cynthia_con::{CynthiaColors, CynthiaStyles};

/// Message prefixes for different types of messages.
/// Usage: `let (info, warn, error, success, failure, log, incoming, registrationerror) = message_prefixes();`
pub fn message_prefixes() -> (
    std::string::String,
    std::string::String,
    std::string::String,
    std::string::String,
    std::string::String,
    std::string::String,
    std::string::String,
    std::string::String,
) {
    let info = "[INFO]".color_green().style_bold();
    let warn = "[WARN]".color_yellow().style_bold();
    let error = "[ERROR]".color_error_red().style_bold();
    let succes = "[✅ SUCCESS]".color_ok_green().style_bold();
    let failure = "[✖️ FAILURE]".color_error_red().style_bold();
    let log = "[LOG]".color_blue().style_bold();
    let incoming = "[INCOMING]".color_lilac().style_bold();
    let registrationerror = "[RegistrationError]".color_bright_red().style_bold();
    (
        info,
        warn,
        error,
        succes,
        failure,
        log,
        incoming,
        registrationerror,
    )
}
