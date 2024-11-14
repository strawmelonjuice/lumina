// Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
// Licensed under the BSD 3-Clause License. See the LICENSE file for more info.

import lumina/shared/shared_fejsonobject
import lumina/shared/shared_users
import plinth/javascript/date

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

@external(javascript, "../../ffi.mjs", "getJsonObj")
fn get_flat() -> FEJsonObjFlat

@external(javascript, "../../ffi.mjs", "setJsonObj")
fn set_flat(obj: FEJsonObjFlat) -> nil

@external(javascript, "../../ffi.mjs", "dateToTimestamp")
pub fn timestamp() -> Int
