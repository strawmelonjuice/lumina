import * as $process from "../../../gleam_erlang/gleam/erlang/process.mjs";
import * as $request from "../../../gleam_http/gleam/http/request.mjs";
import * as $response from "../../../gleam_http/gleam/http/response.mjs";
import * as $actor from "../../../gleam_otp/gleam/otp/actor.mjs";
import * as $factory from "../../../gleam_otp/gleam/otp/factory_supervisor.mjs";
import * as $bytes_tree from "../../../gleam_stdlib/gleam/bytes_tree.mjs";
import * as $option from "../../../gleam_stdlib/gleam/option.mjs";
import { Some } from "../../../gleam_stdlib/gleam/option.mjs";
import * as $glisten from "../../../glisten/glisten.mjs";
import * as $transport from "../../../glisten/glisten/transport.mjs";
import * as $logging from "../../../logging/logging.mjs";
import * as $ewe_http from "../../ewe/internal/http1.mjs";
import * as $http1_handler from "../../ewe/internal/http1/handler.mjs";
import { CustomType as $CustomType } from "../../gleam.mjs";

export class Http1 extends $CustomType {
  constructor(state, self) {
    super();
    this.state = state;
    this.self = self;
  }
}
export const Handler$Http1 = (state, self) => new Http1(state, self);
export const Handler$isHttp1 = (value) => value instanceof Http1;
export const Handler$Http1$state = (value) => value.state;
export const Handler$Http1$0 = (value) => value.state;
export const Handler$Http1$self = (value) => value.self;
export const Handler$Http1$1 = (value) => value.self;
