/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */
//! This module contains the inter-instance api's. It will mostly be used for pulling from other instances and syncing.

use std::time::Duration;

use crate::{LuminaConfig, ServerVars, SynclistItem};
use indicatif::{MultiProgress, ProgressBar, ProgressStyle};
use tokio::time::sleep;

pub(crate) async fn main(vars: ServerVars) {
    let progressbars = MultiProgress::new();
    let config: LuminaConfig = vars.config.clone();
    let mut round = 0;
    let mut sync_interval = config.interinstance.syncing.syncintervall;
    if sync_interval < 30 {
        sync_interval = 120
    };
    // count before starting to sync
    let initial_waiting_time = sync_interval / 3;
    println!(
        "{}",
        vars.format_tell(format!(
            "Syncer: Syncing will start in {initial_waiting_time} seconds."
        ))
        .as_str()
    );
    let waiting_counter = progressbars.add(ProgressBar::new(initial_waiting_time));
    waiting_counter.enable_steady_tick(Duration::from_secs(1));
    waiting_counter.set_style(
        ProgressStyle::with_template("{bar:60.white} {pos:>7}/{len:7} {msg}")
            .unwrap()
            .progress_chars("██░"),
    );
    let mut remaining_waiting_time = initial_waiting_time;
    for _ in 0..initial_waiting_time {
        remaining_waiting_time -= 1;
        waiting_counter.inc(1);
        waiting_counter
            .set_message(vars.format_tell(format!("{} seconds left.", remaining_waiting_time)));
        sleep(Duration::from_secs(1)).await;
    }
    let number_of_instances: u64 = config.interinstance.synclist.len() as u64;
    if number_of_instances == 0 {
        waiting_counter.println(vars.format_tell("Syncer: No instances to sync from are listed. Syncer will close until further notice to preserve CPU threads."));
        waiting_counter.finish_and_clear();
        return;
    }
    let _s = if number_of_instances == 1 { "" } else { "s" };
    waiting_counter.println(vars.format_tell(format!(
        "Syncer: Syncing from {number_of_instances} listed instance{_s} starting now."
    )));
    waiting_counter.finish_and_clear();
    loop {
        vars.tell(format!("Syncer: Syncing from {number_of_instances} listed instance{_s}, round {round}. Syncings are done every {sync_interval} seconds."));
        round += 1;
        let sync_progress_through_instances =
            progressbars.add(ProgressBar::new(number_of_instances));
        // bar.println(vars.format_tell("Syncing:"));
        sync_progress_through_instances.set_style(
            ProgressStyle::with_template("{bar:60.white} {pos:>7}/{len:7} {msg}")
                .unwrap()
                .progress_chars("██░"),
        );
        for instance in config.interinstance.synclist.iter() {
            sync_progress_through_instances.inc(1);
            sync_progress_through_instances
                .set_message(vars.format_tell(format!("Syncing: {}", instance.name)));
            // let sync_this_instance = MultiProgress::new().insert_after(&sync_progress_through_instances, ProgressBar::new(100));
            // sync_this_instance.set_style(ProgressStyle::with_template("{bar:60.white} {pos:>7}/{len:7} {msg}").unwrap().progress_chars("██░"));
            sync_instance(instance.clone(), config.clone());
            sleep(Duration::from_secs(3)).await;
            // sync_this_instance.finish();
        }
        sync_progress_through_instances.finish_and_clear();
        vars.tell(String::from("Syncer: Sync done."));
        sleep(Duration::from_secs(sync_interval)).await;
    }
}

fn sync_instance(synclist_item: SynclistItem, config: LuminaConfig) {
    // Syncing code here.
    let _ = (synclist_item, config);
    // todo!("Syncing code here.")
}
