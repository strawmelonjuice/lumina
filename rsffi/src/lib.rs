#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn markdown_to_html() {
        let result = intern::i_md_render_to_html(String::from("*Hello, world!*"));
        assert_eq!(result, Ok("<p><em>Hello, world!</em></p>".to_string()));
    }
}

mod intern {
    pub fn i_md_render_to_html(unprocessed_md: String) -> Result<String, ()> {
        let processed_md = match markdown::to_html_with_options(
            unprocessed_md.as_str(),
            &markdown::Options::gfm(),
        ) {
            Ok(html) => html,
            Err(_) => {
                return Err(());
            }
        };
        let readied_html = processed_md
			.replace(r#"<img "#, r#"<img class="max-w-9/12" "#)
			.replace(r#"<a "#, r#"<a class="text-blue-400" "#)
			.replace(r#"<code>"#, r#"<code class="m-1 text-stone-500 bg-slate-200 dark:text-stone-200 dark:bg-slate-600">"#)
			.replace(r#"<blockquote>"#, r#"<blockquote class="p-0 [&>*]:pl-2 ml-3 mr-3 border-gray-300 border-s-4 bg-gray-50 dark:border-gray-500 dark:bg-gray-800">"#);
        Ok(readied_html)
    }
}

#[rustler::nif]
pub fn add(left: u64, right: u64) -> u64 {
    left + right
}

#[rustler::nif]
pub fn md_render_to_html(unprocessed_md: String) -> Result<String, ()> {
    intern::i_md_render_to_html(unprocessed_md)
}

rustler::init!("rsffi");
