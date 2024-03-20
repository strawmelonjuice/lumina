use std::time::Duration;

use async_std::task;

use crate::log::info;

pub(crate) async fn main(i: u64) {
    let mut o = 0;
    loop {
        o += 1;
        info(format!(
            "Polling from listed instances, round {o}. Pollings are done every {i} seconds."
        ));
        // Here.
        task::sleep(Duration::from_secs(i.into())).await;
    }
}
