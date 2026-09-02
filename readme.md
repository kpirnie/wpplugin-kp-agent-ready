# KP Agent Ready

[![GitHub Issues](https://img.shields.io/github/issues/kpirnie/wpplugin-kp-agent-ready?style=for-the-badge&logo=github&color=006400&logoColor=white&labelColor=000)](https://github.com/kpirnie/wpplugin-kp-agent-ready/issues)
[![Last Commit](https://img.shields.io/github/last-commit/kpirnie/wpplugin-kp-agent-ready?style=for-the-badge&labelColor=000)](https://github.com/kpirnie/wpplugin-kp-agent-ready/commits/main)
[![MIT](https://img.shields.io/badge/License-GPLv3-orange.svg?style=for-the-badge&logo=opensourceinitiative&logoColor=white&labelColor=000)](LICENSE)

[![PHP](https://img.shields.io/badge/Min.%20php8.2-777BB4?logo=php&logoColor=white&style=for-the-badge&labelColor=000)](https://php.net)
[![WordPress](https://img.shields.io/badge/Min.%20WP-6.8-3858e9?logo=wordpress&logoColor=white&style=for-the-badge&labelColor=000)](https://wordpress.org)
[![Kevin Pirnie](https://img.shields.io/badge/-KevinPirnie.com-000d2d?style=for-the-badge&labelColor=000&logoColor=white&logo=data:image/svg%2Bxml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSJ3aGl0ZSIgc3Ryb2tlLXdpZHRoPSIxLjgiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIgc3Ryb2tlLWxpbmVqb2luPSJyb3VuZCI+CiAgPGNpcmNsZSBjeD0iMTIiIGN5PSIxMiIgcj0iMTAiLz4KICA8ZWxsaXBzZSBjeD0iMTIiIGN5PSIxMiIgcng9IjQuNSIgcnk9IjEwIi8+CiAgPGxpbmUgeDE9IjIiIHkxPSIxMiIgeDI9IjIyIiB5Mj0iMTIiLz4KICA8bGluZSB4MT0iNC41IiB5MT0iNi41IiB4Mj0iMTkuNSIgeTI9IjYuNSIvPgogIDxsaW5lIHgxPSI0LjUiIHkxPSIxNy41IiB4Mj0iMTkuNSIgeTI9IjE3LjUiLz4KPC9zdmc+Cg==)](https://kevinpirnie.com/)

Make your WordPress site discoverable and usable by AI agents. Implements the emerging suite of agent-readiness standards — `.well-known` endpoints, `llms.txt`, WebMCP tools, RFC 8288 Link headers, Content Signals in `robots.txt`, and markdown content negotiation — all configurable from the WordPress admin.

Nothing here requires an Apache or Nginx rule. Every endpoint dispatches off the request inside WordPress.

## Requirements

* PHP 8.2 or higher
* WordPress 6.8 or higher
* Single-site only — the plugin refuses network activation

## Repository layout

Work happens in `source`. Nothing in `distribute` is edited by hand - it is regenerated in full on every build.

```
composer.json            the package definition
package.json             name, version and the build script
build.sh                 the build
source/                  everything that is worked on
    kp-agent-ready.php   the plugin bootstrap
    src/                 the namespaced classes
    uninstall.php
    readme.txt
    LICENSE
distribute/              the built plugin, committed, installable as-is
vendor/                  composer dependencies, not committed
```

## Building

```bash
composer install
npm install
./build.sh
```

`build.sh` wipes `distribute` and rebuilds it every time. It checks that the plugin header version, the `KP_AGENT_READY_VERSION` constant and the readme stable tag all agree, copies the PHP and the supporting files, builds the autoloader, and generates `languages/kp-agent-ready.pot` with WP-CLI. `composer.json` ships alongside it.

There are no translation files in `source`. The `.pot` is generated on each build and lives only in `distribute/languages`.

## Releasing

Tag the commit and push it. The release workflow stages `distribute` under the plugin slug, zips it, and publishes the zip on the tag.

```bash
git tag v1.1.98
git push --tags
```

## Installing

Install `distribute` as the plugin directory, or download the zip from a release. There is nothing to configure to get started — every module ships off by default and is toggled from the settings page.

## Architecture

`Plugin` is a singleton. The bootstrap registers a PSR-4 autoloader over `src`, so there is no Composer dependency at runtime, then hands the option array to every module.

Everything under `src/Modules` extends `AbstractModule` and does its work through a single `register()` method that hooks into WordPress. Nothing outside a module hooks anything.

* `LinkHeaders` - RFC 8288 `Link` response headers on every request
* `RobotsTxt` - Content Signals directives appended to the generated `robots.txt`
* `WellKnown` - the `/.well-known/*` discovery endpoints
* `MarkdownNegotiation` - serves markdown for singular posts and pages when the client asks for it
* `WebMCP` - registers and injects the WebMCP tool context
* `LlmsTxt` - writes `/llms.txt` and `/llms-full.txt` to the web root and keeps them current

`src/Settings/SettingsPage.php` is the admin screen. `src/Helpers/HtmlToMarkdown.php` is the stateless converter behind markdown negotiation.

## Data

All plugin settings live in one option key, `kp_agent_ready`. Activation registers no rewrite rules — the well-known endpoints dispatch off `REQUEST_URI` at `parse_request`, so there is nothing to flush.

`llms.txt` and `llms-full.txt` are physical files written to `ABSPATH`. When the filesystem refuses the write, the generated content is stored and surfaced in the admin so it can be placed manually.

## Coding standards

PSR-12 with the WordPress coding standards on top. Class files are namespaced under `KP\AgentReady`. Every superglobal read is unslashed and sanitized, every output is escaped, and every write path checks a nonce and a capability.

Run Plugin Check against `distribute`, not `source` - the built tree is what ships.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
