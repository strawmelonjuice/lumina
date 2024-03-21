use colored::Colorize;

pub fn error(msg: String) {
    eprintln!("{0}: {msg}", "error".red())
}

pub fn info(msg: String) {
    println!("{0}: {msg}", "info".bright_yellow())
}
