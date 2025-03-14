const MINIMUM_GLEAM_VERSION: (u32, u32, u32) = (1, 9, 1);
const MINIMUM_BUN_VERSION: (u32, u32, u32) = (1, 2, 4);

fn main() {
    // The build script will be ran from the server directory, so we need to go up one directory to get to the root
    let root_path = match std::env::var("CARGO_MANIFEST_DIR") {
        Ok(path) => (path + "/..").replace("/server/..", "/"),
        Err(_) => panic!("Failed to get root path"),
    };
    // Tell cargo to rerun the build script if the client directory changes
    println!("cargo::rerun-if-changed={}client/src/", root_path);
    // Check if Bun is installed and is the correct version
    println!("Checking for Bun...");
    let bun_version = match std::process::Command::new("bun").arg("--version").output() {
        Ok(output) => output,
        Err(_) => {
            let minimum_bun_version = MINIMUM_BUN_VERSION.0.to_string()
                + "."
                + &MINIMUM_BUN_VERSION.1.to_string()
                + "."
                + &MINIMUM_BUN_VERSION.2.to_string();

            panic!(
                "Could not find Bun in path. Please install Bun {} or higher.",
                minimum_bun_version
            );
        }
    };
    println!("Checking found Bun version...");
    let bun_version = String::from_utf8_lossy(&bun_version.stdout);
    let bun_version = bun_version.trim();
    let bun_version = bun_version.split_whitespace().nth(0).unwrap();
    let bun_version = bun_version.split('.').collect::<Vec<&str>>();
    let bun_version: (u32, u32, u32) = (
        bun_version[0].parse::<u32>().unwrap(),
        bun_version[1].parse::<u32>().unwrap(),
        bun_version[2].parse::<u32>().unwrap(),
    );
    if bun_version < MINIMUM_BUN_VERSION {
        let bun_version = bun_version.0.to_string()
            + "."
            + &bun_version.1.to_string()
            + "."
            + &bun_version.2.to_string();
        let minimum_bun_version = MINIMUM_BUN_VERSION.0.to_string()
            + "."
            + &MINIMUM_BUN_VERSION.1.to_string()
            + "."
            + &MINIMUM_BUN_VERSION.2.to_string();
        panic!(
            "Bun version {} or higher is required, found {}",
            minimum_bun_version, bun_version
        );
    }
    println!("Bun version is correct.");
    // Install the dependencies: bun install
    println!("Installing Bun dependencies...");
    let install_result = std::process::Command::new("bun")
        .current_dir(root_path.clone() + "/client")
        .args(&["install"])
        .output()
        .expect("Failed to install Bun dependencies");
    if !install_result.status.success() {
        println!(
            "cargo:error={}",
            String::from_utf8_lossy(&install_result.stderr)
        );
        panic!("Failed to install Bun dependencies.");
    }
    println!("Bun dependencies installed.");

    // Check if Gleam is installed and is the correct version
    println!("Checking for Gleam...");
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
    println!("Checking found Gleam version...");
    let gleam_version = String::from_utf8_lossy(&gleam_version.stdout);
    let gleam_version = gleam_version.trim();
    // Splits behind the word gleam, in "gleam x.x.x" to keep "x.x.x"
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
    println!("Gleam version is correct.");

    // Compile the Gleam code: gleam run -m lustre/dev build --minify=true
    println!("Compiling Gleam client code...");
    let lustre_result = std::process::Command::new("gleam")
        .current_dir(root_path.clone() + "/client")
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
