// Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
// Licensed under the BSD 3-Clause License. See the LICENSE file for more info.

import lumina/shared/shared_fejsonobject
import lumina/shared/shared_users

pub type FEJsonObj =
  shared_fejsonobject.FEJSonObj

type FEJsonObjFlat {
  FEJsonObjFlat(
    pulled: Int,
    instance_iid: String,
    instance_lastsync: Int,
    user_username: String,
    user_id: Int,
    user_email: String,
  )
}

pub fn get() -> FEJsonObj {
  let flat = get_flat()
  shared_fejsonobject.FEJSonObj(
    pulled: flat.pulled,
    instance: shared_fejsonobject.FEJsonObjInstanceInfo(
      iid: flat.instance_iid,
      last_sync: flat.instance_lastsync,
    ),
    user: shared_users.SafeUser(
      id: flat.user_id,
      username: flat.user_username,
      email: flat.user_email,
    ),
  )
}

pub fn set(obj: FEJsonObj) -> nil {
  set_flat(FEJsonObjFlat(
    pulled: obj.pulled,
    instance_iid: obj.instance.iid,
    instance_lastsync: obj.instance.last_sync,
    user_id: obj.user.id,
    user_username: obj.user.username,
    user_email: obj.user.email,
  ))
}

@external(javascript, "../../fejson_ffi.ts", "getJsonObj")
fn get_flat() -> FEJsonObjFlat

@external(javascript, "../../fejson_ffi.ts", "setJsonObj")
fn set_flat(obj: FEJsonObjFlat) -> nil

@external(javascript, "../../fejson_ffi.ts", "dateToTimestamp")
pub fn timestamp() -> Int

@external(javascript, "../../fejson_ffi.ts", "queueFejsonFunction")
pub fn register_fejson_function(a: fn() -> nil) -> nil
