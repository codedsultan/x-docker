#!/bin/sh
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/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"  # Replace with your Slack webhook URL

send_slack_notification() {
    local message="$1"
    log_message "Sending Slack notification: $message"
    curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"${message}\"}" "$SLACK_WEBHOOK_URL"
}
echo "🔄 Installing Git Hooks..."
send_slack_notification "🔄 Installing Git Hooks..."

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

# Create post-merge hook if it doesn't exist

if [ ! -f .git/hooks/post-merge ]; then
    send_slack_notification "🔄 Installing post-merge hook..."
    cp scripts/post-merge .git/hooks/post-merge
    chmod +x .git/hooks/post-merge
    echo "✅ post-merge hook installed!"
    send_slack_notification "✅ post-merge hook installed!"
fi

echo "✅ All hooks installed successfully!"
send_slack_notification "✅ All hooks installed successfully!"
