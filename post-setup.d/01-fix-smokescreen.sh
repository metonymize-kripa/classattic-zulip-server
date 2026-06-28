#!/bin/bash
find /etc/supervisor/conf.d/zulip/ -name '*.conf' -exec \
    grep -l 'HTTP_proxy' {} \; | while read -r f; do
    if ! grep -q 'no_proxy' "$f"; then
        sed -i 's/\(environment=.*\)HTTP_proxy/\1no_proxy=".exe.xyz",HTTP_proxy/' "$f"
    fi
done
