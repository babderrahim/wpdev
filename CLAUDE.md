# wpdev: notes for agents

Disposable WordPress dev environment (Docker + Makefile). See README.md for details.

- WP-CLI: always use `./bin/wp <cmd>` (from the repo root or any subdir). Don't use the host `wp`; core lives in a Docker volume.
- Write theme/plugin code under `wp-content/themes`, `wp-content/plugins` and `wp-content/mu-plugins` (bind-mounted). Nothing else in WordPress is on the host.
- Lifecycle: `make up`, `make down`, `make fresh` (wipe + reinstall), `make status`.
- PHP errors: `make debug-log`, or `docker compose exec wordpress cat wp-content/debug.log`.
- Mail: check `curl -s localhost:8025/api/v1/messages`.
- Site URL is `http://localhost:$WP_PORT` (default 8080). Admin is admin/admin.
- `make destroy` deletes the database. Only run it when asked.
