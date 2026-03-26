import * as $atom from "../../../../gleam_erlang/gleam/erlang/atom.mjs";
import * as $process from "../../../../gleam_erlang/gleam/erlang/process.mjs";
import * as $response from "../../../../gleam_http/gleam/http/response.mjs";
import * as $actor from "../../../../gleam_otp/gleam/otp/actor.mjs";
import * as $bytes_tree from "../../../../gleam_stdlib/gleam/bytes_tree.mjs";
import * as $int from "../../../../gleam_stdlib/gleam/int.mjs";
import * as $list from "../../../../gleam_stdlib/gleam/list.mjs";
import * as $option from "../../../../gleam_stdlib/gleam/option.mjs";
import * as $result from "../../../../gleam_stdlib/gleam/result.mjs";
import * as $string_tree from "../../../../gleam_stdlib/gleam/string_tree.mjs";
import * as $socket from "../../../../glisten/glisten/socket.mjs";
import * as $options from "../../../../glisten/glisten/socket/options.mjs";
import { Active, ActiveMode } from "../../../../glisten/glisten/socket/options.mjs";
import * as $transport from "../../../../glisten/glisten/transport.mjs";
import * as $encoder from "../../../ewe/internal/encoder.mjs";
import { CustomType as $CustomType } from "../../../gleam.mjs";

export class SSEConnection extends $CustomType {
  constructor(transport, socket) {
    super();
    this.transport = transport;
    this.socket = socket;
  }
}
export const SSEConnection$SSEConnection = (transport, socket) =>
  new SSEConnection(transport, socket);
export const SSEConnection$isSSEConnection = (value) =>
  value instanceof SSEConnection;
export const SSEConnection$SSEConnection$transport = (value) => value.transport;
export const SSEConnection$SSEConnection$0 = (value) => value.transport;
export const SSEConnection$SSEConnection$socket = (value) => value.socket;
export const SSEConnection$SSEConnection$1 = (value) => value.socket;

export class Continue extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const SSENext$Continue = ($0) => new Continue($0);
export const SSENext$isContinue = (value) => value instanceof Continue;
export const SSENext$Continue$0 = (value) => value[0];

export class NormalStop extends $CustomType {}
export const SSENext$NormalStop = () => new NormalStop();
export const SSENext$isNormalStop = (value) => value instanceof NormalStop;

export class AbnormalStop extends $CustomType {
  constructor(reason) {
    super();
    this.reason = reason;
  }
}
export const SSENext$AbnormalStop = (reason) => new AbnormalStop(reason);
export const SSENext$isAbnormalStop = (value) => value instanceof AbnormalStop;
export const SSENext$AbnormalStop$reason = (value) => value.reason;
export const SSENext$AbnormalStop$0 = (value) => value.reason;

export class User extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const SSEMessages$User = ($0) => new User($0);
export const SSEMessages$isUser = (value) => value instanceof User;
export const SSEMessages$User$0 = (value) => value[0];

export class Close extends $CustomType {}
export const SSEMessages$Close = () => new Close();
export const SSEMessages$isClose = (value) => value instanceof Close;

export class SSEEvent extends $CustomType {
  constructor(event, data, id, retry) {
    super();
    this.event = event;
    this.data = data;
    this.id = id;
    this.retry = retry;
  }
}
export const SSEEvent$SSEEvent = (event, data, id, retry) =>
  new SSEEvent(event, data, id, retry);
export const SSEEvent$isSSEEvent = (value) => value instanceof SSEEvent;
export const SSEEvent$SSEEvent$event = (value) => value.event;
export const SSEEvent$SSEEvent$0 = (value) => value.event;
export const SSEEvent$SSEEvent$data = (value) => value.data;
export const SSEEvent$SSEEvent$1 = (value) => value.data;
export const SSEEvent$SSEEvent$id = (value) => value.id;
export const SSEEvent$SSEEvent$2 = (value) => value.id;
export const SSEEvent$SSEEvent$retry = (value) => value.retry;
export const SSEEvent$SSEEvent$3 = (value) => value.retry;

/**
 * Formats a field and value for a Server-Sent Events event.
 * 
 * @ignore
 */
function format(field, value) {
  return ((field + ": ") + value) + "\n";
}
