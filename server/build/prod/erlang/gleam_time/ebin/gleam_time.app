{application, gleam_time, [
    {vsn, "1.8.0"},
    {applications, [gleam_stdlib]},
    {description, "Work with time in Gleam!"},
    {modules, [gleam@time@calendar,
               gleam@time@duration,
               gleam@time@timestamp,
               gleam_time_ffi]},
    {registered, []}
]}.
