/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */

use markdown::to_html;

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
const BUN_NPM: &str = "bun";
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
extern crate build_const;

fn main() {
    let mut assets = build_const::ConstWriter::for_build("assets")
        .unwrap()
        .finish_dependencies();
    match create_dirs() {
        Ok(_) => {}
        Err(e) => {
            panic!("Could not create output folders:\n\n{}", e)
        }
    }
    assets.add_value(
        "STR_ASSETS_INDEX_HTML_",
        "&str",
        process_markdown_into_html(
            "./src/assets/html/index.html",
            "./src/assets/markdown/intro.md",
        )
        .as_str(),
    );

    match std::process::Command::new(BUN_NPM).arg("install").output() {
        Ok(t) => {
            if t.status.code().unwrap() != 0 {
                panic!(
                    "Could not install dependencies:\n\n{}",
                    std::str::from_utf8(&t.stderr).unwrap_or("Unknown error.")
                )
            }
        }
        Err(_err) => match std::process::Command::new(NODE_NPM).arg("install").output() {
            Ok(t) => {
                if t.status.code().unwrap() != 0 {
                    panic!(
                        "Could not install dependencies:\n\n{}",
                        std::str::from_utf8(&t.stderr).unwrap_or("Unknown error.")
                    )
                }
            }
            Err(_err) => {
                panic!("No supported (Node.JS or Bun) Javascript runtimes found on path! Or could not install dependencies.");
            }
        },
    };
    match std::process::Command::new(BUNJSR)
        .arg("--bun")
        .arg("run")
        .arg("build:deps")
        .output()
    {
        Ok(t) => {
            if t.status.code().unwrap() != 0 {
                panic!(
                    "Could not generate assets:\n\n{}",
                    std::str::from_utf8(&t.stderr).unwrap_or("Unknown error.")
                )
            }
        }
        Err(_err) => match std::process::Command::new(NODEJSR)
            .arg("run")
            .arg("build:deps")
            .output()
        {
            Ok(t) => {
                if t.status.code().unwrap() != 0 {
                    panic!(
                        "Could not generate assets:\n\n{}",
                        std::str::from_utf8(&t.stderr).unwrap_or("Unknown error.")
                    )
                }
            }
            Err(_err) => {
                panic!("No supported (Node.JS or Bun) Javascript runtimes found on path! Or could not generate necessary files.");
            }
        },
    };
}
