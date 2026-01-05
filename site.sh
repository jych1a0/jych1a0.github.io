#!/bin/bash

# Site Style Manager
# Usage:
#   ./site.sh status  - Check content version across all style branches
#   ./site.sh switch <style>  - Switch main to specified style
#   ./site.sh styles  - List available styles

STYLES=("bento-box" "swiss-modernism" "bootstrap-academic")
STYLE_BRANCHES=("style/bento-box" "style/swiss-modernism" "style/bootstrap-academic")

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

get_content_version() {
    local branch=$1
    git show "$branch:index.html" 2>/dev/null | grep -oP '<!-- content-version: \K[^-]+-v\d+' || echo "not set"
}

get_current_style() {
    grep -oP '<!-- style: \K[^ ]+' index.html 2>/dev/null || echo "unknown"
}

cmd_status() {
    echo -e "${BLUE}=== Site Sync Status ===${NC}\n"

    # Current main status
    local current_style=$(get_current_style)
    local main_version=$(get_content_version "main")
    echo -e "Main branch:"
    echo -e "  Style:   ${GREEN}${current_style}${NC}"
    echo -e "  Version: ${main_version}\n"

    echo "Style branches:"

    local all_synced=true
    local first_version=""

    for i in "${!STYLES[@]}"; do
        local style="${STYLES[$i]}"
        local branch="${STYLE_BRANCHES[$i]}"
        local version=$(get_content_version "$branch")

        if [ -z "$first_version" ]; then
            first_version="$version"
        fi

        if [ "$version" != "$first_version" ]; then
            all_synced=false
            echo -e "  ${YELLOW}${style}${NC}: ${version} ${RED}(out of sync)${NC}"
        else
            echo -e "  ${GREEN}${style}${NC}: ${version}"
        fi
    done

    echo ""
    if [ "$all_synced" = true ] && [ "$first_version" != "not set" ]; then
        echo -e "${GREEN}All style branches are synced.${NC}"
    elif [ "$first_version" = "not set" ]; then
        echo -e "${YELLOW}Content version not set. Run this after adding version markers.${NC}"
    else
        echo -e "${RED}Some branches are out of sync!${NC}"
    fi
}

cmd_switch() {
    local target_style=$1

    if [ -z "$target_style" ]; then
        echo -e "${RED}Error: Please specify a style${NC}"
        echo "Usage: ./site.sh switch <style>"
        echo "Available styles: ${STYLES[*]}"
        exit 1
    fi

    # Find matching branch
    local target_branch=""
    for i in "${!STYLES[@]}"; do
        if [ "${STYLES[$i]}" = "$target_style" ]; then
            target_branch="${STYLE_BRANCHES[$i]}"
            break
        fi
    done

    if [ -z "$target_branch" ]; then
        echo -e "${RED}Error: Unknown style '${target_style}'${NC}"
        echo "Available styles: ${STYLES[*]}"
        exit 1
    fi

    # Check if already on this style
    local current_style=$(get_current_style)
    if [ "$current_style" = "$target_style" ]; then
        echo -e "${YELLOW}Already using ${target_style} style.${NC}"
        exit 0
    fi

    # Switch
    echo -e "Switching to ${GREEN}${target_style}${NC} style..."

    git checkout "$target_branch" -- index.html zh.html

    if [ $? -eq 0 ]; then
        git add index.html zh.html
        git commit -m "Switch to ${target_style} style"
        git push origin main
        echo -e "${GREEN}Done! Site now uses ${target_style} style.${NC}"
    else
        echo -e "${RED}Failed to switch style.${NC}"
        exit 1
    fi
}

cmd_styles() {
    echo -e "${BLUE}Available styles:${NC}"
    for style in "${STYLES[@]}"; do
        echo "  - $style"
    done
}

cmd_help() {
    echo "Site Style Manager"
    echo ""
    echo "Usage:"
    echo "  ./site.sh status          Check content version across all branches"
    echo "  ./site.sh switch <style>  Switch main to specified style"
    echo "  ./site.sh styles          List available styles"
    echo "  ./site.sh help            Show this help"
}

# Main
case "$1" in
    status)
        cmd_status
        ;;
    switch)
        cmd_switch "$2"
        ;;
    styles)
        cmd_styles
        ;;
    help|--help|-h)
        cmd_help
        ;;
    *)
        cmd_help
        exit 1
        ;;
esac
