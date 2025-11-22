//// Lumina > Server > Helpers
//// Shared helper functions and utilities for the server.

/*
 *     Lumina/Peonies
 *     Copyright (C) 2018-2026 MLC 'Strawmelonjuice'  Bloeiman and contributors.
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU Affero General Public License as published
 *     by the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU Affero General Public License for more details.
 *
 *     You should have received a copy of the GNU Affero General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

pub mod events;

use cynthia_con::{CynthiaColors, CynthiaStyles};

/// Message prefixes for different types of messages.
/// Usage: `let (info, warn, error, success, failure, log, incoming, registrationerror) = message_prefixes();`
pub(crate) fn message_prefixes() -> (
    String,
    String,
    String,
    String,
    String,
    String,
    String,
    String,
) {
    let info = "[INFO]".color_green().style_bold();
    let warn = "[WARN]".color_yellow().style_bold();
    let error = "[ERROR]".color_error_red().style_bold();
    let success = "[✅ SUCCESS]".color_ok_green().style_bold();
    let failure = "[✖️ FAILURE]".color_error_red().style_bold();
    let log = "[LOG]".color_blue().style_bold();
    let incoming = "[INCOMING]".color_lilac().style_bold();
    let registrationerror = "[RegistrationError]".color_bright_red().style_bold();
    (
        info,
        warn,
        error,
        success,
        failure,
        log,
        incoming,
        registrationerror,
    )
}
