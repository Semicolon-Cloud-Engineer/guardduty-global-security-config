#!/bin/bash

# Check if a tag name is provided
if [ -z "$1" ]; then
  echo "Error: No tag name provided."
  echo "Usage: ./git-tag.sh <tag-type> <version/feature/bugfix>"
  exit 1
fi

TAG_TYPE=$1
TAG_NAME=$2

# Define tag prefixes
RELEASE_PREFIX="v"
FEATURE_PREFIX="feature/"
BUGFIX_PREFIX="fix/"
HOTFIX_PREFIX="hotfix/"
BETA_PREFIX="beta/v"
ALPHA_PREFIX="alpha/v"

case $TAG_TYPE in
  release)
    git tag "$RELEASE_PREFIX$TAG_NAME"
    ;;
  feature)
    git tag "$FEATURE_PREFIX$TAG_NAME"
    ;;
  bugfix)
    git tag "$BUGFIX_PREFIX$TAG_NAME"
    ;;
  hotfix)
    git tag "$HOTFIX_PREFIX$TAG_NAME"
    ;;
  beta)
    git tag "$BETA_PREFIX$TAG_NAME"
    ;;
  alpha)
    git tag "$ALPHA_PREFIX$TAG_NAME"
    ;;
  *)
    echo "Invalid tag type. Choose from: release, feature, bugfix, hotfix, beta, alpha."
    exit 1
    ;;
esac

# Push the tag to the remote repository
git push origin "$TAG_NAME"

echo "Tag $TAG_TYPE/$TAG_NAME created and pushed successfully."
