# maneyko.com

Source code for my personal website. Plain PHP, no framework, no build step.

## Running it locally

```sh
scripts/run_server.sh -p 8089 -o
```

No install step and no dependency manager — PHP and two command-line tools:

| Needs | For |
|---|---|
| `yq` | `index.php` shells out to it to read `static/icons.yml` |
| [argparse.sh](https://github.com/maneyko/argparse.sh) | argument parsing in `run_server.sh` |

`run_server.sh` wraps `php -S` and points it at `config/` for its ini; `-o` opens
a browser on macOS.

`yq` is a **runtime** requirement, not just a local one, so it has to be on the
server too (`apt-get install -y yq`). Two things follow from shelling out to it:

- Without `yq`, `shell_exec` returns null and the icon row renders empty rather
  than erroring — a missing binary looks like a content problem.
- `yq` writes a merge-anchor deprecation warning to stderr on every call, which
  in production means one line in the php-fpm log per request. `static/icons.yml`
  does use merge anchors, and each entry's own `href` correctly overrides the
  anchor's today; the warning is about that precedence becoming spec-compliant,
  which is the behaviour already in effect here.

## How pages resolve

There is no router. `index.php` reads `.env` then `.env.local` by hand, includes
`header.php`, and emits a page. The rewrite rules do the rest:

```nginx
location / { try_files $uri $uri/ @php_rewrite; }
location @php_rewrite { rewrite ^(.*)$ $1.php last; }
```

So `/foo` serves `foo.php` when it exists. Adding a page means adding a `.php`
file — nothing registers it.

`files/` is a browsable directory listing rendered by
`files/directory_listing.php`. Its knobs are `$PAGE_HEADING`, `$PAGE_TITLE`,
`$FILE_SORT_KEY` and `$SKIP_PATTERN`, set before the include.

## What is not in the repo

`files/`, `local/`, `private/` and every image are gitignored — this repo holds
the code, not the content it serves. Each keeps a `.keep` so the directory
exists in a fresh checkout.

Real configuration goes in `.env.local`, which is also gitignored. The tracked
`.env` is a placeholder so the loader has something to read.

`config/nginx/maneyko.com.conf` carries a deny-list covering `/config`,
`/private`, `/scripts`, the dotfiles and a few paths that no longer exist.
**Anything new that holds private content needs adding to it** — the default is
to serve whatever is in the document root.

## Legacy

These predate the current setup and nothing runs them. They are kept for
reference, not as instructions:

| Path | |
|---|---|
| `bin/setup.sh` | hand-installs packages and a crontab against a host layout that no longer exists |
| `scripts/cert-renewal/` | certbot-era certificate renewal; superseded |
| `config/fail2ban/`, `config/monit/`, `config/vsftpd.conf` | configure services that are not installed |
| `scripts/ipv6/` | one-off interface toggles |

`scripts/check-ips.sh` and `scripts/cloudflare-purge-cache.sh` are still useful
by hand.

`config/php.ini` is for the local server only.
