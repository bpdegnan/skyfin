#!/usr/bin/env bash
set -euo pipefail

SSH_CONFIG="${SSH_CONFIG:-$HOME/.ssh/config}"
REMOTE="${1:-origin}"

die() {
    echo "error: $*" >&2
    exit 1
}

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

need_cmd git
need_cmd awk
need_cmd sed

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "not inside a git repository"

[ -r "$SSH_CONFIG" ] || die "cannot read $SSH_CONFIG"

current_url="$(git remote get-url "$REMOTE" 2>/dev/null || true)"
[ -n "$current_url" ] || die "remote '$REMOTE' does not exist"

# Extract simple Host aliases from ~/.ssh/config.
# Skips wildcards and negated patterns.
mapfile -t hosts < <(
    awk '
        BEGIN { IGNORECASE=1 }
        /^[[:space:]]*Host[[:space:]]+/ {
            for (i = 2; i <= NF; i++) {
                h = $i
                if (h !~ /[*?]/ && h !~ /^!/) print h
            }
        }
    ' "$SSH_CONFIG" | sort -u
)

[ "${#hosts[@]}" -gt 0 ] || die "no usable Host aliases found in $SSH_CONFIG"

echo "Current $REMOTE URL:"
echo "  $current_url"
echo

echo "Available SSH personalities from $SSH_CONFIG:"
select chosen_host in "${hosts[@]}" "cancel"; do
    if [ "${chosen_host:-}" = "cancel" ]; then
        echo "cancelled"
        exit 0
    fi

    if [ -n "${chosen_host:-}" ]; then
        break
    fi

    echo "Invalid selection"
done

# Convert common GitHub SSH URL formats to use the selected Host alias.
#
# Examples:
#   git@github.com:bpdegnan/skyfin.git
#     -> git@github-bpdegnan:bpdegnan/skyfin.git
#
#   ssh://git@github.com/bpdegnan/skyfin.git
#     -> ssh://git@github-bpdegnan/bpdegnan/skyfin.git
#
#   https://github.com/bpdegnan/skyfin.git
#     -> git@github-bpdegnan:bpdegnan/skyfin.git

new_url=""

case "$current_url" in
    git@*:*.git|git@*:*/*)
        # scp-like SSH URL: git@host:owner/repo.git
        path="${current_url#git@*:}"
        new_url="git@${chosen_host}:${path}"
        ;;

    ssh://git@*/*)
        # ssh://git@host/owner/repo.git
        path="${current_url#ssh://git@*/}"
        new_url="ssh://git@${chosen_host}/${path}"
        ;;

    https://github.com/*|http://github.com/*)
        # HTTPS GitHub URL
        path="${current_url#https://github.com/}"
        path="${path#http://github.com/}"
        new_url="git@${chosen_host}:${path}"
        ;;

    *)
        echo "I do not recognize this remote URL format:"
        echo "  $current_url"
        echo
        echo "Enter the repository path manually, for example:"
        echo "  bpdegnan/skyfin.git"
        read -r -p "repo path: " path
        [ -n "$path" ] || die "empty repo path"
        new_url="git@${chosen_host}:${path}"
        ;;
esac

echo
echo "New $REMOTE URL will be:"
echo "  $new_url"
echo
read -r -p "Apply this change? [y/N] " answer

case "$answer" in
    y|Y|yes|YES)
        git remote set-url "$REMOTE" "$new_url"
        echo
        echo "Updated $REMOTE:"
        git remote -v
        echo
        echo "Testing SSH authentication:"
        ssh -T "git@${chosen_host}" || true
        echo
        echo "Done. You can now try:"
        echo "  git push -u $REMOTE $(git branch --show-current)"
        ;;
    *)
        echo "no changes made"
        ;;
esac

