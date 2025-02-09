# #!/bin/sh
# # /scripts/install-hooks.sh
# set -a
# # Load the environment variables from the .env file at the root of the project
# source ./.env
# # Disable exporting environment variables after loading
# set +a

# SLACK_WEBHOOK_URL="${SLACK_MONITORING_WEB_HOOK}"  # Replace with your Slack webhook URL

# send_slack_notification() {
#     local message="$1"
#     echo "Sending Slack notification: $message to $SLACK_WEBHOOK_URL"
#     curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"${message}\"}" "$SLACK_WEBHOOK_URL"
# }

# echo "🔄 Installing Git Hooks..."
# send_slack_notification "Installing Git Hooks..."

# # Ensure the hooks directory exists
# mkdir -p .git/hooks

# # # Create post-fetch hook if it doesn't exist
# # if [ ! -f .git/hooks/post-fetch ]; then
# #     cat <<EOL > .git/hooks/post-fetch
# # #!/bin/sh
# # echo "🔄 Running post-fetch actions..."
# # git merge origin/main  # Replace 'main' with your branch
# # .git/hooks/post-merge  # Run post-merge script
# # EOL
# #     chmod +x .git/hooks/post-fetch
# #     echo "✅ post-fetch hook created!"
# # fi

# # Ensure the .git/hooks directory exists
# mkdir -p .git/hooks

# # Install the post-merge hook if it doesn't exist
# # if [ ! -f .git/hooks/post-merge ]; then
#     send_slack_notification "🔄 Installing post-merge hook..."
#     cp scripts/hooks/post-merge .git/hooks/post-merge
#     chmod +x .git/hooks/post-merge  # Make sure it's executable
#     echo "✅ post-merge hook installed!"
#     send_slack_notification "✅ post-merge hook installed!"
# # fi

# echo "✅ All hooks installed successfully!"

#!/bin/bash

# Function to find the project root (where .env file is located)
find_project_root() {
    local current_dir="$PWD"
    while [[ "$current_dir" != "/" ]]; do
        if [[ -f "$current_dir/.env" ]]; then
            echo "$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done
    return 1
}

# Store the original directory
# ORIGINAL_DIR=$(pwd)

# Find project root
# PROJECT_ROOT=$(find_project_root)
# if [[ -z "$PROJECT_ROOT" ]]; then
#     echo "Error: Could not find project root containing .env file"
#     exit 1
# fi

# # Change to project root to ensure relative paths work correctly
# cd "$PROJECT_ROOT"

# Load environment variables
# if [ -f .env ]; then
PROJECT_ROOT=/var/www/apps/docker

echo "Loading environment variables from .env"
set -a
source "$PROJECT_ROOT/scripts/.env"
set +a
# else
#     echo "Error: .env file not found at project root"
#     exit 1
# fi

SLACK_WEBHOOK_URL="${SLACK_MONITORING_WEB_HOOK}"

send_slack_notification() {
    local message="$1"
    echo "Sending Slack notification: $message to $SLACK_WEBHOOK_URL"
    curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"${message}\"}" "$SLACK_WEBHOOK_URL"
}

# Function to install hooks
install_hooks() {
    echo "🔄 Installing Git Hooks..."
    send_slack_notification "Installing Git Hooks...here"

    # Ensure the hooks directory exists
    mkdir -p .git/hooks

    # Install the post-merge hook
    send_slack_notification "🔄 Installing post-merge hook..."
    
    if [ -f "scripts/hooks/post-merge" ]; then
        cp scripts/hooks/post-merge .git/hooks/post-merge
        chmod +x .git/hooks/post-merge
        echo "✅ post-merge hook installed!"
        send_slack_notification "✅ post-merge hook installed!"
    else
        echo "Error: post-merge hook source file not found at scripts/hooks/post-merge"
        send_slack_notification "❌ Error: post-merge hook source file not found!"
        exit 1
    fi
}

# Main execution
main() {
    # Install the hooks
    install_hooks
    
    echo "✅ All hooks installed successfully!"
    send_slack_notification "✅ All hooks installed successfully!"
    
    # Return to original directory
    cd "$ORIGINAL_DIR"
}

# Execute main function
main