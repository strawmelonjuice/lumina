import lustre_websocket

pub type Msg {
  WSTryReconnect
  TickUp
  WsDisconnectDefinitive
  WsWrapper(lustre_websocket.WebSocketEvent)
  ToLoginPage
  SubmitLogin(List(#(String, String)))
  ToRegisterPage
  SubmitSignup(List(#(String, String)))
  ToLandingPage
  // Can be re-used for both login and register pages
  UpdateEmailField(String)
  UpdatePasswordField(String)
  // Register page
  UpdateUsernameField(String)
  UpdatePasswordConfirmField(String)
  FocusLostEmailField
}
