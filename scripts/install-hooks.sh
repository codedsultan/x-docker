#!/bin/sh
# /scripts/install-hooks.sh
set -a
# Load the environment variables from the .env file at the root of the project
source ./.env
# Disable exporting environment variables after loading
set +a
SLACK_WEBHOOK_URL="${SLACK_MONITORING_WEB_HOOK}"  # Replace with your Slack webhook URL

send_slack_notification() {
    local message="$1"
    echo "Sending Slack notification: $message to $SLACK_WEBHOOK_URL"
    curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"${message}\"}" "$SLACK_WEBHOOK_URL"
}

echo "🔄 Installing Git Hooks..."
send_slack_notification "Installing Git Hooks..."

# Ensure the hooks directory exists
mkdir -p .git/hooks

# # Create post-fetch hook if it doesn't exist
# if [ ! -f .git/hooks/post-fetch ]; then
#     cat <<EOL > .git/hooks/post-fetch
# #!/bin/sh
# echo "🔄 Running post-fetch actions..."
# git merge origin/main  # Replace 'main' with your branch
# .git/hooks/post-merge  # Run post-merge script
# EOL
#     chmod +x .git/hooks/post-fetch
#     echo "✅ post-fetch hook created!"
# fi

# Ensure the .git/hooks directory exists
mkdir -p .git/hooks

# Install the post-merge hook if it doesn't exist
# if [ ! -f .git/hooks/post-merge ]; then
    send_slack_notification "🔄 Installing post-merge hook..."
    cp scripts/hooks/post-merge .git/hooks/post-merge
    chmod +x .git/hooks/post-merge  # Make sure it's executable
    echo "✅ post-merge hook installed!"
    send_slack_notification "✅ post-merge hook installed!"
# fi

echo "✅ All hooks installed successfully!"
