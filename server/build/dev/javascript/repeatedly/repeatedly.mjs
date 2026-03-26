import { call, stop, replace as set_function, update_state } from "./repeatedly_ffi.mjs";

export { call, set_function, stop, update_state };

/**
 * Set the repeater state.
 *
 * On Erlang if the repeater message queue is not empty then this message will
 * handled after all other messages.
 *
 * On JavaScript there is no message queue so it will stop immediately, though
 * not interrupt the function callback if currently being executed.
 */
export function set_state(repeater, state) {
  return update_state(repeater, (_) => { return state; });
}
