#!/usr/bin/env sh

set -euo pipefail

config_file="/var/www/html/config/config.ini.php"

start_server() {
  echo "Booting up temporary server…"

  # Start services
  /entrypoint.sh php-fpm &
  nginx
  sleep 2
}

exec_sql_query() {
  php -r "
    \$conn = new PDO(\"mysql:host=${MATOMO_DATABASE_HOST}:${MATOMO_DATABASE_PORT_NUMBER};dbname=${MATOMO_DATABASE_NAME}\", \"${MATOMO_DATABASE_USER}\", \"${MATOMO_DATABASE_PASSWORD}\");
    \$conn->exec(\"$1\");"
}

# Run through the installation wizard
matomo_pass_wizard() {
  local wizard_url cookie_file curl_output curl_opts curl_data_opts

  # Start wizard
  wizard_url="http://127.0.0.1:26059/"
  cookie_file="/tmp/cookie$RANDOM"
  curl_opts="--location --silent --cookie $cookie_file --cookie-jar $cookie_file -o /dev/null"
  curl $curl_opts $wizard_url

  echo "Step 1: System check"
  curl_data_opts="--data-urlencode action=systemCheck"
  curl $curl_opts $curl_data_opts $wizard_url

  echo "Step 2: Database setup"
  curl_data_opts="--data-urlencode action=databaseSetup\
    --data-urlencode host=${MATOMO_DATABASE_HOST}:${MATOMO_DATABASE_PORT_NUMBER}\
    --data-urlencode username=${MATOMO_DATABASE_USER}\
    --data-urlencode password=${MATOMO_DATABASE_PASSWORD}\
    --data-urlencode dbname=${MATOMO_DATABASE_NAME}\
    --data-urlencode tables_prefix=matomo_\
    --data-urlencode adapter=PDO\\MYSQL"
  curl $curl_opts $curl_data_opts $wizard_url

  echo "Step 3: Create tables (SKIP)"

  echo "Step 4: Setup super-user"
  curl_data_opts="--data-urlencode action=setupSuperUser\
    --data-urlencode module=Installation\
    --data-urlencode login=${MATOMO_USERNAME}\
    --data-urlencode password=${MATOMO_PASSWORD}\
    --data-urlencode password_bis=${MATOMO_PASSWORD}\
    --data-urlencode email=${MATOMO_EMAIL}"
  curl $curl_opts $curl_data_opts $wizard_url

  echo "Step 5: Setup first tracking website"
  curl_data_opts="--data-urlencode action=firstWebsiteSetup\
    --data-urlencode module=Installation\
    --data-urlencode siteName=${MATOMO_WEBSITE_NAME}\
    --data-urlencode url=${MATOMO_HOST}\
    --data-urlencode timezone=UTC"
  curl $curl_opts $curl_data_opts $wizard_url

  echo "Step 6: Tracking code"
  curl_data_opts="--data-urlencode action=trackingCode\
    --data-urlencode module=Installation"
  curl $curl_opts $curl_data_opts $wizard_url

  echo "Step 7: Finish installation"
  curl_data_opts="--data-urlencode action=finished\
    --data-urlencode module=Installation"
  curl $curl_opts $curl_data_opts $wizard_url
}

# Install & activate the given plugin
matomo_install_plugin() {
  echo "Installing plugin '$1'…"

  # Download plugin
  curl --location --silent -o "/tmp/$1.zip" "https://plugins.matomo.org/api/2.0/plugins/$1/download/latest"
  unzip -q "/tmp/$1.zip" -d /var/www/html/plugins
  chown -R www-data:www-data "/var/www/html/plugins/$1"
  rm "/tmp/$1.zip"

  # Activate plugin
  ./console plugin:activate $1
}

# Adapt some general settings (stored in the DB) to match our preferences
matomo_tweak_options() {
  echo "Tweak some options…"

  # General settings
  exec_sql_query "REPLACE INTO matomo_option VALUES
    ('enableBrowserTriggerArchiving', '0', 1),
    ('PrivacyManager.ipAddressMaskLength', '2', 0),
    ('PrivacyManager.ipAnonymizerEnabled', '1', 0),
    ('PrivacyManager.useAnonymizedIpForVisitEnrichment', '1', 0),
    ('PrivacyManager.anonymizeOrderId', '1', 0),
    ('PrivacyManager.anonymizeUserId', '1', 0),
    ('PrivacyManager.doNotTrackEnabled', '1', 0),
    ('delete_logs_enable', '1', 0),
    ('delete_logs_older_than', '180', 0),
    ('delete_reports_enable', '1', 0),
    ('delete_reports_keep_basic_metrics', '1', 0),
    ('delete_reports_keep_month_reports', '1', 0),
    ('delete_reports_keep_year_reports', '1', 0),
    ('delete_reports_older_than', '12', 0);"

  # Configure ProtectTrackID
  exec_sql_query "INSERT INTO matomo_plugin_setting VALUES
    ('ProtectTrackID', 'baseSetting', 'ABCDEFGHIJKLMNOPijklmnopqrstuvxwyz12345', 0, '', DEFAULT),
    ('ProtectTrackID', 'saltSetting', '$(openssl rand -hex 20)', 0, '', DEFAULT),
    ('ProtectTrackID', 'lengthSetting', '20', 0, '', DEFAULT);"

  # Configure TrackingSpamPrevention
  exec_sql_query "INSERT INTO matomo_plugin_setting VALUES
    ('TrackingSpamPrevention', 'block_clouds', '1', 0, '', DEFAULT),
    ('TrackingSpamPrevention', 'block_headless', '1', 0, '', DEFAULT);"
}

# Update configuration settings stored in the config.ini.php file
# Will always be run, to reflect changes to the ENV
matomo_update_config() {
  # Database settings
  ./console config:set \
    "database.host=\"$MATOMO_DATABASE_HOST:$MATOMO_DATABASE_PORT_NUMBER\"" \
    "database.username=\"$MATOMO_DATABASE_USER\"" \
    "database.password=\"$MATOMO_DATABASE_PASSWORD\"" \
    "database.dbname=\"$MATOMO_DATABASE_NAME\"" \
    "General.enable_load_data_infile=0"

  # Handle proxy correctly
  ./console config:set \
    'General.force_ssl=1' \
    'General.assume_secure_protocol=1' \
    'General.proxy_uri_header=1' \
    'General.enable_trusted_host_check=0' \
    'General.trusted_hosts=[]' \
    'General.proxy_client_headers=[]' \
    'General.proxy_client_headers[]="HTTP_X_FORWARDED_FOR"' \
    'General.proxy_host_headers=[]' \
    'General.proxy_host_headers[]="HTTP_X_FORWARDED_HOST"'

  # Email settings
  ./console config:set \
    "General.noreply_email_address=\"$MATOMO_NOREPLY_ADDRESS\"" \
    "General.noreply_email_name=\"$MATOMO_NOREPLY_NAME\"" \
    'mail.transport="smtp"' \
    "mail.port=\"$MATOMO_SMTP_PORT_NUMBER\"" \
    "mail.host=\"$MATOMO_SMTP_HOST\"" \
    'mail.type="Login"' \
    "mail.username=\"$MATOMO_SMTP_USER\"" \
    "mail.password=\"$MATOMO_SMTP_PASSWORD\"" \
    "mail.encryption=\"$MATOMO_SMTP_ENCRYPTION\""
}

# Only initialize if we do NOT have a config file
if [ ! -f "$config_file" ]; then
  start_server
  matomo_pass_wizard
  matomo_install_plugin BotTracker
  matomo_install_plugin JsTrackerForceAsync
  matomo_install_plugin Provider
  matomo_install_plugin ProtectTrackID
  matomo_install_plugin TrackingSpamPrevention
  matomo_install_plugin TreemapVisualization
  matomo_tweak_options
fi

# Always update general config
matomo_update_config
