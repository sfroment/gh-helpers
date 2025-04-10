#!/bin/bash

# === Configuration ===
ORG="$1"                        # Organization name
OUTPUT_DIR="${2:-gh_issues_md}" # Base directory where .md files will be saved, default to gh_issues_md if not provided
LIMIT=1000                      # Max issues to fetch in one go (adjust if needed, max is often 1000 via API)
REPO_LIMIT=1000                 # Max repos to fetch in one go (adjust if needed, max is often 1000 via API)
# === End Configuration ===

# === Validation ===
if ! command -v gh &>/dev/null; then
    echo "Error: GitHub CLI 'gh' not found."
    echo "Please install it from https://cli.github.com/ and run 'gh auth login'."
    exit 1
fi

if ! command -v jq &>/dev/null; then
    echo "Error: 'jq' command not found."
    echo "Please install it (e.g., 'sudo apt-get install jq' or 'brew install jq')."
    exit 1
fi

if [ -z "$ORG" ]; then
    echo "Error: Please provide an organization name."
    echo "Usage: $0 <organization_name> [output_directory]"
    echo "Example: $0 my-org ./issues-docs"
    exit 1
fi

# === Script Logic ===

# Create the base output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"
echo "Exporting issues from organization '$ORG' to directory: $OUTPUT_DIR/"

# Function to process issues for a single repository
process_repo_issues() {
    local repo_full_name
    local repo_name
    local repo_output_dir
    local issue_json
    local issue_number
    local issue_title
    local issue_body
    local issue_author
    local issue_state
    local issue_url
    local issue_created_at
    local issue_updated_at
    local issue_labels
    local issue_assignees
    local output_filename

    repo_full_name="$1"
    repo_name=$(basename "$repo_full_name")
    repo_output_dir="$OUTPUT_DIR/$repo_name"

    echo "Processing repository: $repo_full_name"
    mkdir -p "$repo_output_dir"

    # Fetch all issues (open and closed) with relevant fields in JSON format
    echo "  -> Fetching issues (up to limit: $LIMIT)..."
    gh issue list --repo "$repo_full_name" --state all --limit "$LIMIT" \
        --json number,title,body,author,state,url,createdAt,updatedAt,labels,assignees |
        jq -c '.[]' | while IFS= read -r issue_json; do

        # Extract fields using jq -r (raw output)
        issue_number=$(echo "$issue_json" | jq -r '.number')
        issue_title=$(echo "$issue_json" | jq -r '.title')
        issue_body=$(echo "$issue_json" | jq -r '.body // ""')
        issue_author=$(echo "$issue_json" | jq -r '.author.login // "ghost"')
        issue_state=$(echo "$issue_json" | jq -r '.state')
        issue_url=$(echo "$issue_json" | jq -r '.url')
        issue_created_at=$(echo "$issue_json" | jq -r '.createdAt')
        issue_updated_at=$(echo "$issue_json" | jq -r '.updatedAt')
        issue_labels=$(echo "$issue_json" | jq -r '[.labels[].name] | join(", ") // "None"')
        issue_assignees=$(echo "$issue_json" | jq -r '[.assignees[].login] | join(", ") // "None"')

        # Define the output filename
        output_filename="${repo_output_dir}/${issue_number}.md"

        echo "    -> Creating ${output_filename}"

        # Create the Markdown content
        {
            printf "# Issue #%s: %s\n\n" "$issue_number" "$issue_title"
            printf "**Repository:** %s\n" "$repo_full_name"
            printf "**Number:** %s\n" "$issue_number"
            printf "**State:** %s\n" "$issue_state"
            printf "**Author:** @%s\n" "$issue_author"
            printf "**Created:** %s\n" "$issue_created_at"
            printf "**Updated:** %s\n" "$issue_updated_at"
            printf "**Labels:** %s\n" "$issue_labels"
            printf "**Assignees:** %s\n" "$issue_assignees"
            printf "**URL:** %s\n\n" "$issue_url"
            printf -- "---\n\n"
            printf "%s\n" "$issue_body"
        } >"$output_filename"
    done
}

# Process each repository in the organization
echo "Fetching repositories for organization '$ORG'..."
repo_count=0
processed_count=0

while IFS= read -r repo_full_name || [ -n "$repo_full_name" ]; do
    if [ -z "$repo_full_name" ]; then
        continue
    fi

    repo_count=$((repo_count + 1))
    process_repo_issues "$repo_full_name"
    processed_count=$((processed_count + 1))
    echo # Add a blank line for readability
done < <(gh repo list "$ORG" --limit "$REPO_LIMIT" --json nameWithOwner --jq '.[].nameWithOwner')

echo "----------------------------------------"
echo "Export complete!"
echo "Processed $processed_count repositories out of $repo_count found."

if [ $repo_count -eq 0 ]; then
    echo "Warning: No repositories found for organization '$ORG'."
    echo "Check organization name and permissions."
fi

echo "Markdown files saved in: $OUTPUT_DIR"
echo "----------------------------------------"

exit 0
