/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */
//! This module contains the tellgen function and future derivatives.
use std::time::SystemTime;

use colored::Colorize;
use time::{format_description, OffsetDateTime};

use crate::Logging;

const DATE_FORMAT_STR: &str = "[hour]:[minute]:[second]";

#[doc = r"Generates a function that either prints as an [info] log, or prints as [log], depending on configuration. This because loglevel 3 is a bit too verbose, while loglevel 2 is too quiet."]
pub(crate) fn tellgen(a: Option<Logging>) -> fn(msg: String) {
    fn po(msg: String) {
        let dt1: OffsetDateTime = SystemTime::now().into();
        let dt_fmt = format_description::parse(DATE_FORMAT_STR).unwrap();
        let times = dt1.format(&dt_fmt).unwrap();
        println!("{} {} {}", times, "[LOG] ".magenta(), msg);
        info!("{}", msg);
    }
    match a {
        Some(a) => {
            match a.term_loglevel {
                None => po,
                Some(s) => {
                    // If the log level is set to erroronly or info-too, just return it as info. The only other case is really just 2, but I am funny.
                    if s >= 3 || s <= 1 {
                        |msg: String| {
                            info!("{}", msg);
                        }
                    } else {
                        po
                    }
                }
            }
        }
        None => po,
    }
}
