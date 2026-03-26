import * as $process from "../../../../gleam_erlang/gleam/erlang/process.mjs";
import * as $response from "../../../../gleam_http/gleam/http/response.mjs";
import * as $actor from "../../../../gleam_otp/gleam/otp/actor.mjs";
import * as $bit_array from "../../../../gleam_stdlib/gleam/bit_array.mjs";
import * as $bytes_tree from "../../../../gleam_stdlib/gleam/bytes_tree.mjs";
import * as $result from "../../../../gleam_stdlib/gleam/result.mjs";
import * as $glisten from "../../../../glisten/glisten.mjs";
import * as $socket from "../../../../glisten/glisten/socket.mjs";
import * as $transport from "../../../../glisten/glisten/transport.mjs";
import * as $logging from "../../../../logging/logging.mjs";
import * as $encoder from "../../../ewe/internal/encoder.mjs";
import { CustomType as $CustomType } from "../../../gleam.mjs";

export class ChunkedBody extends $CustomType {
  constructor(transport, socket) {
    super();
    this.transport = transport;
    this.socket = socket;
  }
}
export const ChunkedBody$ChunkedBody = (transport, socket) =>
  new ChunkedBody(transport, socket);
export const ChunkedBody$isChunkedBody = (value) =>
  value instanceof ChunkedBody;
export const ChunkedBody$ChunkedBody$transport = (value) => value.transport;
export const ChunkedBody$ChunkedBody$0 = (value) => value.transport;
export const ChunkedBody$ChunkedBody$socket = (value) => value.socket;
export const ChunkedBody$ChunkedBody$1 = (value) => value.socket;

export class Continue extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const ChunkedNext$Continue = ($0) => new Continue($0);
export const ChunkedNext$isContinue = (value) => value instanceof Continue;
export const ChunkedNext$Continue$0 = (value) => value[0];

export class NormalStop extends $CustomType {}
export const ChunkedNext$NormalStop = () => new NormalStop();
export const ChunkedNext$isNormalStop = (value) => value instanceof NormalStop;

export class AbnormalStop extends $CustomType {
  constructor(reason) {
    super();
    this.reason = reason;
  }
}
export const ChunkedNext$AbnormalStop = (reason) => new AbnormalStop(reason);
export const ChunkedNext$isAbnormalStop = (value) =>
  value instanceof AbnormalStop;
export const ChunkedNext$AbnormalStop$reason = (value) => value.reason;
export const ChunkedNext$AbnormalStop$0 = (value) => value.reason;
