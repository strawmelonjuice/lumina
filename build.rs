/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */

extern crate build_const;

use markdown::to_html;
use std::fmt::format;
use std::process::Command;
use std::{fs::read_to_string, str::FromStr};

// Javascript runtimes:
//     NodeJS:
#[cfg(windows)]
const NODEJSR: &str = "node.exe";
#[cfg(not(windows))]
const NODEJSR: &str = "node";
//     Bun:
#[cfg(windows)]
const BUNJSR: &str = "bun.exe";
#[cfg(not(windows))]
const BUNJSR: &str = "bun";

// Javascript package managers:
//     NPM:
#[cfg(windows)]
const NODE_NPM: &str = "npm.cmd";
#[cfg(not(windows))]
const NODE_NPM: &str = "npm";
//     Bun:
#[cfg(windows)]
const BUN_NPM: &str = "bun.exe";
#[cfg(not(windows))]
const BUN_NPM: &str = "~/.bun/bin/bun";

#[cfg(windows)]
const PNPM_NPM: &str = "pnpm.cmd";
#[cfg(not(windows))]
const PNPM_NPM: &str = "pnpm";
macro_rules! warn {
    ($($arg:tt)*) => {
        let message = format(format_args!($($arg)*)).replace("\n", "\ncargo:warning=");
        println!("cargo:warning={}", message)
    }
}
fn run_js_pm_stuff(
    pnpm: (u32, &mut Command),
    bun: (u32, &mut Command),
    npm: (u32, &mut Command),
    errmsg: impl AsRef<str>,
) {
    let errormsg = errmsg.as_ref();
    let mut errors = String::new();
    match pnpm.1.output() {
        Ok(t) => {
            if t.status.code().unwrap() != 0 {
                warn!(
                    "{}",
                    format!(
                        "build.rs:{} - PNPM: {}:\n\n{}",
                        pnpm.0,
                        errormsg,
                        std::str::from_utf8(&t.stderr).unwrap_or("Unknown error.")
                    )
                );
            }
        }
        Err(err) => {
            errors.push_str(format!("PNPM: {}; ", err).as_str());
            match bun.1.output() {
                Ok(t) => {
                    if t.status.code().unwrap() != 0 {
                        warn!(
                            "{}",
                            format!(
                                "build.rs:{} - Bun: {}:\n\n{}",
                                bun.0,
                                errormsg,
                                std::str::from_utf8(&t.stderr).unwrap_or("Unknown error.")
                            )
                        );
                    }
                }
                Err(err) => {
                    errors.push_str(format!("Bun: {}; ", err).as_str());
                    match npm.1.output() {
                        Ok(t) => {
                            if t.status.code().unwrap() != 0 {
                                warn!(
                                    "{}",
                                    format!(
                                        "build.rs:{} - NPM: {}:\n\n{}",
                                        npm.0,
                                        errormsg,
                                        std::str::from_utf8(&t.stderr).unwrap_or("Unknown error.")
                                    )
                                );
                            }
                        }
                        Err(err) => {
                            errors.push_str(format!("NPM: {}; ", err).as_str());
                            warn!("{} error messages: {errors}", "No supported (NodeJS / Bun) Javascript runtimes, or package managers (PNPM/Bun/NPM) found on path!".to_string());
                        }
                    }
                }
            }
        }
    }
}

fn create_dirs() -> Result<(), std::io::Error> {
    std::fs::create_dir_all("./target/generated/")?;
    std::fs::create_dir_all("./target/generated/js")?;
    std::fs::create_dir_all("./target/generated/html")?;
    std::fs::create_dir_all("./target/generated/css")?;
    Ok(())
}

fn process_markdown_into_html(htmlfile: &str, markdownfile: &str) -> String {
    let html_file = std::path::PathBuf::from_str(htmlfile).unwrap();
    let md_file = std::path::PathBuf::from_str(markdownfile).unwrap();
    let html_without_md = read_to_string(html_file).unwrap();
    let unprocessed_md = read_to_string(md_file).unwrap();
    let processed_md = to_html(unprocessed_md.as_str());
    html_without_md
        .replace(r#"{{md}}"#, processed_md.as_str())
        .to_string()
}
fn main() {
    let mut assets = build_const::ConstWriter::for_build("assets")
        .unwrap()
        .finish_dependencies();
    match create_dirs() {
        Ok(_) => {}
        Err(e) => {
            warn!("{}", format!("Could not create output folders:\n\n{}", e));
        }
    }
    assets.add_value(
        "STR_ASSETS_INDEX_HTML_",
        "&str",
        process_markdown_into_html("./assets/html/index.html", "./assets/markdown/intro.md")
            .as_str(),
    );
    run_js_pm_stuff(
        (line!(), Command::new(PNPM_NPM).arg("install")),
        (line!(), Command::new(BUN_NPM).arg("install")),
        (line!(), Command::new(NODE_NPM).arg("install")),
        "Could not install dependencies.",
    );
    match Command::new(BUNJSR)
        .arg("--bun")
        .arg("run")
        .arg("build:deps")
        .output()
    {
        Ok(t) => {
            if t.status.code().unwrap() != 0 {
                warn!(
                    "{}",
                    format!(
                        "{} - Could not generate assets:\\n\\n```\\n{}\\n```\\nStatus code: {}.",
                        "build.rs:103",
                        std::str::from_utf8(&t.stderr)
                            .unwrap_or("Unknown error.")
                            .replace('\n', "\\n"),
                        t.status.code().unwrap()
                    )
                );
            }
        }
        Err(_err) => match Command::new(NODEJSR)
            .arg("run-script")
            .arg("build:deps")
            .output()
        {
            Ok(t) => {
                if t.status.code().unwrap() != 0 {
                    warn!("{}", format!(
                        "{} - Could not generate assets:\\n\\n```\\n{}\\n```\\nStatus code: {}.",
                        "build.rs:118",
                        std::str::from_utf8(&t.stderr).unwrap_or("Unknown error.").replace('\n', "\\n"),
                        t.status.code().unwrap()
                    ));
                }
            }
            Err(_err) => {
                warn!("{}","No supported (NodeJS / Bun) Javascript runtimes found on path! Or could not generate necessary files.".to_string());
            }
        },
    };
}
