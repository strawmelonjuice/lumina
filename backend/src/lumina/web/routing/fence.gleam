import gleam/bool
import gleam/dynamic
import gleam/option.{None, Some}
import gleam/result
import lumina/data/context.{type Context}
import lumina/users
import wisp
import wisp_kv_sessions

/// Fence protects a route by checking if the user is logged in. Otherwise, redirects to login.
pub fn fence(
  next: fn(wisp.Request, users.SafeUser) -> wisp.Response,
  req: wisp.Request,
  ctx: Context,
) -> wisp.Response {
  fn(_) {
    wisp.log_notice("Forwarding user (" <> req.host <> ") to login.")
    let _deletion = wisp_kv_sessions.delete_session(ctx.session_config, req)
    wisp.redirect("/login")
  }
  |> shield(next, _, req, ctx)
}

// Shield checks if the user is logged in.
pub fn shield(
  next: fn(wisp.Request, users.SafeUser) -> a,
  otherwise: fn(wisp.Request) -> a,
  req: wisp.Request,
  ctx: Context,
) -> a {
  let user_from_session =
    wisp_kv_sessions.get(ctx.session_config, req, "uid", dynamic.int)
  use <- bool.lazy_guard(user_from_session |> result.is_ok |> bool.negate, fn() {
    let _ = wisp_kv_sessions.delete_session(ctx.session_config, req)
    otherwise(req)
  })
  let uid_option =
    user_from_session
    |> result.unwrap(None)
  case uid_option {
    Some(uid) -> {
      case users.fetch(ctx, uid) {
        Some(user) -> {
          user
          |> users.to_safe_user
          |> next(req, _)
        }
        None -> {
          wisp.log_critical("Session verified user not found in database.")
          otherwise(req)
        }
      }
    }
    None -> {
      otherwise(req)
    }
  }
}
