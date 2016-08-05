#!/usr/bin/env bash
#
# config/rwahs/env/production - Production environment configuration for integration script.
#

set -e
set -u

host='collections.histwest.org.au'
user='ca'
targetRoot='/data/deploy'
localSettingsRoot='/data/local'
localStorageRoot='/data/storage'
adminEmailAddress='rwahs@gaiaresources.com.au'
