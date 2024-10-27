import gleam/option
import gleam/result
import lumina/data/context.{type Context}
import lumina/users
import simplifile as fs
import wisp

pub fn anonymous(ctx: Context) {
  [
    fs.read(ctx.priv_directory <> "/static/svg/avatar1.svg"),
    fs.read(ctx.priv_directory <> "/static/svg/avatar2.svg"),
    fs.read(ctx.priv_directory <> "/static/svg/avatar3.svg"),
    fs.read(ctx.priv_directory <> "/static/svg/avatar4.svg"),
    fs.read(ctx.priv_directory <> "/static/svg/avatar5.svg"),
    fs.read(ctx.priv_directory <> "/static/svg/avatar6.svg"),
  ]
  |> result.all
  |> result.map_error(fn(_) { Nil })
}

pub fn get(_ctx: Context, _user: users.User) {
  wisp.log_warning("Avatars getter not yet implemented")
  option.None
}
