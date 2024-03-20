use colored::Colorize;

pub fn error(msg: String) {
    eprintln!("{0}: {msg}", "ERROR".red())
}

pub fn info(msg: String) {
    println!("{0}: {msg}", "INFO".bright_yellow())
}
