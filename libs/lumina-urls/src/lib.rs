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
    Succes(UrlMetaTags),
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
                        match document.select(&selector).next() {
                            Some(elm) => Some(String::from(elm.value().name())),
                            None => None,
                        }
                    },
                    extract("og:title", &document),
                )
                .unwrap_or(String::from("Could not get a title at this time."));
                self = Succes(UrlMetaTags {
                    title,
                    description: onesome(
                        extract("description", &document),
                        extract("og:description", &document),
                    )
                    .unwrap_or(String::from("Could not get a description at this time.")),
                    thumbnail: onesome(extract("og:image", &document), extract("image", &document)),
                    page: General,
                });
                self
            }
        }
    }
}

fn extract(name: &str, document: &Html) -> Option<String> {
    let selector = Selector::parse(format!(r#"meta[name="{}"]"#, name).as_str()).unwrap();
    match document.select(&selector).next() {
        Some(elm) => match elm.value().attr("content") {
            Some(t) => Some(String::from(t)),
            None => None,
        },
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
