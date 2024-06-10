/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */
//! This module contains the inter-instance api's. It will mostly be used for pulling from other instances and syncing.
use std::time::Duration;

use crate::LuminaConfig;
use async_std::task;

pub(crate) async fn main(j: LuminaConfig, tell: fn(String)) {
    let mut o = 0;
    let mut i = j.interinstance.polling.pollintervall;
    if i < 30 {
        i = 120
    };
    let a = j.interinstance.synclist.len();
    if a == 0 {
        tell("Poller: No instances to poll from are listed. Poller will close until further notice to preserve CPU threads.".to_string());
        return;
    }
    let s = if a == 1 { "" } else { "s" };
    loop {
        o += 1;
        tell(format!("Poller: Polling from {a} listed instance{s}, round {o}. Pollings are done every {i} seconds."));
        // Here.
        tell(String::from("Poller: Polls done."));
        task::sleep(Duration::from_secs(i)).await;
    }
}
