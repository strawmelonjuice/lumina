pub enum PageType {
    General {
        description: String,
        image: String,
    },
    Article {
        summary: String,
        author: String,
        published_time: String,
        modified_time: String,
        expiration_time: String,
        section: String,
        tag: String,
    },
    Media {
        mime_type: String,
        media_url: String,
    },
}

pub struct UrlMetaTags {
    pub title: String,
    pub description: String,
    pub image: String,
    pub page: PageType,
}
impl UrlMetaTags {
    fn get(&self, url: String) {
        
    }
}