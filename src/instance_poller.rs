/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */

use std::time::Duration;

use async_std::task;
pub(crate) async fn main(mut i: u64, tell: fn(String)) {
    let mut o = 0;
    if i < 30 {
        i = 120
    };
    loop {
        o += 1;
        tell(format!("Poller: Polling from listed instances, round {o}. Pollings are done every {i} seconds."));
        // Here.
        tell(String::from("Poller: Poll done."));
        task::sleep(Duration::from_secs(i)).await;
    }
}
