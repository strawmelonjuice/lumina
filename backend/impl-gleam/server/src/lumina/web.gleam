// IMPORTS ---------------------------------------------------------------------

import lumina_client
import lumina_client/model_type.{type Model, type Msg}
import lustre.{type App}

// MAIN ------------------------------------------------------------------------

pub fn component() -> App(_, Model, Msg) {
  lumina_client.app(fn(_) { todo })
}

pub type Message =
  model_type.Msg
