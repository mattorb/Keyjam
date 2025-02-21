#!/bin/bash
REPO_ROOT=$(git rev-parse --show-toplevel)
xcrun swift-format format -i -r "$REPO_ROOT"
