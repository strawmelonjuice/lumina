# Contributing to Lumina/Peonies

Excited to see you on this document, because it likely means you'd like to contribute!

This project has a few _how_s, nothing too complicated, about how you should contribute to it.

## How to contribute to Lumina/Peonies

Before committing anything to this project in _code_, make sure you're comfortable doing so.
If not, then [filing an issue](#filing-an-issue) is also fine! If you plan on becoming more comfortable with the code,
you are encouraged to ask for the technical details behind how your issue is fixed.

If you are going to contribute in the form of changes to code or other files, here's how you should do it:

### 1. Forking

You start off by forking the repository from
[https://tangled.org/strawmelonjuice.com/Lumina](https://tangled.org/did:plc:dlfsjwtiq5zklprcrmhjxlsq).

### 2. Branches

If there is no [issue](https://tangled.org/did:plc:dlfsjwtiq5zklprcrmhjxlsq/issues) for your PR to solve (or an existing issue is marked as [`out-planned`](#tag-out-planned)), make sure to commit your
changes to a feature branch. If your commit is a planned one in any other way, or is just part of the currently ongoing
development work (ongoing development work means core contributors, strawmelonjuice, committing to the development
branch directly), your fork should just be rebased onto the development branch and you won't have to create any branches
on your fork.

### 3. Committing changes

#### Language use in documents, discussion and file comments
Lumina tries to standardise its English to common British spelling for consistency, this may fail in places and this
may not always be checked properly, but you are encouraged to file issues for this, and above all try to keep this in.

#### Commit style

Commits should, where possible be held to the conventional committing style. I personally like [this
reference](https://gist.github.com/qoomon/5dfcdf8eec66a051ecd85625518cfd13) (partially) quite a bit.

| What have you done?                         | Commit message prefix |
| ------------------------------------------- | --------------------- |
| Bug fix?	                               | `fix:`               |
| New or changed feature in API/UI?           | `feat:`              |
| Performance improvement?                    | `perf:`              |
| Code restructuring without behavior change? | `refactor:`          |
| Formatting only?						 | `style:`             |
| Tests added/corrected?					 | `test:`			|
| CI workflow modified/added/corrected					 | `ci:`			|
| Documentation only?					 | `docs:`			|
| Build tools, dependencies, versions?		 | `build:`			|
| DevOps, infrastructure, or backups?		 | `ops:`			|
| Anything else						 | `chore:`			|

Where applicable and preferred, you can use scopes like (examples) `ci(test): Created an action to test for x` 
or `style(database): Scheme now includes a whitespace before SELECT`.

While following this can make commits easier to categorise, for bigger groups of changes (usually branched changes in
this case) that may be squashed, it's completely understandable not to follow this.

Overall, Lumina also prefers blog-style commit messages, that have a first line as a short version and after a blank line
a longer explanation and maybe even journey to how this commit was made. This is more or less required for squashed
commits or bigger commits that may otherwise create some ambiguity. Of course, a PR will likely also contain a longer
description and you may just write it all out there.

#### Souls

Lumina, and most other projects have a philosophy on the use of AI and other tooling in contributing to the project.

For Lumina, a commit is a commitment. This means indeed, we want as many _humans_ to have touched our code as possible.
Automated ways of creating code are considered a disappointment or a failure to compel a contributor to get their
hands dirty. You are required to clearly state any form of automated help you may have received in creating your
contribution.
Also, make sure that if your tool includes telemetry, it doesn't accidentally violate our [licence](./LICENCE).

> Note:
> 
> You may not have English as your first language or may not be good at spelling. Using a translation tool or a spellchecker 
> is NEVER a bad thing! But please, if you use any non-LLM based tool that significantly modifies your text, also let a reviewer know.
> This will help your contribution get appreciated as much as it should be.
> 
> LLM/AI based tools should always be disclosed.

We understand if you need some tooling, especially spellcheckers or translation tooling are important and necessary beneficial
tools for many people, but telling us helps in the review process, so we know exactly what caused a phrasing to be the way it is.

The PR message and commit messages are considered part of the contribution.

Based on the urgency, number of interested contributors, quality and code style, your contribution may or
may not be taken in consideration for taking it in. Maintainers always reserve the right to decide not to accept your
contribution if they feel like maintaining it would be too big of a burden.

Yes, you could say, everyone who's gotten their hands on the Lumina codebase is a contributor who put their soul into it.

### 4. Making it a pull request

This goes as you would expect it! Turn your fork into a PR from the Tangled web UI, properly describe the changes made 
and await review from a maintainer with write access. They may tell you to review some things, ask you to change things 
or may or may not merge the PR. Congratulations if they do merge! **You've now contributed to Lumina.**


## Filing an issue

Feel like something should be changed, even if it's just documentation, or a piece of text, a bug, or maybe an architectural design or... 
anything really! [File an issue](https://tangled.org/did:plc:dlfsjwtiq5zklprcrmhjxlsq/issues) for it!

For proposing any changes, it is of course best to state what is currently going on and how this is 
possibly wrong (or right, but could be improved!). 

Furthermore, [the above mention of 'souls'](#souls) is not strongly checked nor ever enforced for issues, but you may still find 
that hand-writing your issue and having a few spelling mistakes will be received with more kindness than you might expect.

Try and stay positive in your approach, after all, your ideas, observations and reports are always valued to maintainers, but maintainers
are humans too! We all want to make Lumina great, don't we?

### Issue tags

Lumina uses the default Tangled tags and some more:

- `roadmap`: Denotes that this issue is part of the roadmap, which as of writing means, a feature must be included and
  has already been planned to be part of the first release.
- <a id="tag-out-planned"></a> `out-planned`: This means an issue is recognised and considered a 'nice to have', but there's currently no planning
  for it to happen.
