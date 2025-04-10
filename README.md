# GitHub Organization Helpers

A collection of bash scripts to help manage GitHub organizations, including cloning repositories and extracting issues.

## Features

### Organization Cloner (`clone-org.sh`)
- Clones all repositories from a specified GitHub organization
- Handles pagination with a configurable repository limit (default: 1000)
- Skips already cloned repositories
- Provides detailed progress information
- Error handling and validation

### Issue Extractor (`issue-extractor.sh`)
- Extracts all issues (open and closed) from organization repositories
- Creates markdown files for each issue with detailed metadata
- Includes issue title, body, author, state, labels, assignees, and timestamps
- Organizes issues by repository in a structured directory
- Handles pagination with configurable limits

## Prerequisites

- [GitHub CLI (`gh`)](https://cli.github.com/) installed and configured
- Bash shell environment
- Git installed
- `jq` command-line tool (for issue extractor)

## Installation

1. Clone this repository:
```bash
git clone https://github.com/yourusername/gh-helpers.git
cd gh-helpers
```

## Usage

### Organization Cloner

```bash
./clone-org.sh <github_organization> <clone_directory>
```

#### Arguments
- `github_organization`: The name of the GitHub organization to clone repositories from
- `clone_directory`: The directory where repositories will be cloned

#### Example
```bash
./clone-org.sh my-cool-org ./cloned-repos
```

### Issue Extractor

```bash
./issue-extractor.sh <github_organization> [output_directory]
```

#### Arguments
- `github_organization`: The name of the GitHub organization to extract issues from
- `output_directory`: (Optional) Directory where markdown files will be saved (default: `gh_issues_md`)

#### Example
```bash
./issue-extractor.sh my-cool-org ./issues-docs
```

## Configuration

### Organization Cloner
- `REPO_LIMIT`: Maximum number of repositories to fetch (default: 1000)

### Issue Extractor
- `LIMIT`: Maximum number of issues to fetch per repository (default: 1000)
- `REPO_LIMIT`: Maximum number of repositories to process (default: 1000)
- `OUTPUT_DIR`: Base directory for markdown files (default: `gh_issues_md`)

## Error Handling

Both scripts include comprehensive error checks:
- Validates required arguments
- Checks for required dependencies (GitHub CLI, jq)
- Verifies directory creation
- Handles API failures gracefully
- Validates organization access and existence

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source and available under the [GNU GPLv3](LICENSE).

