use std::time::Duration;

use async_std::task;
pub(crate) async fn main(mut i: u64) {
    let mut o = 0;
    if i < 30 {
        i = 120
    };
    loop {
        o += 1;
        info!("Polling from listed instances, round {o}. Pollings are done every {i} seconds.");
        // Here.
        task::sleep(Duration::from_secs(i)).await;
    }
}
