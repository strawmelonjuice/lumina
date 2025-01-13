use crate::ERun;
use colored::Colorize;
use std::path::PathBuf;

#[derive(Clone, Debug)]
pub struct LuminaConfig {
    pub(crate) lumina_server_port: u16,
    pub(crate) lumina_server_addr: String,
    pub(crate) lumina_server_https: bool,
    pub(crate) lumina_synchronisation_iid: String,
    pub(crate) lumina_synchronisation_interval: u64,
    pub(crate) db_custom_salt: String,
    pub(crate) db_connection_info: LuminaDBConnectionInfo,
    pub(crate) logging: Option<LuminaLogConfig>,
    /// Run time information
    pub(crate) erun: ERun,
}

#[derive(Clone, Debug)]
pub enum LuminaDBConnectionInfo {
    LuminaDBConnectionInfoPOSTGRES(postgres::Config),
    LuminaDBConnectionInfoSQLite(PathBuf),
}

#[derive(Default, Debug, Clone, PartialEq)]
pub struct LuminaLogConfig {
    pub file_loglevel: Option<u8>,
    pub term_loglevel: Option<u8>,
    pub logfile: Option<String>,
}
#[derive(Debug)]
enum DBType {
    POSTGRES,
    SQLITE,
}
impl LuminaConfig {
    /// Loads the configuration from environment variables after reading an env file if it exists.
    pub fn new(erun: ERun) -> Self {
        if erun.cd.join(".env").exists() {
            if dotenv::from_path(erun.cd.join(".env")).is_ok() {
                info!(
                    "Loaded environment variables from '{}' file.",
                    erun.cd.join(".env").display()
                );
            };
        } else {
            info!(
                "No '.env' file found in the directory '{}'. Using only environment variables.",
                erun.cd.display()
            );
        }

        let db_type: DBType = {
            match std::env::var("_LUMINA_DB_TYPE_")
                .unwrap_or(String::from("SQLITE"))
                .to_uppercase()
                .as_str()
            {
                "POSTGRES" => DBType::POSTGRES,
                _ => {
                    warn!("{}", "Using SQLITE database, this is not recommended for production as it is not scalable.".yellow());
                    info!("{}","To use a different database, set the '_LUMINA_DB_TYPE_' environment variable to 'POSTGRES'.".purple());
                    DBType::SQLITE
                }
            }
        };
        let db_connection_info = match db_type {
            DBType::SQLITE => {
                let keyname = "_LUMINA_SQLITE_FILE_";
                let def_val = String::from("instance.db");
                match std::env::var(keyname) {
                    Ok(val) => {
                        LuminaDBConnectionInfo::LuminaDBConnectionInfoSQLite(erun.cd.join(val))
                    }
                    Err(_) => {
                        warn!("The key '{}' was not found in the environment variables. Using default: {}", keyname, def_val);
                        LuminaDBConnectionInfo::LuminaDBConnectionInfoSQLite(erun.cd.join(def_val))
                    }
                }
            }
            DBType::POSTGRES => {
                let mut pg_config = postgres::Config::new();
                {
                    match std::env::var("_LUMINA_POSTGRES_USERNAME_") {
                        Ok(val) => {
                            pg_config.user(&val);
                        }
                        Err(_) => {
                            error!("No Postgres database user provided under environment variable '_LUMINA_POSTGRES_USER_'. Exiting.");
                            std::process::exit(1);
                        }
                    }
                }
                match std::env::var("_LUMINA_POSTGRES_HOST_") {
                    Ok(val) => {
                        pg_config.host(&val);
                    }
                    Err(_) => {
                        warn!("No Postgres database host provided under environment variable '_LUMINA_POSTGRES_HOST_'. Using default value 'localhost'.");
                        pg_config.host("localhost");
                    }
                };
                match std::env::var("_LUMINA_POSTGRES_PASSWORD_") {
                    Ok(val) => {
                        pg_config.password(&val);
                    }
                    Err(_) => {
                        info!("No Postgres database password provided under environment variable '_LUMINA_POSTGRES_PASSWORD_'. Using passwordless connection.");
                    }
                };
                match std::env::var("_LUMINA_POSTGRES_DATABASE_") {
                    Ok(val) => {
                        pg_config.dbname(&val);
                    }
                    Err(_) => {
                        error!("No Postgres database name provided under environment variable '_LUMINA_POSTGRES_DATABASE_'. Exiting.");
                        std::process::exit(1);
                    }
                };
                {
                    match std::env::var("_LUMINA_POSTGRES_PORT_") {
                        Ok(val) => match val.parse::<u16>() {
                            Ok(v) => {
                                pg_config.port(v);
                            }
                            Err(_) => {
                                error!("The value '{}' for the key '_LUMINA_POSTGRES_PORT_' is not a valid port number. Exiting.", val);
                                std::process::exit(1);
                            }
                        },
                        Err(_) => {
                            warn!("No Postgres database port provided under environment variable '_LUMINA_POSTGRES_PORT_'. Using default value '5432'.");
                            pg_config.port(5432);
                        }
                    }
                }

                LuminaDBConnectionInfo::LuminaDBConnectionInfoPOSTGRES(pg_config)
            }
        };

        LuminaConfig {
            lumina_server_port: {
                let keyname = "_LUMINA_SERVER_PORT_";
                let def_val = String::from("8085");
                match std::env::var(keyname) {
                    Ok(val) => match val.parse::<u16>() {
                        Ok(v) => v,
                        Err(_) => {
                            error!("The value '{}' for the key '{}' is not a valid port number. Exiting.", val, keyname);
                            std::process::exit(1);
                        }
                    },
                    Err(_) => {
                        warn!("The key '{}' was not found in the environment variables. Using default value.", keyname);
                        def_val.parse::<u16>().unwrap()
                    }
                }
            },
            lumina_server_addr: {
                let keyname = "_LUMINA_SERVER_ADDR_";
                let def_val = String::from("localhost");
                match std::env::var(keyname) {
                    Ok(val) => val,
                    Err(_) => {
                        warn!("The key '{}' was not found in the environment variables. Using default value.", keyname);
                        def_val
                    }
                }
            },
            lumina_server_https: {
                let keyname = "_LUMINA_SERVER_HTTPS_";
                let def_val = String::from("true");
                match std::env::var(keyname) {
                    Ok(val) => {
                        match val.parse::<bool>() {
                            Ok(v) => v,
                            Err(_) => {
                                error!("The value '{}' for the key '{}' is not a valid boolean. Exiting.", val, keyname);
                                std::process::exit(1);
                            }
                        }
                    }
                    Err(_) => {
                        warn!("The key '{}' was not found in the environment variables. Using default value.", keyname);
                        def_val.parse::<bool>().unwrap()
                    }
                }
            },
            lumina_synchronisation_iid: {
                let keyname = "_LUMINA_SYNCHRONISATION_IID_";
                let def_val = String::from("localhost");
                match std::env::var(keyname) {
                    Ok(val) => val,
                    Err(_) => {
                        warn!("The key '{}' was not found in the environment variables. Using default value.", keyname);
                        def_val
                    }
                }
            },
            lumina_synchronisation_interval: {
                let keyname = "_LUMINA_SYNCHRONISATION_INTERVAL_";
                let def_val = String::from("30");
                match std::env::var(keyname) {
                    Ok(val) => {
                        match val.parse::<u64>() {
                            Ok(v) => v,
                            Err(_) => {
                                error!("The value '{}' for the key '{}' is not a valid number. Exiting.", val, keyname);
                                std::process::exit(1);
                            }
                        }
                    }
                    Err(_) => {
                        warn!("The key '{}' was not found in the environment variables. Using default value.", keyname);
                        def_val.parse::<u64>().unwrap()
                    }
                }
            },
            db_custom_salt: {
                let keyname = "_LUMINA_DB_SALT_";
                let def_val = String::from("sally_sal");
                match std::env::var(keyname) {
                    Ok(val) => val,
                    Err(_) => {
                        warn!("The key '{}' was not found in the environment variables. Using default value.", keyname);
                        def_val
                    }
                }
            },
            db_connection_info,
            // Uses the default value of Logging::default() fer now.
            logging: None,
            erun,
        }
    }
}
