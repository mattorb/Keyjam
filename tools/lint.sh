#!/bin/bash
REPO_ROOT=$(git rev-parse --show-toplevel)
xcrun swift-format lint -r -s -p "$REPO_ROOT"
