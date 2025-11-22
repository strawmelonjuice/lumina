//	Lumina/Peonies
//	Copyright (C) 2018-2026 MLC 'Strawmelonjuice'  Bloeiman and contributors.
//
//	This program is free software: you can redistribute it and/or modify
//	it under the terms of the GNU Affero General Public License as published
//	by the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	This program is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU Affero General Public License for more details.
//
//	You should have received a copy of the GNU Affero General Public License
//	along with this program.  If not, see <https://www.gnu.org/licenses/>.

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
  /// Travel to a different timeline.
  TimeLineTo(String)
  /// Load more posts for the current timeline
  LoadMorePosts(String)
  /// Log the user out (destroys session and recreates model)
  Logout
  /// Close current modal
  CloseModal
  /// Browse modal to different page
  SetModal(String)
  /// Start dragging the modal box
  /// Parameters: the event, current mouse x and y positions
  /// Starts a sideffect that tracks mouse movements and sends MoveModalBoxTo messages
  StartDraggingModalBox(Float, Float)
  /// Move the modal box to a new position
  /// Parameters: new x and y positions
  MoveModalBoxTo(Float, Float)
}
