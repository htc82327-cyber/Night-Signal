#!/bin/sh
set -eu

FOUND_NS="$(find .theos -type f -path '*/NightSignal.app/Info.plist' -print -quit || true)"
FOUND_PZ="$(find .theos -type f -path '*/PovoZka.app/Info.plist' -print -quit || true)"

if [ -z "$FOUND_NS" ]; then
  echo "ERROR: NightSignal.app/Info.plist is missing from staged bundle"
  exit 1
fi

if [ -z "$FOUND_PZ" ]; then
  echo "ERROR: PovoZka.app/Info.plist is missing from staged bundle"
  exit 1
fi

echo "NightSignal Info.plist: $FOUND_NS"
echo "PovoZka Info.plist: $FOUND_PZ"
echo "APP BUNDLES OK"
