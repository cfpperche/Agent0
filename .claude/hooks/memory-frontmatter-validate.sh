#!/usr/bin/env bash
exec bash "$(dirname "$0")/../../.agent0/hooks/$(basename "$0")" "$@"
