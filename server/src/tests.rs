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

#[cfg(test)]
#[test]
fn gleam_test() {
    // Sometimes
    println!("Checking Gleam client code...");
    let lustre_result = std::process::Command::new("gleam")
        .current_dir("../client/")
        .args(&["test"])
        .output()
        .expect("Could not run gleam test command. The outcome of the tests itself is unknown.");

    eprint!("{}", String::from_utf8_lossy(&lustre_result.stderr));
    print!("{}", String::from_utf8_lossy(&lustre_result.stdout));

    if !lustre_result.status.success() {
        panic!("Gleam tests failed.");
    }
}
