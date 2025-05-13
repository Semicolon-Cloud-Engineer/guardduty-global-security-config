#!/bin/bash

# GitHub setup script with parameterization, error handling, and logging
# Requires GitHub CLI (gh) and jq

# Parameters
ORG_NAME=$1
GITHUB_TOKEN=$2
LOG_FILE="github_setup.log"
REPOS=(BE FE QA_BE QA_FE)
BRANCHES=(dev systest uat prod)
DEFAULT_BRANCH="dev"

# Authenticate with GitHub
export GH_TOKEN=$GITHUB_TOKEN

# Log function
log_message() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to create a repository and set up branches
create_repo_and_branches() {
  local repo_name=$1
  log_message "Creating repository: $repo_name"

  if gh repo create "$ORG_NAME/$repo_name" --private --confirm; then
    cd $repo_name || exit

    # Create .github/workflows/maven.yml
    mkdir -p .github/workflows
    cat <<EOF > .github/workflows/maven.yml
name: Maven Build

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      - name: Set up JDK 17
        uses: actions/setup-java@v3
        with:
          java-version: 17
      - name: Build with Maven
        run: mvn clean install
EOF

    # Create Dockerfile
    cat <<EOF > Dockerfile
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY . .
RUN ./mvnw clean install
CMD ["java", "-jar", "target/*.jar"]
EOF

    # Create docker-compose.yml
    cat <<EOF > docker-compose.yml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "8080:8080"
EOF

    # Create branches
    for branch in "${BRANCHES[@]}"; do
      log_message "Creating branch: $branch"
      git checkout -b $branch
      git push -u origin $branch
    done

    # Set default branch
    gh repo edit "$ORG_NAME/$repo_name" --default-branch $DEFAULT_BRANCH

    # Lock main branch
    gh api repos/$ORG_NAME/$repo_name/branches/main/protection -X PUT -f required_pull_request_reviews.dismiss_stale_reviews=true

    # Set branch protection rules for dev branch
    gh api repos/$ORG_NAME/$repo_name/branches/dev/protection -X PUT -f required_pull_request_reviews.dismiss_stale_reviews=true

    cd ..
  else
    log_message "Error creating repository: $repo_name"
  fi
}

# Iterate through each repository
for repo in "${REPOS[@]}"; do
  create_repo_and_branches $repo
done

log_message "Setup complete for all repositories."
