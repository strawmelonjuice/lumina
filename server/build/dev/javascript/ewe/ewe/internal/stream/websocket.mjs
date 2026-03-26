import * as $exception from "../../../../exception/exception.mjs";
import * as $atom from "../../../../gleam_erlang/gleam/erlang/atom.mjs";
import * as $process from "../../../../gleam_erlang/gleam/erlang/process.mjs";
import * as $actor from "../../../../gleam_otp/gleam/otp/actor.mjs";
import * as $bit_array from "../../../../gleam_stdlib/gleam/bit_array.mjs";
import * as $bytes_tree from "../../../../gleam_stdlib/gleam/bytes_tree.mjs";
import * as $dynamic from "../../../../gleam_stdlib/gleam/dynamic.mjs";
import * as $option from "../../../../gleam_stdlib/gleam/option.mjs";
import { None, Some } from "../../../../gleam_stdlib/gleam/option.mjs";
import * as $socket from "../../../../glisten/glisten/socket.mjs";
import * as $options from "../../../../glisten/glisten/socket/options.mjs";
import { ActiveMode, Count } from "../../../../glisten/glisten/socket/options.mjs";
import * as $transport from "../../../../glisten/glisten/transport.mjs";
import * as $logging from "../../../../logging/logging.mjs";
import * as $websocks from "../../../../websocks/websocks.mjs";
import { CustomType as $CustomType } from "../../../gleam.mjs";

export class WebsocketConnection extends $CustomType {
  constructor(transport, socket, context) {
    super();
    this.transport = transport;
    this.socket = socket;
    this.context = context;
  }
}
export const WebsocketConnection$WebsocketConnection = (transport, socket, context) =>
  new WebsocketConnection(transport, socket, context);
export const WebsocketConnection$isWebsocketConnection = (value) =>
  value instanceof WebsocketConnection;
export const WebsocketConnection$WebsocketConnection$transport = (value) =>
  value.transport;
export const WebsocketConnection$WebsocketConnection$0 = (value) =>
  value.transport;
export const WebsocketConnection$WebsocketConnection$socket = (value) =>
  value.socket;
export const WebsocketConnection$WebsocketConnection$1 = (value) =>
  value.socket;
export const WebsocketConnection$WebsocketConnection$context = (value) =>
  value.context;
export const WebsocketConnection$WebsocketConnection$2 = (value) =>
  value.context;

export class Frame extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const WebsocketMessage$Frame = ($0) => new Frame($0);
export const WebsocketMessage$isFrame = (value) => value instanceof Frame;
export const WebsocketMessage$Frame$0 = (value) => value[0];

export class UserMessage extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const WebsocketMessage$UserMessage = ($0) => new UserMessage($0);
export const WebsocketMessage$isUserMessage = (value) =>
  value instanceof UserMessage;
export const WebsocketMessage$UserMessage$0 = (value) => value[0];

export class Continue extends $CustomType {
  constructor(user_state, selector) {
    super();
    this.user_state = user_state;
    this.selector = selector;
  }
}
export const WebsocketNext$Continue = (user_state, selector) =>
  new Continue(user_state, selector);
export const WebsocketNext$isContinue = (value) => value instanceof Continue;
export const WebsocketNext$Continue$user_state = (value) => value.user_state;
export const WebsocketNext$Continue$0 = (value) => value.user_state;
export const WebsocketNext$Continue$selector = (value) => value.selector;
export const WebsocketNext$Continue$1 = (value) => value.selector;

export class NormalStop extends $CustomType {}
export const WebsocketNext$NormalStop = () => new NormalStop();
export const WebsocketNext$isNormalStop = (value) =>
  value instanceof NormalStop;

export class AbnormalStop extends $CustomType {
  constructor(reason) {
    super();
    this.reason = reason;
  }
}
export const WebsocketNext$AbnormalStop = (reason) => new AbnormalStop(reason);
export const WebsocketNext$isAbnormalStop = (value) =>
  value instanceof AbnormalStop;
export const WebsocketNext$AbnormalStop$reason = (value) => value.reason;
export const WebsocketNext$AbnormalStop$0 = (value) => value.reason;

class WebsocketState extends $CustomType {
  constructor(user_state, context) {
    super();
    this.user_state = user_state;
    this.context = context;
  }
}

class Packet extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}

class Close extends $CustomType {}

class TcpPassive extends $CustomType {}

class User extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}

class Invalid extends $CustomType {}

class ResolveState extends $CustomType {
  constructor(socket, transport, handler, next) {
    super();
    this.socket = socket;
    this.transport = transport;
    this.handler = handler;
    this.next = next;
  }
}

const malformed = "Received malformed message";

const crashed = "Crash in websocket handler";

const failed_pong = "Failed to send PONG frame";

const non_owning_process = "Sending WebSocket message from non-owning process";

const socket_active_count = 100;
