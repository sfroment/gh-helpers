#!/bin/bash

# --- Configuration ---
# Limit for the number of repos to fetch (gh handles pagination).
REPO_LIMIT=1000

# --- Argument Handling & Validation ---

# Check if the required number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <github_organization> <clone_directory>"
    echo "Example: $0 my-cool-org ./cloned-repos"
    exit 1
fi

# Assign arguments to variables
ORG="$1"
CLONE_DIR="$2"

# --- Dependency Check ---

# Check if gh command exists
if ! command -v gh &>/dev/null; then
    echo "Error: 'gh' command not found."
    echo "Please install the GitHub CLI: https://cli.github.com/"
    exit 1
fi

# --- Main Logic ---

echo "Target Organization: $ORG"
echo "Cloning Directory:   $CLONE_DIR"

# Create the clone directory if it doesn't exist
echo "Creating directory '$CLONE_DIR' if it doesn't exist..."
if ! mkdir -p "$CLONE_DIR"; then
    echo "Error: Failed to create directory '$CLONE_DIR'."
    exit 1
fi

echo "Fetching repositories for organization '$ORG' and cloning..."
echo "-----------------------------------------"

repo_count=0
processed_count=0
export repo_count processed_count

# Fetch the list of repositories and process line by line using a while read loop
while IFS= read -r repo_full_name || [ -n "$repo_full_name" ]; do
    # The '|| [ -n "$repo_full_name" ]' handles the case where the last line might not have a newline

    # Increment total count
    repo_count=$((repo_count + 1))

    # Skip empty lines if any somehow occur
    if [ -z "$repo_full_name" ]; then
        continue
    fi

    # Extract the repository name from the full name (ORG/REPO)
    repo_name=$(basename "$repo_full_name")
    target_path="$CLONE_DIR/$repo_name"

    echo "Processing: $repo_full_name"

    # Check if the target directory already exists
    if [ -d "$target_path" ]; then
        echo "  -> Directory '$target_path' already exists. Skipping clone."
        # Optional: You could add logic here to pull latest changes instead
        # echo "  -> Pulling latest changes..."
        # ( cd "$target_path" && git pull )
    else
        echo "  -> Cloning into '$target_path'..."
        if ! gh repo clone "$repo_full_name" "$target_path"; then
            echo "  -> Warning: Failed to clone $repo_full_name."
            # Decide if you want to continue or exit on failure
            # exit 1 # Uncomment to exit script on first clone failure
        else
            processed_count=$((processed_count + 1))
        fi
    fi
    echo # Add a blank line for readability
done < <(gh repo list "$ORG" --limit "$REPO_LIMIT" --json nameWithOwner --jq '.[].nameWithOwner')

# Check if the gh command itself failed (e.g., invalid org, permissions)
# Note: This check happens *after* the pipe, so it captures gh exit status.
# We use PIPESTATUS array (Bash specific) if available, otherwise check repo_count
if [ -n "${PIPESTATUS[0]}" ] && [ "${PIPESTATUS[0]}" -ne 0 ]; then
    echo "-----------------------------------------"
    echo "Error: 'gh repo list' command failed (Status: ${PIPESTATUS[0]}). Check organization name and permissions."
    exit 1
elif [ -z "${PIPESTATUS[0]}" ] && [ $repo_count -eq 0 ]; then
    # Fallback check if PIPESTATUS is not available (e.g., running with sh)
    # Check if gh command might have printed an error to stderr instead of stdout
    # This is less reliable than PIPESTATUS
    echo "-----------------------------------------"
    echo "Warning: No repositories were processed. Check organization name, permissions, or if the organization is empty."
    # We don't exit here, as an empty org is not strictly an error
fi

echo "-----------------------------------------"
if [ $repo_count -eq 0 ]; then
    echo "No repositories found for organization '$ORG'."
else
    echo "Cloning process completed. Checked $repo_count repositories. Cloned/updated $processed_count."
fi
