#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EXIT_CODE=0
TOTAL_FILES=0
TOTAL_MERMAID=0

BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC} $1"; }
pass()  { echo -e "${GREEN}[PASS]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail()  { echo -e "${RED}[FAIL]${NC} $1"; EXIT_CODE=1; }
header(){ echo -e "\n${BOLD}$1${NC}\n$(printf '=%.0s' $(seq 1 ${#1}))"; }

# Regex patterns for OLD broken directory references
OLD_REFS=(
    '01-Fundamentals'
    '03-Databases'
    '04-Caching'
    '05-Message-Queues'
    '07-Cloud-Architecture'
    '10-Open-Source'
    '11-Production-Incidents'
    '12-Hands-On'
    '13-System-Design-Interviews'
    '14-Staff-Engineer-Level'
)

# Regex for checking file naming: NN-description.md (numbers 01-99)
NAME_REGEX='^[0-9]{2}-[A-Za-z0-9].+\.md$'

header "1. File Naming Convention"
while IFS= read -r file; do
    rel="${file#$ROOT/}"
    basename=$(basename "$file")
    dirname=$(dirname "$file")
    parent=$(basename "$dirname")

    # Skip root files (README.md, CONTRIBUTING.md, etc.) and READMEs
    if [[ "$parent" =~ ^[0-9]{2} ]]; then
        if [[ "$basename" != "README.md" ]]; then
            TOTAL_FILES=$((TOTAL_FILES + 1))
            if [[ ! "$basename" =~ $NAME_REGEX ]]; then
                fail "Bad filename: $rel (expected NN-description.md)"
            fi
        fi
    fi
done < <(find "$ROOT" -maxdepth 3 -name '*.md' -not -path '*/.git/*' -not -path '*/node_modules/*')

pass "All content files follow NN-description.md naming"

header "2. Module Numbering Completeness"
EXPECTED_MODULES=$(seq -w 1 21)
ACTUAL_MODULES=""
while IFS= read -r dir; do
    d=$(basename "$dir")
    num="${d:0:2}"
    ACTUAL_MODULES="$ACTUAL_MODULES $num"
done < <(find "$ROOT" -maxdepth 1 -type d -name '[0-9][0-9]-*' | sort)

for num in $EXPECTED_MODULES; do
    found=false
    for a in $ACTUAL_MODULES; do
        [[ "$a" == "$num" ]] && found=true && break
    done
    if ! $found; then
        fail "Missing module directory: $num-*"
    fi
done
pass "All 21 modules (01-21) present"

header "3. Module README Navigation"
while IFS= read -r dir; do
    readme="$dir/README.md"
    d=$(basename "$dir")
    num="${d:0:2}"
    if [[ ! -f "$readme" ]]; then
        fail "Missing README.md in $d"
        continue
    fi
    content=$(cat "$readme")
    if [[ "$num" != "01" ]] && ! echo "$content" | grep -q 'Previous:'; then
        fail "$d/README.md missing Previous: link"
    fi
    if [[ "$num" != "21" ]] && ! echo "$content" | grep -q 'Next:'; then
        fail "$d/README.md missing Next: link"
    fi
done < <(find "$ROOT" -maxdepth 1 -type d -name '[0-9][0-9]-*' | sort)
pass "All module READMEs have correct navigation"

header "4. Cross-Module Reference Integrity"
violations=0
while IFS= read -r file; do
    rel="${file#$ROOT/}"
    for old_ref in "${OLD_REFS[@]}"; do
        if grep -q "$old_ref" "$file" 2>/dev/null; then
            fail "$rel contains old reference: $old_ref"
            violations=$((violations + 1))
        fi
    done
done < <(find "$ROOT" -name '*.md' -not -path '*/.git/*' -not -path '*/node_modules/*')

if [[ "$violations" -eq 0 ]]; then
    pass "Zero old/broken cross-module references"
fi

dirs_checked=0
bad_links=0
while IFS= read -r readme; do
    dir=$(dirname "$readme")
    d=$(basename "$dir")
    # Extract all linked .md files from the README
    while IFS= read -r link; do
        # link is like ../02-Networking/README.md or ./01-foo.md
        target_dir=$(dirname "$link")
        target_file=$(basename "$link")
        # Resolve relative to the README's directory
        abs_target=$(cd "$dir" && cd "$target_dir" 2>/dev/null && pwd 2>/dev/null)/$target_file
        if [[ ! -f "$abs_target" ]]; then
            link_display=$(echo "$link" | sed 's/\.\///')
            fail "$d/README.md links to non-existent: $link_display"
            bad_links=$((bad_links + 1))
        fi
        dirs_checked=$((dirs_checked + 1))
    done < <(grep -oP '\]\([^)]+\.md\)' "$readme" | sed 's/\](\|)$//g')
done < <(find "$ROOT" -maxdepth 2 -name 'README.md' -not -path '*/.git/*')

if [[ "$bad_links" -eq 0 ]]; then
    pass "All $(find "$ROOT" -maxdepth 2 -name 'README.md' -not -path '*/.git/*' | wc -l) README.md files have valid local links"
fi

header "5. Mermaid Diagram Coverage"
files_without_diagram=0
mermaid_count=0
while IFS= read -r file; do
    rel="${file#$ROOT/}"
    # Count mermaid code blocks with at least 3 lines of content
    diagram_count=$(awk '/```mermaid/{flag=1; next} /```/{flag=0} flag' "$file" | grep -c '^.\+' || true)
    if [[ "$diagram_count" -eq 0 ]]; then
        # Check if it's a README.md in a module dir
        dir=$(dirname "$file")
        parent=$(basename "$dir")
        is_module_readme=false
        if [[ "$(basename "$file")" == "README.md" && "$parent" =~ ^[0-9]{2} ]]; then
            is_module_readme=true
        fi
        # Top-level files (README.md, CONTRIBUTING.md) are allowed to skip
        if ! $is_module_readme; then
            files_without_diagram=$((files_without_diagram + 1))
            warn "No Mermaid diagram: $rel"
        fi
    else
        mermaid_count=$((mermaid_count + diagram_count))
    fi
done < <(find "$ROOT" -name '*.md' -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/README.md')

TOTAL_MERMAID=$mermaid_count

if [[ "$files_without_diagram" -gt 0 ]]; then
    echo ""
    warn "$files_without_diagram file(s) are missing Mermaid diagrams (3+ line content)"
else
    pass "All content files have Mermaid diagrams"
fi

echo ""
echo "   Total Mermaid diagrams found: $TOTAL_MERMAID"

header "6. File Count Consistency"
MODULE_COUNT=0
ALL_COUNT=0
while read -r line; do
    MODULE_COUNT=$((MODULE_COUNT + 1))
    ALL_COUNT=$((ALL_COUNT + line))
done < <(for dir in $(find "$ROOT" -maxdepth 1 -type d -name '[0-9][0-9]-*' | sort); do
    count=$(find "$dir" -maxdepth 1 -name '*.md' -not -name 'README.md' | wc -l)
    d=$(basename "$dir")
    echo "$count"
done)

ROOT_MD=$(find "$ROOT" -maxdepth 1 -name '*.md' -not -name 'README.md' | wc -l)
TOTAL_ALL=$((ALL_COUNT + ROOT_MD))

echo "   Total modules: $MODULE_COUNT"
echo "   Total content files (non-README): $TOTAL_ALL"
echo "   Total .md files (all): $(find "$ROOT" -name '*.md' -not -path '*/.git/*' | wc -l)"

# Summary
header "SUMMARY"
if [[ "$EXIT_CODE" -eq 0 ]]; then
    echo -e "${GREEN}All validations passed!${NC}"
else
    echo -e "${RED}Some validations failed.${NC}"
fi

exit $EXIT_CODE