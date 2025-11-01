✅ Implemented in PR [#2](https://git.strawmelonjuice.com/strawmelonjuice/Lumina/pulls/2)
In the past, I've worked with mostly SQLite because it made development easy. Since the introduction of Redis as cache, Podman is always somehow involved in the development run, be it to provide the entire environment or to just run the Redis Server.

There is no more real advantage of using SQLite for development, and instead it places a (relatively small) burden on the developer to abstract inconsistencies away.

Which is why I decided for Lumina to stop supporting SQLite as a whole.
