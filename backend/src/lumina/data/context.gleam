import lumina/data/config
import lumina/database.{type LuminaDBConnection}
import wisp_kv_sessions/session_config

pub type Context {
  Context(
    config_dir: String,
    session_config: session_config.Config,
    priv_directory: String,
    config: config.LuminaConfig,
    db: LuminaDBConnection,
  )
}
