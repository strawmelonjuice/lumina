# Security Policy

## Supported Versions

Currently, as the project is not in a state where it supports "versions", the only version considered 'safe' should be latest commit.

<!--
Use this section to tell people about which versions of your project are
currently being supported with security updates.

| Version | Supported          |
| ------- | ------------------ |
| 5.1.x   | :white_check_mark: |
| 5.0.x   | :x:                |
| 4.0.x   | :white_check_mark: |
| < 4.0   | :x:                |
-->

## Reporting a Vulnerability

Reporting a vulnerability should not be done through GitHub Issues, those are public and could be used for more exploitation before I even see them. Instead, email me at <mar@strawmelonjuice.com> and mention **at least**:

-   estimated severity
-   vulnerability-type
-   some steps to reproduce (or a detailed explanation on _how_)
    But more info is always welcome.

### If the vulnerability is in a dependency

#### ...and unreported there

Of course, follow the dependencies security policy, but if you got there because of this project, maybe mail me too.

#### ...but reported there

Mail me, so I can wait for a patch to be released and maybe dim my usage of that dependency a bit. Just emailing me a simple mail like `"Dependency {xyz} has a vuln report here: <{github.com/xyz/...}>"` would suffice.

#### ...but fixed there

Now that saves us a lot of the trouble. You can safely just create a GitHub Issue or a PR to update the dependency and include the patches. After that, if the severity is high enough, maybe mail me to alert me, otherwise just wait for me to come online and accept the patch.
