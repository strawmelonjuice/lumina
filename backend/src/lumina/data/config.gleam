pub type LuminaConfig {
  LuminaConfig(
    lumina_server_port: Int,
    lumina_server_addr: String,
    lumina_server_https: Bool,
    lumina_synchronisation_iid: String,
    lumina_synchronisation_interval: Int,
    db_custom_salt: String,
    db_connection_info: LuminaDBConnectionInfo,
  )
}

pub type LuminaDBConnectionInfo {
  MySQLConnectionInfo(
    port: Int,
    host: String,
    username: String,
    password: option.Option(String),
    name: String,
  )
  SQLiteConnectionInfo(file: String)
}

import envoy
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import gleamy_lights/premixed
import simplifile as fs
import wisp

pub fn load(in: String) {
  let envfile = in <> ".env"
  case fs.is_file(envfile) {
    // If an .env file exists, load it.
    Ok(True) -> {
      let assert Ok(env_file) = fs.read(envfile)
      string.split(env_file, "\n")
      |> list.filter(fn(line) { line != "" })
      |> list.each(fn(line) {
        let splited_line = string.split(line, "=")
        let key =
          list.first(splited_line)
          |> result.unwrap("")
          |> string.trim()

        let value =
          list.drop(splited_line, 1)
          |> string.join("=")
          |> string.trim()
        envoy.set(key, value)
      })
    }
    // Otherwise tell the console that environment variables will be used.
    Ok(False) ->
      wisp.log_notice(
        "No "
        <> premixed.text_orange(envfile)
        <> " file found, using environment variables",
      )
    Error(_) -> {
      panic as "Error reading .env file"
    }
  }
  let sv_port: Int = case envoy.get("_LUMINA_SERVER_PORT_") {
    Error(_) -> {
      wisp.log_notice(
        "No port provided under environment variable '"
        <> premixed.text_orange("_LUMINA_SERVER_PORT_")
        <> "', using default "
        <> premixed.text_green("8085"),
      )
      8085
    }
    Ok(port) ->
      case int.parse(port) {
        Ok(p) -> p
        Error(_) -> {
          wisp.log_notice(
            "Invalid port provided under environment variable '"
            <> premixed.text_orange("_LUMINA_SERVER_PORT_")
            <> "', using default "
            <> premixed.text_green("8085"),
          )
          8085
        }
      }
  }
  let sv_host: String = case envoy.get("_LUMINA_SERVER_ADDR_") {
    Error(_) -> {
      wisp.log_notice(
        "No host provided under environment variable '"
        <> premixed.text_orange("_LUMINA_SERVER_ADDR_")
        <> "', using default "
        <> premixed.text_green("localhost"),
      )
      "localhost"
    }
    Ok(host) -> host
  }
  let sv_safe: Bool = case
    case envoy.get("_LUMINA_SERVER_ADDR_") {
      Error(_) -> {
        wisp.log_notice(
          "No value provided under environment variable '"
          <> premixed.text_orange("_LUMINA_SERVER_HTTPS_")
          <> "', using default "
          <> premixed.text_green("false"),
        )
        "false"
      }
      Ok(host) -> host
    }
    |> string.lowercase()
  {
    "true" -> True
    _ -> False
  }

  let db_info = case
    case envoy.get("_LUMINA_DB_TYPE_") {
      Error(_) -> {
        wisp.log_notice(
          "No database type provided under environment variable '"
          <> premixed.text_orange("_LUMINA_DB_TYPE_")
          <> "', using default "
          <> premixed.text_green("sqlite"),
        )
        "sqlite"
      }
      Ok("sqlite") -> "sqlite"
      Ok("mysql") -> "mysql"
      Ok(_) -> {
        panic as "Invalid database type provided"
      }
    }
  {
    "mysql" -> {
      let db_password =
        envoy.get("_LUMINA_MYSQL_PASSWORD_") |> option.from_result()
      // let db_password = case envoy.get("_LUMINA_MYSQL_PASSWORD_") {
      //   Error(_) -> {
      //     wisp.log_notice(
      //       "No MYSQL password provided under environment variable '"
      //       <> premixed.text_orange("_LUMINA_MYSQL_PASSWORD_")
      //       <> "', using "
      //       <> premixed.text_green("passwordless"),
      //     )
      //     option.None
      //   }
      //   Ok(name) -> option.Some(name)
      // }
      let db_name: String = case envoy.get("_LUMINA_MYSQL_DATABASE_") {
        Error(_) -> {
          wisp.log_notice(
            "No MYSQL database name provided under environment variable '"
            <> premixed.text_orange("_LUMINA_MYSQL_DATABASE_")
            <> "', using default "
            <> premixed.text_green("lumina_db"),
          )
          "lumina_db"
        }
        Ok(name) -> name
      }
      let db_port: Int = case envoy.get("_LUMINA_MYSQL_PORT_") {
        Error(_) -> {
          wisp.log_notice(
            "No MYSQL port provided under environment variable '"
            <> premixed.text_orange("_LUMINA_MYSQL_PORT_")
            <> "', using default "
            <> premixed.text_green("3306"),
          )
          3306
        }
        Ok(port) ->
          case int.parse(port) {
            Ok(p) -> p
            Error(_) -> {
              wisp.log_notice(
                "Invalid MYSQL port provided under environment variable '"
                <> premixed.text_orange("_LUMINA_MYSQL_PORT_")
                <> "', using default "
                <> premixed.text_green("3306"),
              )
              3306
            }
          }
      }
      let db_host: String = case envoy.get("_LUMINA_MYSQL_HOST_") {
        Error(_) -> {
          wisp.log_notice(
            "No MYSQL host provided under environment variable '"
            <> premixed.text_orange("_LUMINA_MYSQL_HOST_")
            <> "', using default "
            <> premixed.text_green("localhost"),
          )
          "localhost"
        }
        Ok(host) -> host
      }
      let db_username: String = case envoy.get("_LUMINA_MYSQL_USERNAME_") {
        Error(_) -> {
          wisp.log_notice(
            "No MYSQL username provided under environment variable '"
            <> premixed.text_orange("_LUMINA_MYSQL_USERNAME_")
            <> "', using default "
            <> premixed.text_green("lumina"),
          )
          "lumina"
        }
        Ok(name) -> name
      }
      MySQLConnectionInfo(
        port: db_port,
        host: db_host,
        username: db_username,
        password: db_password,
        name: db_name,
      )
    }
    "sqlite" -> {
      wisp.log_warning(
        "Using SQLITE database, this is not recommended for production as it is not scalable."
        |> premixed.bg_bright_orange
        |> premixed.text_black,
      )
      let db_file: String = case envoy.get("_LUMINA_SQLITE_FILE_") {
        Error(_) -> {
          wisp.log_notice(
            "No SQLITE file provided under environment variable '"
            <> premixed.text_orange("_LUMINA_SQLITE_FILE_")
            <> "', using default "
            <> premixed.text_green("instance.db"),
          )
          "instance.db"
        }
        Ok(name) -> name
      }
      SQLiteConnectionInfo(file: db_file)
    }
    _ -> {
      panic as "Invalid database type provided"
    }
  }

  // Synchronisation config
  let sy_time: Int = case envoy.get("_LUMINA_SYNCHRONISATION_INTERVAL_") {
    Error(_) -> {
      wisp.log_notice(
        "No MYSQL port provided under environment variable '"
        <> premixed.text_orange("_LUMINA_SYNCHRONISATION_INTERVAL_")
        <> "', using default "
        <> premixed.text_green("30"),
      )
      30
    }
    Ok(o) ->
      case int.parse(o) {
        Ok(p) ->
          case p < 30 {
            True -> {
              wisp.log_notice(
                "Invalid interval provided under environment variable '"
                <> premixed.text_orange("_LUMINA_SYNCHRONISATION_INTERVAL_")
                <> "', using default "
                <> premixed.text_green("30"),
              )
              30
            }
            False -> p
          }
        Error(_) -> {
          wisp.log_notice(
            "Invalid interval provided under environment variable '"
            <> premixed.text_orange("_LUMINA_SYNCHRONISATION_INTERVAL_")
            <> "', using default "
            <> premixed.text_green("30"),
          )
          30
        }
      }
  }
  let sy_iid: String = case envoy.get("_LUMINA_SYNCHRONISATION_IID_") {
    Error(_) -> {
      wisp.log_notice(
        "No value provided under environment variable '"
        <> premixed.text_orange("_LUMINA_SYNCHRONISATION_IID_")
        <> "', using default "
        <> premixed.text_green("localhost"),
      )
      "localhost"
    }
    Ok(host) -> host
  }

  let db_salt: String = case envoy.get("_LUMINA_DB_SALT_") {
    Error(_) -> {
      wisp.log_notice(
        "No value provided under environment variable '"
        <> premixed.text_orange("_LUMINA_DB_SALT_")
        <> "', using default "
        <> premixed.text_green("sally_sal"),
      )
      "sally_sal"
    }
    Ok(host) -> host
  }

  // Compile into one record
  LuminaConfig(
    db_connection_info: db_info,
    db_custom_salt: db_salt,
    lumina_server_port: sv_port,
    lumina_server_addr: sv_host,
    lumina_server_https: sv_safe,
    lumina_synchronisation_iid: sy_iid,
    lumina_synchronisation_interval: sy_time,
  )
}
