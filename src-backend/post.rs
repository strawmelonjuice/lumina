/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */

use handlebars::*;
use serde::{Deserialize, Serialize};

use crate::assets::STR_ASSETS_POST_RENDERS_HANDLEBARS;
use crate::database::{unifetch, BasicUserInfo, IIExchangedUserInfo};
use crate::LuminaConfig;

#[derive(Debug, Serialize, Deserialize)]
pub struct PostInfo {
    /// Local Post ID
    pub lpid: i64,
    /// Post ID
    pub pid: i64,
    /// Instance ID - Might not be necessary on local posts. Hence being Option<>;
    pub instance: Option<String>,
    /// Author ID
    pub author_id: i64,
    /// Timestamp (UNIX)
    pub timestamp: i64,
    /// Content type
    // 1: Textual post (json<content: text/plain>)
    // 2: Article textual post (json<header: text/plain, body: text/markdown>)
    // 3: Media post (json<caption: text/markdown, media-id: integer[]>)
    // 4: Repost (json<repost-id: integer, source-instance: text>)
    pub content_type: i32,
    /// Content in JSON, deserialised depending on content_type.
    pub content: String,
    /// Tags
    pub tags: String, // Json<Vec<String>>
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PostPreRenderData {
    pub(crate) posttype: i32,
    pub(crate) author: IIExchangedUserInfo,
    pub(crate) content: String,
    pub(crate) timestamp: i64,
    pub(crate) title: Option<String>,
    pub(crate) embeds: Option<Vec<String>>,
    pub(crate) tags: Vec<String>,
    pub(crate) local: bool,
    button_push: String,
    button_comment: String,
    button_boost: String,
}
impl PostPreRenderData {
    pub fn to_html(&self) -> String {
        let mut handlebars = Handlebars::new();
        handlebars_helper!(num_is_equal: |x: u64, y: u64| x == y);
        handlebars.register_helper("numequal", Box::new(num_is_equal));

        handlebars
            .render_template(STR_ASSETS_POST_RENDERS_HANDLEBARS, self)
            .unwrap_or_else(|e| {
                eprintln!("Error rendering post: {}", e);
                String::from("Error rendering post.")
            })
    }
}

impl PostInfo {
    pub fn to_formatted(&self, config: &LuminaConfig) -> PostPreRenderData {
        let author_u: BasicUserInfo =
            unifetch::<BasicUserInfo>(config, ("id", self.author_id.to_string().as_str()))
                .unwrap_user();

        let author = IIExchangedUserInfo {
            id: self.author_id,
            username: author_u.username,
            instance: self
                .instance
                .clone()
                .unwrap_or(config.interinstance.iid.clone()),
        };
        let content;

        let mut embeds = None;

        let mut title = None;

        match self.content_type {
            1 => {
                #[derive(Serialize, Deserialize)]
                struct TextPost {
                    content: String,
                }

                content = serde_json::from_str::<TextPost>(&self.content)
                    .unwrap()
                    .content;
            }
            2 => {
                #[derive(Serialize, Deserialize)]
                struct ArticlePost {
                    header: String,
                    body: String,
                }

                let article = serde_json::from_str::<ArticlePost>(&self.content).unwrap();
                content = markdown::to_html(&article.body);
                title = Some(article.header);
            }
            3 => {
                #[derive(Serialize, Deserialize)]
                struct MediaPost {
                    caption: String,
                    media_id: Vec<i64>,
                }

                let media = serde_json::from_str::<MediaPost>(&self.content).unwrap();
                content = markdown::to_html(&media.caption);
                embeds = Some(media.media_id.iter().map(|x| x.to_string()).collect());
            }
            4 => {
                #[derive(Serialize, Deserialize)]
                struct Repost {
                    repost_id: i64,
                    source_instance: String,
                }

                let repost = serde_json::from_str::<Repost>(&self.content).unwrap();
                content = format!(
                    "<a href=\"{}/post/{}\">Reposted from {}</a>",
                    repost.source_instance, repost.repost_id, repost.source_instance
                );
            }
            _ => {
                error!("Unknown content type!");
                panic!("Unknown content type!");
            }
        };

        let timestamp = self.timestamp;

        let tags = serde_json::from_str::<Vec<String>>(&self.tags).unwrap();

        let local = self.instance.is_none();

        PostPreRenderData {
            posttype: self.content_type,
            author,
            content,
            timestamp,
            title,
            embeds,
            tags,
            local,
            button_push: crate::assets::STR_ASSETS_BTN_PUSH_SVG
                .replace(r#"height="120""#, r#"height="100%""#)
                .replace(r#"width="120""#, r#"width="100%""#),
            // <svg width="100%" height="100%"  viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
            button_comment: crate::assets::STR_ASSETS_BTN_COMMENT_SVG
                .replace(r#"height="120""#, r#"height="100%""#)
                .replace(r#"width="120""#, r#"width="100%""#),
            button_boost: crate::assets::STR_ASSETS_BTN_BOOST_SVG
                .replace(r#"height="120""#, r#"height="100%""#)
                .replace(r#"width="120""#, r#"width="100%""#),
        }
    }
}
