use serde::{Deserialize, Serialize};

use crate::database::PostInfo;

#[derive(Debug, Serialize, Deserialize)]
struct PostContentTypeOne {
    content: String,
}
pub fn post_to_html(post: PostInfo) -> String {
    let mut html = String::new();
    html.push_str(format!("<div class=\"post post-lpid-{}\">", post.lpid).as_str());
    html.push_str("<div class=\"postcontent\">");
    html.push_str(
        match post.content_type {
            1 => {
                match serde_json::from_str::<PostContentTypeOne>(&post.content) {
                    Ok(t) => t,
                    Err(_) => PostContentTypeOne {
                        content: String::from("Unable to show this post."),
                    },
                }
                .content
            }
            _ => String::from("Unable to show this post."),
        }
        .as_str(),
    );
    html.push_str("</div>");
    html.push_str("</div>");
    html
}
