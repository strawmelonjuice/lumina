{application, mist, [
    {mod, {'mist@internal@clock', []}},
    {vsn, "6.0.2"},
    {applications, [exception,
                    gleam_erlang,
                    gleam_http,
                    gleam_otp,
                    gleam_stdlib,
                    glisten,
                    gramps,
                    hpack,
                    logging]},
    {description, "a misty Gleam web server"},
    {modules, []},
    {registered, []}
]}.
