import * as $atom from "../../../gleam_erlang/gleam/erlang/atom.mjs";
import * as $process from "../../../gleam_erlang/gleam/erlang/process.mjs";
import * as $actor from "../../../gleam_otp/gleam/otp/actor.mjs";
import * as $factory from "../../../gleam_otp/gleam/otp/factory_supervisor.mjs";
import * as $supervisor from "../../../gleam_otp/gleam/otp/static_supervisor.mjs";
import * as $supervision from "../../../gleam_otp/gleam/otp/supervision.mjs";
import * as $int from "../../../gleam_stdlib/gleam/int.mjs";
import * as $option from "../../../gleam_stdlib/gleam/option.mjs";
import { None } from "../../../gleam_stdlib/gleam/option.mjs";
import * as $result from "../../../gleam_stdlib/gleam/result.mjs";
import * as $logging from "../../../logging/logging.mjs";
import { CustomType as $CustomType } from "../../gleam.mjs";
import * as $handler from "../../glisten/internal/handler.mjs";
import { Handler, Internal, Ready } from "../../glisten/internal/handler.mjs";
import * as $listener from "../../glisten/internal/listener.mjs";
import * as $socket from "../../glisten/socket.mjs";
import * as $options from "../../glisten/socket/options.mjs";
import * as $transport from "../../glisten/transport.mjs";

export class AcceptConnection extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const AcceptorMessage$AcceptConnection = ($0) =>
  new AcceptConnection($0);
export const AcceptorMessage$isAcceptConnection = (value) =>
  value instanceof AcceptConnection;
export const AcceptorMessage$AcceptConnection$0 = (value) => value[0];

export class AcceptError extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const AcceptorError$AcceptError = ($0) => new AcceptError($0);
export const AcceptorError$isAcceptError = (value) =>
  value instanceof AcceptError;
export const AcceptorError$AcceptError$0 = (value) => value[0];

export class HandlerError extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const AcceptorError$HandlerError = ($0) => new HandlerError($0);
export const AcceptorError$isHandlerError = (value) =>
  value instanceof HandlerError;
export const AcceptorError$HandlerError$0 = (value) => value[0];

export class ControlError extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const AcceptorError$ControlError = ($0) => new ControlError($0);
export const AcceptorError$isControlError = (value) =>
  value instanceof ControlError;
export const AcceptorError$ControlError$0 = (value) => value[0];

export class AcceptorState extends $CustomType {
  constructor(sender, socket, transport) {
    super();
    this.sender = sender;
    this.socket = socket;
    this.transport = transport;
  }
}
export const AcceptorState$AcceptorState = (sender, socket, transport) =>
  new AcceptorState(sender, socket, transport);
export const AcceptorState$isAcceptorState = (value) =>
  value instanceof AcceptorState;
export const AcceptorState$AcceptorState$sender = (value) => value.sender;
export const AcceptorState$AcceptorState$0 = (value) => value.sender;
export const AcceptorState$AcceptorState$socket = (value) => value.socket;
export const AcceptorState$AcceptorState$1 = (value) => value.socket;
export const AcceptorState$AcceptorState$transport = (value) => value.transport;
export const AcceptorState$AcceptorState$2 = (value) => value.transport;

export class Pool extends $CustomType {
  constructor(handler, pool_count, name, on_init, on_close, transport, active_state) {
    super();
    this.handler = handler;
    this.pool_count = pool_count;
    this.name = name;
    this.on_init = on_init;
    this.on_close = on_close;
    this.transport = transport;
    this.active_state = active_state;
  }
}
export const Pool$Pool = (handler, pool_count, name, on_init, on_close, transport, active_state) =>
  new Pool(handler, pool_count, name, on_init, on_close, transport, active_state);
export const Pool$isPool = (value) => value instanceof Pool;
export const Pool$Pool$handler = (value) => value.handler;
export const Pool$Pool$0 = (value) => value.handler;
export const Pool$Pool$pool_count = (value) => value.pool_count;
export const Pool$Pool$1 = (value) => value.pool_count;
export const Pool$Pool$name = (value) => value.name;
export const Pool$Pool$2 = (value) => value.name;
export const Pool$Pool$on_init = (value) => value.on_init;
export const Pool$Pool$3 = (value) => value.on_init;
export const Pool$Pool$on_close = (value) => value.on_close;
export const Pool$Pool$4 = (value) => value.on_close;
export const Pool$Pool$transport = (value) => value.transport;
export const Pool$Pool$5 = (value) => value.transport;
export const Pool$Pool$active_state = (value) => value.active_state;
export const Pool$Pool$6 = (value) => value.active_state;
