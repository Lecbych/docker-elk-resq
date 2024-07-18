#!/usr/bin/env bash

set -eu
set -o pipefail

source "${BASH_SOURCE[0]%/*}"/lib.sh

# Ensure required environment variables are set
if [ -z "${KEYCLOAK_SERVER_URL:-}" ]; then
    echo "Error: KEYCLOAK_SERVER_URL is not set"
    exit 1
fi

if [ -z "${KEYCLOAK_CLIENT_NAME:-}" ]; then
    echo "Error: KEYCLOAK_CLIENT_NAME is not set"
    exit 1
fi

if [ -z "${CLIENT_SECRET:-}" ]; then
    echo "Error: CLIENT_SECRET is not set"
    exit 1
fi


# Initialize Elasticsearch setup
# --------------------------------------------------------
# Users declarations

declare -A users_passwords
users_passwords=(
	[logstash_internal]="${LOGSTASH_INTERNAL_PASSWORD:-}"
	[kibana_system]="${KIBANA_SYSTEM_PASSWORD:-}"
)

declare -A users_roles
users_roles=(
	[logstash_internal]='logstash_writer'
)

# --------------------------------------------------------
# Roles declarations

declare -A roles_files
roles_files=(
	[logstash_writer]='logstash_writer.json'
)

# --------------------------------------------------------


log 'Waiting for availability of Elasticsearch. This can take several minutes.'

declare -i exit_code=0
wait_for_elasticsearch || exit_code=$?

if ((exit_code)); then
	case $exit_code in
		6)
			suberr 'Could not resolve host. Is Elasticsearch running?'
			;;
		7)
			suberr 'Failed to connect to host. Is Elasticsearch healthy?'
			;;
		28)
			suberr 'Timeout connecting to host. Is Elasticsearch healthy?'
			;;
		*)
			suberr "Connection to Elasticsearch failed. Exit code: ${exit_code}"
			;;
	esac

	exit $exit_code
fi

sublog 'Elasticsearch is running'

log 'Setting OIDC client secret in the Elasticsearch keystore'

keystore_cmd="$HOME/bin/elasticsearch-keystore"
echo "$CLIENT_SECRET" | "$keystore_cmd" add xpack.security.authc.realms.oidc.stroke.rp.client_secret -f
sublog 'Client secret for was succesfully set into the Elasticsearch keystore'


log 'Waiting for initialization of built-in users'

wait_for_builtin_users || exit_code=$?

if ((exit_code)); then
	suberr 'Timed out waiting for condition'
	exit $exit_code
fi

sublog 'Built-in users were initialized'

for role in "${!roles_files[@]}"; do
	log "Role '$role'"

	declare body_file
	body_file="${BASH_SOURCE[0]%/*}/roles/${roles_files[$role]:-}"
	if [[ ! -f "${body_file:-}" ]]; then
		sublog "No role body found at '${body_file}', skipping"
		continue
	fi

	sublog "Creating/updating ${body_file}" 
	ensure_role "$role" "$(<"${body_file}")"
done

for user in "${!users_passwords[@]}"; do
	log "User '$user'"
	if [[ -z "${users_passwords[$user]:-}" ]]; then
		sublog 'No password defined, skipping'
		continue
	fi

	declare -i user_exists=0
	user_exists="$(check_user_exists "$user")"

	if ((user_exists)); then
		sublog 'User exists, setting password'
		set_user_password "$user" "${users_passwords[$user]}"
	else
		if [[ -z "${users_roles[$user]:-}" ]]; then
			suberr '  No role defined, skipping creation'
			continue
		fi

		sublog 'User does not exist, creating'
		log "Assigning role '${users_roles[$user]}'" 
		create_user "$user" "${users_passwords[$user]}" "${users_roles[$user]}"
	fi
done

log 'Setting OIDC client configuration into elasticsearch.yml'
./update_config.sh
sublog 'Configuration was succesfull.'