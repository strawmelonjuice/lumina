const MINIMUM_GLEAM_VERSION: (u32, u32, u32) = (1, 8, 1);
fn main() {
    // The build script will be ran from the server directory, so we need to go up one directory to get to the root
    let root_path = match std::env::var("CARGO_MANIFEST_DIR") {
        Ok(path) => path + "/..",
        Err(_) => panic!("Failed to get root path"),
    };
    // Tell Cargo that if the given file changes, to rerun this build script.
    println!("cargo::rerun-if-changed={}client/src", root_path);

    // Check if Gleam is installed and is the correct version
    let gleam_version = match std::process::Command::new("gleam")
        .arg("--version")
        .output()
    {
        Ok(output) => output,
        Err(_) => {
            let minimum_gleam_version = MINIMUM_GLEAM_VERSION.0.to_string()
                + "."
                + &MINIMUM_GLEAM_VERSION.1.to_string()
                + "."
                + &MINIMUM_GLEAM_VERSION.2.to_string();

            panic!(
                "Could not find Gleam in path. Please install Gleam {} or higher.",
                minimum_gleam_version
            );
        }
    };
    let gleam_version = String::from_utf8_lossy(&gleam_version.stdout);
    let gleam_version = gleam_version.trim();
    let gleam_version = gleam_version.split_whitespace().nth(1).unwrap();
    let gleam_version = gleam_version.split('.').collect::<Vec<&str>>();
    let gleam_version: (u32, u32, u32) = (
        gleam_version[0].parse::<u32>().unwrap(),
        gleam_version[1].parse::<u32>().unwrap(),
        gleam_version[2].parse::<u32>().unwrap(),
    );
    if gleam_version < MINIMUM_GLEAM_VERSION {
        let gleam_version = gleam_version.0.to_string()
            + "."
            + &gleam_version.1.to_string()
            + "."
            + &gleam_version.2.to_string();
        let minimum_gleam_version = MINIMUM_GLEAM_VERSION.0.to_string()
            + "."
            + &MINIMUM_GLEAM_VERSION.1.to_string()
            + "."
            + &MINIMUM_GLEAM_VERSION.2.to_string();
        panic!(
            "Gleam version {} or higher is required, found {}",
            minimum_gleam_version, gleam_version
        );
    }

    // Compile the Gleam code: gleam run -m lustre/dev build --minify=true
    let lustre_result = std::process::Command::new("gleam")
        .current_dir(root_path + "/client")
        .args(&["run", "-m", "lustre/dev", "build", "--minify=true"])
        .output()
        .expect("Failed to compile Gleam code");
    if !lustre_result.status.success() {
        println!(
            "cargo:error={}",
            String::from_utf8_lossy(&lustre_result.stderr)
        );
        panic!("Failed to compile Gleam code.");
    }
}
