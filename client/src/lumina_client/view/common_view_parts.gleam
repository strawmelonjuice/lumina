import lumina_client/message_type.{type Msg}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn common_view_parts(
  main_body: List(Element(Msg)),
  with_menu menuitems: List(Element(Msg)),
) {
  html.div([attribute.class("font-sans")], [
    html.div(
      [attribute.class("navbar bg-base-100 dark:bg-neutral-800 shadow-sm")],
      [
        html.div([attribute.class("flex-none")], [
          html.button([attribute.class("")], [
            html.img([
              attribute.src("/static/logo.svg"),
              attribute.alt("Lumina logo"),
              attribute.class("h-8"),
            ]),
          ]),
        ]),
        html.div([attribute.class("flex-1")], [
          html.a([attribute.class("btn btn-ghost text-xl font-logo")], [
            element.text("Lumina"),
          ]),
        ]),
        html.div([attribute.class("flex-none")], [
          html.ul(
            [attribute.class("menu menu-horizontal px-1 font-menuitems")],
            menuitems,
          ),
        ]),
      ],
    ),
    html.div(
      [attribute.class("bg-base-200 h-screen max-h-[calc(100vh-4rem)]")],
      main_body,
    ),
  ])
}
