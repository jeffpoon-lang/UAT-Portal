//! uat-seal：將 UAT sign-off 記錄鎖死成一條 hash chain。
//!
//! 每條記錄嘅 digest = SHA-256(上一條 digest + "\n" + 今次 payload)。
//! 改過任何一條舊記錄，佢之後所有 digest 都會對唔上，所以一驗就知。
//!
//! 用法：
//!   echo '<payload json>' | uat-seal seal <prev_digest>
//!   第一條記錄冇上一條，prev_digest 用 GENESIS。

use sha2::{Digest, Sha256};
use std::io::{self, Read};
use std::process::ExitCode;

const GENESIS: &str = "GENESIS";

fn main() -> ExitCode {
    let args: Vec<String> = std::env::args().collect();

    match args.get(1).map(String::as_str) {
        Some("seal") => {
            let prev = args.get(2).map(String::as_str).unwrap_or(GENESIS);
            if !is_valid_prev(prev) {
                eprintln!("prev_digest 要係 GENESIS 或者 64 位小楷 hex");
                return ExitCode::from(2);
            }

            let mut payload = String::new();
            if let Err(e) = io::stdin().read_to_string(&mut payload) {
                eprintln!("讀唔到 stdin：{e}");
                return ExitCode::from(1);
            }

            println!("{}", seal(prev, payload.trim()));
            ExitCode::SUCCESS
        }
        _ => {
            eprintln!("usage: uat-seal seal <prev_digest|GENESIS>  (payload 經 stdin)");
            ExitCode::from(2)
        }
    }
}

/// 計今次記錄嘅 digest，將上一條 digest 一齊 hash 入去，形成 chain。
fn seal(prev: &str, payload: &str) -> String {
    let mut h = Sha256::new();
    h.update(prev.as_bytes());
    h.update(b"\n");
    h.update(payload.as_bytes());
    format!("{:x}", h.finalize())
}

/// 防止打錯字：prev 一係 GENESIS，一係一個真 digest。
fn is_valid_prev(prev: &str) -> bool {
    prev == GENESIS || (prev.len() == 64 && prev.bytes().all(|b| b.is_ascii_digit() || (b'a'..=b'f').contains(&b)))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn same_input_same_digest() {
        assert_eq!(seal(GENESIS, r#"{"a":1}"#), seal(GENESIS, r#"{"a":1}"#));
    }

    #[test]
    fn digest_is_64_hex_chars() {
        let d = seal(GENESIS, "x");
        assert_eq!(d.len(), 64);
        assert!(is_valid_prev(&d));
    }

    #[test]
    fn changing_payload_changes_digest() {
        assert_ne!(seal(GENESIS, r#"{"result":"pass"}"#), seal(GENESIS, r#"{"result":"fail"}"#));
    }

    #[test]
    fn chain_breaks_when_old_record_is_edited() {
        // 原本兩條記錄
        let d1 = seal(GENESIS, "round 1: TC-01 pass");
        let d2 = seal(&d1, "round 2: TC-01 pass");

        // 有人偷偷改咗第一條
        let d1_tampered = seal(GENESIS, "round 1: TC-01 fail");
        let d2_recomputed = seal(&d1_tampered, "round 2: TC-01 pass");

        assert_ne!(d2, d2_recomputed, "改舊記錄之後，下一條 digest 應該對唔上");
    }

    #[test]
    fn rejects_bad_prev() {
        assert!(!is_valid_prev("abc"));
        assert!(!is_valid_prev(&"G".repeat(64)));
    }
}
