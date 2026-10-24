//! uat-seal：將 UAT sign-off 記錄鎖死成一條 hash chain。
//!
//! 每條記錄嘅 digest = SHA-256(上一條 digest + "\n" + 今次 payload)。
//! 改過任何一條舊記錄，佢之後所有 digest 都會對唔上，所以一驗就知。
//!
//! 用法：
//!   echo '<payload json>' | uat-seal seal <prev_digest|GENESIS>
//!   uat-seal verify < records.tsv
//!     每行一條記錄，由第一條開始：digest<TAB>prev_digest<TAB>payload_json
//!     全部啱 → 印 "OK <條數>"，exit 0
//!     有問題 → 印 "BROKEN <第幾條> <原因>"，exit 1

use sha2::{Digest, Sha256};
use std::io::{self, Read};
use std::process::ExitCode;

const GENESIS: &str = "GENESIS";

fn main() -> ExitCode {
    let args: Vec<String> = std::env::args().collect();

    let mut input = String::new();
    let cmd = args.get(1).map(String::as_str);
    if matches!(cmd, Some("seal") | Some("verify"))
        && let Err(e) = io::stdin().read_to_string(&mut input)
    {
        eprintln!("讀唔到 stdin：{e}");
        return ExitCode::from(1);
    }

    match cmd {
        Some("seal") => {
            let prev = args.get(2).map(String::as_str).unwrap_or(GENESIS);
            if !is_valid_prev(prev) {
                eprintln!("prev_digest 要係 GENESIS 或者 64 位小楷 hex");
                return ExitCode::from(2);
            }
            println!("{}", seal(prev, input.trim()));
            ExitCode::SUCCESS
        }
        Some("verify") => match verify(&input) {
            Ok(n) => {
                println!("OK {n}");
                ExitCode::SUCCESS
            }
            Err(Broken { index, reason }) => {
                println!("BROKEN {index} {reason}");
                ExitCode::from(1)
            }
        },
        _ => {
            eprintln!("usage: uat-seal seal <prev_digest|GENESIS>  (payload 經 stdin)");
            eprintln!("       uat-seal verify  (digest<TAB>prev<TAB>payload 每行一條，經 stdin)");
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
    prev == GENESIS
        || (prev.len() == 64
            && prev
                .bytes()
                .all(|b| b.is_ascii_digit() || (b'a'..=b'f').contains(&b)))
}

#[derive(Debug, PartialEq)]
struct Broken {
    /// 第幾條記錄出事（由 1 開始數）
    index: usize,
    reason: &'static str,
}

/// 由頭驗到尾，返回驗咗幾多條，或者第一條出事嘅記錄。
fn verify(input: &str) -> Result<usize, Broken> {
    let mut expected_prev = GENESIS.to_string();
    let mut count = 0;

    for (i, line) in input.lines().filter(|l| !l.is_empty()).enumerate() {
        let index = i + 1;
        let mut parts = line.splitn(3, '\t');
        let (Some(digest), Some(prev), Some(payload)) = (parts.next(), parts.next(), parts.next())
        else {
            return Err(Broken {
                index,
                reason: "format_error",
            });
        };

        // 記錄自己話嘅上一條，要同真正上一條一致：防止有人刪走或者調亂記錄
        if prev != expected_prev {
            return Err(Broken {
                index,
                reason: "prev_mismatch",
            });
        }
        // 用內容重新計一次，要同存咗嘅 digest 一樣：防止有人改內容
        if seal(prev, payload) != digest {
            return Err(Broken {
                index,
                reason: "digest_mismatch",
            });
        }

        expected_prev = digest.to_string();
        count = index;
    }

    Ok(count)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn chain(payloads: &[&str]) -> Vec<(String, String, String)> {
        let mut prev = GENESIS.to_string();
        payloads
            .iter()
            .map(|p| {
                let d = seal(&prev, p);
                let row = (d.clone(), prev.clone(), p.to_string());
                prev = d;
                row
            })
            .collect()
    }

    fn tsv(rows: &[(String, String, String)]) -> String {
        rows.iter()
            .map(|(d, p, j)| format!("{d}\t{p}\t{j}\n"))
            .collect()
    }

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
        assert_ne!(
            seal(GENESIS, r#"{"result":"pass"}"#),
            seal(GENESIS, r#"{"result":"fail"}"#)
        );
    }

    #[test]
    fn rejects_bad_prev() {
        assert!(!is_valid_prev("abc"));
        assert!(!is_valid_prev(&"G".repeat(64)));
    }

    #[test]
    fn verify_accepts_an_intact_chain() {
        let rows = chain(&["a", "b", "c"]);
        assert_eq!(verify(&tsv(&rows)), Ok(3));
    }

    #[test]
    fn verify_accepts_empty_input() {
        assert_eq!(verify(""), Ok(0));
    }

    #[test]
    fn verify_catches_edited_content() {
        let mut rows = chain(&["a", "b", "c"]);
        rows[1].2 = "b-edited".to_string();
        assert_eq!(
            verify(&tsv(&rows)),
            Err(Broken {
                index: 2,
                reason: "digest_mismatch"
            })
        );
    }

    #[test]
    fn verify_catches_a_deleted_record() {
        let mut rows = chain(&["a", "b", "c"]);
        rows.remove(1);
        assert_eq!(
            verify(&tsv(&rows)),
            Err(Broken {
                index: 2,
                reason: "prev_mismatch"
            })
        );
    }

    #[test]
    fn verify_catches_a_recomputed_forgery() {
        // 改咗內容又自己重計 digest：下一條嘅 prev 就會對唔上
        let mut rows = chain(&["a", "b", "c"]);
        rows[0].2 = "a-edited".to_string();
        rows[0].0 = seal(GENESIS, "a-edited");
        assert_eq!(
            verify(&tsv(&rows)),
            Err(Broken {
                index: 2,
                reason: "prev_mismatch"
            })
        );
    }

    #[test]
    fn verify_reports_bad_format() {
        assert_eq!(
            verify("only-one-field\n"),
            Err(Broken {
                index: 1,
                reason: "format_error"
            })
        );
    }
}
