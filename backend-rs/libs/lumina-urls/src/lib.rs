/*
 * Copyright (c) 2024, MLC 'Strawmelonjuice' Bloeiman
 *
 * Licensed under the BSD 3-Clause License. See the LICENSE file for more info.
 */

use crate::PageType::General;
use crate::UrlMetaInfo::{Fail, Succes};
use scraper::{Html, Selector};

pub enum PageType {
    General,
    Article {
        summary: Option<String>,
        author: Option<String>,
        published_time: Option<String>,
        modified_time: Option<String>,
        expiration_time: Option<String>,
        section: Option<String>,
        tag: Option<String>,
    },
    Media {
        mime_type: Option<String>,
        media_url: Option<String>,
    },
}
pub struct UrlMetaTags {
    pub title: String,
    pub description: String,
    pub thumbnail: Option<String>,
    pub page: PageType,
}
pub enum UrlMetaInfo {
    Succes(Box<UrlMetaTags>),
    Fail,
    Unset,
}

impl UrlMetaInfo {
    pub fn get(mut self, url: String) -> UrlMetaInfo {
        match self {
            Succes(_) | Fail => self,
            UrlMetaInfo::Unset => {
                let html = match reqwest::blocking::get(url) {
                    Ok(w) => match w.text() {
                        Ok(o) => o,
                        Err(_) => {
                            self = Fail;
                            return self;
                        }
                    },
                    Err(_) => {
                        self = Fail;
                        return self;
                    }
                };
                let document = Html::parse_document(&html);
                let title = onesome(
                    {
                        let selector = Selector::parse("title").unwrap();
                        document
                            .select(&selector)
                            .next()
                            .map(|elm| String::from(elm.value().name()))
                    },
                    extract("og:title", &document),
                )
                .unwrap_or(String::from("Could not get a title at this time."));
                self = Succes(Box::from(UrlMetaTags {
                    title,
                    description: onesome(
                        extract("description", &document),
                        extract("og:description", &document),
                    )
                    .unwrap_or(String::from("Could not get a description at this time.")),
                    thumbnail: onesome(extract("og:image", &document), extract("image", &document)),
                    page: General,
                }));
                self
            }
        }
    }
}

fn extract(name: &str, document: &Html) -> Option<String> {
    let selector = Selector::parse(format!(r#"meta[name="{}"]"#, name).as_str()).unwrap();
    match document.select(&selector).next() {
        Some(elm) => elm.value().attr("content").map(String::from),
        None => None,
    }
}

/// Out of two `Option<T>`'s, picks the one containing a `Some(T)`.
/// If both have `Some`, `a` will be preferred. If both have `None`, `None` will be returned.
fn onesome<T>(a: Option<T>, b: Option<T>) -> Option<T> {
    match a {
        Some(aa) => Some(aa),
        None => b,
    }
}
