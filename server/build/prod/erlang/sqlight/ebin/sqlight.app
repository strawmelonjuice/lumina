{application, sqlight, [
    {vsn, "1.0.3"},
    {applications, [esqlite,
                    gleam_stdlib]},
    {description, "Use SQLite from Gleam!"},
    {modules, [sqlight,
               sqlight_ffi]},
    {registered, []}
]}.
