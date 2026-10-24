#!/bin/sh
# Idempotent first-run install. Runs inside the cli container.
set -eu

if wp core is-installed 2>/dev/null; then
  echo "WordPress already installed."
  exit 0
fi

wp core install \
  --url="$WP_URL" \
  --title="$WP_TITLE" \
  --admin_user="$WP_ADMIN_USER" \
  --admin_password="$WP_ADMIN_PASSWORD" \
  --admin_email="$WP_ADMIN_EMAIL" \
  --skip-email

if [ "$WP_LOCALE" != "en_US" ]; then
  wp language core install "$WP_LOCALE" --activate
fi

wp rewrite structure '/%postname%/'
wp plugin delete akismet hello 2>/dev/null || true
# Drop the older bundled default themes, keep the active one.
wp theme list --status=inactive --field=name | grep '^twenty' | xargs -r wp theme delete

echo "WordPress installed: $WP_URL (user: $WP_ADMIN_USER)"
