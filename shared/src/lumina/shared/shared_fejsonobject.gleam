// Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
// Licensed under the BSD 3-Clause License. See the LICENSE file for more info.

import lumina/shared/shared_users

pub type FEJsonObjInstanceInfo {
  FEJsonObjInstanceInfo(iid: String, last_sync: Int)
}

pub type FEJSonObj {
  FEJSonObj(
    pulled: Int,
    instance: FEJsonObjInstanceInfo,
    user: shared_users.SafeUser,
  )
}
