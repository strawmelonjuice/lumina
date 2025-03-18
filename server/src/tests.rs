#[cfg(test)]
#[test]
fn gleam_test() {
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
