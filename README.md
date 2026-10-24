# wpdev

A small, disposable WordPress dev environment: Docker for the infra, `make` to drive it.

**Stack:** WordPress (PHP 8.3 + Apache + Xdebug) · MariaDB 11.4 · WP-CLI · Mailpit

## Quick start

```sh
make up        # first run creates .env, builds, installs WordPress
```

| | |
|---|---|
| Site | http://localhost:8080 |
| Admin | http://localhost:8080/wp-admin (`admin` / `admin`) |
| Mailpit | http://localhost:8025 (catches all outgoing mail) |

Run `make` on its own to list every target.

## Everyday commands

```sh
make up / down / restart     # start, stop (data kept), stop + start
make fresh                   # wipe everything and reinstall (~30s)
make destroy                 # remove containers, volumes, built image (FORCE=1 skips the prompt)

./bin/wp plugin list         # WP-CLI, works like a local `wp`
make wp ARGS="option get home"

make shell                   # bash in the WordPress container
make db-shell                # MariaDB client
make db-export               # -> backups/<project>-<timestamp>.sql
make db-import FILE=backups/x.sql OLD_URL=https://live.example.com

make logs [S=wordpress]      # container logs
make debug-log               # tail wp-content/debug.log (WP_DEBUG_LOG is on)
make xdebug-on / xdebug-off
make status
```

## Where your code goes

`wp-content/themes`, `wp-content/plugins` and `wp-content/mu-plugins` are bind-mounted into the container, so edit them on the host. WordPress core, uploads and `debug.log` live in a Docker volume and are thrown away by `make destroy`.

Everything in those folders is git-ignored except this repo's own dev mu-plugins, so restored or installed sites never end up in the template. To track a theme or plugin you're building, add an exception to `.gitignore`, e.g. `!wp-content/themes/my-theme/`.

Apache and WP-CLI run as your host UID/GID (`HOST_UID`/`HOST_GID` in `.env`, filled in automatically), so files created by WordPress, such as plugins installed from wp-admin, stay owned by you.

## WP-CLI

`./bin/wp` runs WP-CLI in a throwaway container that shares the site's files and database network. Use it instead of the host `wp`, which can't see core (it's in a volume) or the `db` host. Pipes and non-TTY use work too, e.g. `echo '<?php ...' | ./bin/wp eval-file -`.

## Xdebug

Xdebug is installed but `XDEBUG_MODE=off` by default, so it costs nothing. `make xdebug-on` restarts WordPress with `debug` mode, and it connects to `host.docker.internal:9003`. VS Code (PHP Debug extension) `launch.json`:

```json
{
  "name": "Listen for Xdebug (wpdev)",
  "type": "php",
  "request": "launch",
  "port": 9003,
  "pathMappings": { "/var/www/html/wp-content": "${workspaceFolder}/wp-content" }
}
```

To keep it on permanently, set `XDEBUG_MODE=debug` in `.env`.

## Running more than one site

Copy or clone the repo, then change `COMPOSE_PROJECT_NAME`, `WP_PORT` and `MAIL_PORT` in `.env`. Containers, volumes and networks are namespaced by the project name.

## Dev-only mu-plugins

- `mailpit.php` sends all `wp_mail()` through Mailpit.
- `dev-http.php` sends a plain `WordPress/x.y` user agent to wordpress.org. api.wordpress.org answers HTTP 434 when the agent contains `http://localhost:<port>`, which otherwise breaks plugin and theme installs.

## WSL notes

Keep the repo on the Linux filesystem (`~/dev/...`), not under `/mnt/c`, or bind mounts will be slow. `localhost:8080` is reachable from Windows browsers through WSL's port forwarding.
