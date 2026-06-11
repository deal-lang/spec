#!/usr/bin/env bash
# =============================================================================
# download-references.sh
# =============================================================================
# Downloads all OMG normative reference materials for the MAAL language project.
# Organizes files into the maal-lang/spec/references/ directory structure.
#
# Usage:
#   chmod +x download-references.sh
#   ./download-references.sh [TARGET_DIR]
#
#   TARGET_DIR defaults to ./references if not specified.
#
# Prerequisites: curl
# Idempotent: existing files are skipped (delete a file to re-download it).
# =============================================================================

# No set -e — we handle every error explicitly so the script never dies silently.

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
TARGET="${1:-./references}"
SYSML_BASE="https://www.omg.org/spec/SysML/20250201"
KERML_BASE="https://www.omg.org/spec/KerML/20250201"
GITHUB_RELEASE="https://github.com/Systems-Modeling/SysML-v2-Release/releases"
MAX_RETRIES=3
RETRY_DELAY=2

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

PASS=0
FAIL=0
SKIP=0
ERRORS=()

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log()  { echo -e "${CYAN}[INFO]${NC}  $*"; }
ok()   { echo -e "${GREEN}  ✓${NC}  $*"; PASS=$((PASS + 1)); }
skip_msg() { echo -e "${YELLOW}  ⊘${NC}  $*"; SKIP=$((SKIP + 1)); }
fail_msg() { echo -e "${RED}  ✗${NC}  $*"; FAIL=$((FAIL + 1)); ERRORS+=("$1"); }

human_size() {
    local bytes=$1
    if [ "$bytes" -ge 1048576 ] 2>/dev/null; then
        echo "$((bytes / 1048576)).$((bytes % 1048576 * 10 / 1048576)) MB"
    elif [ "$bytes" -ge 1024 ] 2>/dev/null; then
        echo "$((bytes / 1024)) KB"
    else
        echo "${bytes} B"
    fi
}

download() {
    local url="$1"
    local dest="$2"
    local desc="$3"
    local filename
    filename="$(basename "$dest")"

    # Ensure parent directory exists
    mkdir -p "$(dirname "$dest")"

    # Skip if already exists and is non-empty
    if [ -f "$dest" ] && [ -s "$dest" ]; then
        local existing_size
        existing_size=$(wc -c < "$dest" | tr -d ' ')
        skip_msg "${desc}  ${DIM}(exists, $(human_size "$existing_size"))${NC}"
        return 0
    fi

    # Remove empty/partial files from previous failed attempts
    [ -f "$dest" ] && rm -f "$dest"

    local attempt=1
    while [ "$attempt" -le "$MAX_RETRIES" ]; do
        if [ "$attempt" -gt 1 ]; then
            echo -e "       ${DIM}retry ${attempt}/${MAX_RETRIES} after ${RETRY_DELAY}s...${NC}"
            sleep "$RETRY_DELAY"
        fi

        # Probe with HEAD request for HTTP status
        local http_status
        http_status=$(curl -sI -L -o /dev/null -w "%{http_code}" \
            --connect-timeout 10 "$url" 2>/dev/null) || http_status="000"

        if [ "$http_status" != "200" ]; then
            echo -e "       ${DIM}HTTP ${http_status} — ${url}${NC}"
            attempt=$((attempt + 1))
            continue
        fi

        # Download the file
        local curl_exit
        curl -fSL \
            --connect-timeout 15 \
            --max-time 120 \
            --retry 0 \
            -o "$dest" \
            "$url" 2>/dev/null
        curl_exit=$?

        if [ "$curl_exit" -eq 0 ] && [ -s "$dest" ]; then
            local size
            size=$(wc -c < "$dest" | tr -d ' ')
            ok "${desc}  ${DIM}→ ${filename} ($(human_size "$size"))${NC}"
            return 0
        fi

        # Clean up partial download
        rm -f "$dest"
        echo -e "       ${DIM}curl exit ${curl_exit}${NC}"
        attempt=$((attempt + 1))
    done

    fail_msg "${desc}  →  ${url}"
    return 1
}

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║     MAAL Language — OMG Reference Material Downloader      ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
log "Target: ${BOLD}${TARGET}${NC}"
log "Retries per file: ${MAX_RETRIES}"
echo ""

# ---------------------------------------------------------------------------
# Create directory structure
# ---------------------------------------------------------------------------
mkdir -p "$TARGET/omg-sysml-v2/domain-libraries"
mkdir -p "$TARGET/omg-kerml-v1/domain-libraries"
mkdir -p "$TARGET/omg-specs"
mkdir -p "$TARGET/github-pilot"

# =============================================================================
# SysML v2.0 — Abstract Syntax & Metamodel
# =============================================================================
echo -e "${BOLD}── SysML v2.0 — Abstract syntax & metamodel ───────────────${NC}"

download \
    "${SYSML_BASE}/SysML.json" \
    "$TARGET/omg-sysml-v2/SysML.json" \
    "SysML v2 JSON Schema (MAAL kernel target)"

download \
    "${SYSML_BASE}/SysML.xmi" \
    "$TARGET/omg-sysml-v2/SysML.xmi" \
    "SysML v2 Abstract Syntax (MOF XMI)"

download \
    "${SYSML_BASE}/SysMLv1Tov2.xmi" \
    "$TARGET/omg-sysml-v2/SysMLv1Tov2.xmi" \
    "SysML v1→v2 Transformation Model"

# =============================================================================
# SysML v2.0 — Domain Libraries
# =============================================================================
echo ""
echo -e "${BOLD}── SysML v2.0 — Domain libraries ──────────────────────────${NC}"

download \
    "${SYSML_BASE}/Systems-Library.kpar" \
    "$TARGET/omg-sysml-v2/domain-libraries/Systems-Library.kpar" \
    "Systems Library"

download \
    "${SYSML_BASE}/Quantities-and-Units-Domain-Library.kpar" \
    "$TARGET/omg-sysml-v2/domain-libraries/Quantities-and-Units-Domain-Library.kpar" \
    "Quantities & Units Domain Library"

download \
    "${SYSML_BASE}/Metadata-Domain-Library.kpar" \
    "$TARGET/omg-sysml-v2/domain-libraries/Metadata-Domain-Library.kpar" \
    "Metadata Domain Library"

download \
    "${SYSML_BASE}/Requirement-Derivation-Domain-Library.kpar" \
    "$TARGET/omg-sysml-v2/domain-libraries/Requirement-Derivation-Domain-Library.kpar" \
    "Requirement Derivation Domain Library"

download \
    "${SYSML_BASE}/Analysis-Domain-Library.kpar" \
    "$TARGET/omg-sysml-v2/domain-libraries/Analysis-Domain-Library.kpar" \
    "Analysis Domain Library"

download \
    "${SYSML_BASE}/Cause-and-Effect-Domain-Library.kpar" \
    "$TARGET/omg-sysml-v2/domain-libraries/Cause-and-Effect-Domain-Library.kpar" \
    "Cause & Effect Domain Library"

download \
    "${SYSML_BASE}/Geometry-Domain-Library.kpar" \
    "$TARGET/omg-sysml-v2/domain-libraries/Geometry-Domain-Library.kpar" \
    "Geometry Domain Library"

# =============================================================================
# SysML v2.0 — Informative Examples
# =============================================================================
echo ""
echo -e "${BOLD}── SysML v2.0 — Informative examples ──────────────────────${NC}"

download \
    "https://www.omg.org/cgi-bin/doc?ptc/25-04-31.sysml" \
    "$TARGET/omg-sysml-v2/SimpleVehicleModel.sysml" \
    "Simple Vehicle Model (transpiler test oracle)"

# =============================================================================
# KerML 1.0 — Abstract Syntax & Metamodel
# =============================================================================
echo ""
echo -e "${BOLD}── KerML 1.0 — Abstract syntax & metamodel ────────────────${NC}"

download \
    "${KERML_BASE}/KerML.json" \
    "$TARGET/omg-kerml-v1/KerML.json" \
    "KerML JSON Schema (semantic kernel foundation)"

download \
    "${KERML_BASE}/KerML.xmi" \
    "$TARGET/omg-kerml-v1/KerML.xmi" \
    "KerML Abstract Syntax (MOF XMI)"

download \
    "${KERML_BASE}/KerML-Model-Interchange.json" \
    "$TARGET/omg-kerml-v1/KerML-Model-Interchange.json" \
    "KerML Model Interchange JSON"

# =============================================================================
# KerML 1.0 — Domain Libraries
# =============================================================================
echo ""
echo -e "${BOLD}── KerML 1.0 — Domain libraries ───────────────────────────${NC}"

download \
    "${KERML_BASE}/Semantic-Library.kpar" \
    "$TARGET/omg-kerml-v1/domain-libraries/Semantic-Library.kpar" \
    "Semantic Library"

download \
    "${KERML_BASE}/Function-Library.kpar" \
    "$TARGET/omg-kerml-v1/domain-libraries/Function-Library.kpar" \
    "Function Library"

download \
    "${KERML_BASE}/Data-Type-Library.kpar" \
    "$TARGET/omg-kerml-v1/domain-libraries/Data-Type-Library.kpar" \
    "Data Type Library"

# =============================================================================
# Specification PDFs
# =============================================================================
echo ""
echo -e "${BOLD}── Specification PDFs ─────────────────────────────────────${NC}"

download \
    "https://www.omg.org/spec/SysML/2.0/Language/PDF" \
    "$TARGET/omg-specs/SysML-v2.0-Language-Spec.pdf" \
    "SysML v2.0 Language Specification"

download \
    "https://www.omg.org/spec/SysML/2.0/Transformation/PDF" \
    "$TARGET/omg-specs/SysML-v2.0-Transformation-Spec.pdf" \
    "SysML v2.0 Transformation Specification"

download \
    "https://www.omg.org/spec/KerML/1.0/PDF" \
    "$TARGET/omg-specs/KerML-v1.0-Language-Spec.pdf" \
    "KerML 1.0 Language Specification"

download \
    "https://www.omg.org/spec/SystemsModelingAPI/1.0/PDF" \
    "$TARGET/omg-specs/SystemsModelingAPI-v1.0-Spec.pdf" \
    "Systems Modeling API & Services 1.0"

# =============================================================================
# Generate SHA-256 checksums
# =============================================================================
echo ""
echo -e "${BOLD}── Checksums ──────────────────────────────────────────────${NC}"

CHECKSUM_FILE="$TARGET/SHA256SUMS"

# Pick the right hash command
HASH_CMD=""
if command -v sha256sum >/dev/null 2>&1; then
    HASH_CMD="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
    HASH_CMD="shasum -a 256"
fi

if [ -n "$HASH_CMD" ]; then
    : > "$CHECKSUM_FILE"
    hash_count=0
    while IFS= read -r file; do
        [ -z "$file" ] && continue
        relpath="${file#$TARGET/}"
        hash=$($HASH_CMD "$file" 2>/dev/null | cut -d' ' -f1) || continue
        echo "$hash  $relpath" >> "$CHECKSUM_FILE"
        hash_count=$((hash_count + 1))
    done <<EOF
$(find "$TARGET" -type f \
    ! -name "SHA256SUMS" \
    ! -name "MANIFEST.yaml" \
    ! -name "*.sh" \
    ! -name ".DS_Store" \
    2>/dev/null | sort)
EOF
    ok "SHA256SUMS written (${hash_count} files hashed)"
else
    echo -e "${YELLOW}  ⊘${NC}  No sha256sum or shasum found — skipping checksums"
fi

# =============================================================================
# Summary
# =============================================================================
echo ""
echo -e "${BOLD}══════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  Results${NC}"
echo -e "${BOLD}──────────────────────────────────────────────────────────────${NC}"
echo -e "  ${GREEN}Downloaded:${NC}  $PASS"
echo -e "  ${YELLOW}Skipped:${NC}     $SKIP  (already present)"
echo -e "  ${RED}Failed:${NC}      $FAIL"
echo ""

# Show what's on disk
echo -e "${BOLD}  Files on disk:${NC}"
find "$TARGET" -type f ! -name ".DS_Store" 2>/dev/null | sort | while IFS= read -r f; do
    [ -z "$f" ] && continue
    size=$(wc -c < "$f" | tr -d ' ')
    printf "    %-55s %s\n" "${f#$TARGET/}" "$(human_size "$size")"
done

# Report failures
if [ "$FAIL" -gt 0 ]; then
    echo ""
    echo -e "${RED}  Failed downloads:${NC}"
    for e in "${ERRORS[@]}"; do
        echo -e "    ${RED}✗${NC}  $e"
    done
    echo ""
    echo -e "  ${DIM}Delete any partial files and re-run to retry.${NC}"
fi

# Manual steps
echo ""
echo -e "${BOLD}── Manual: EBNF grammar files ─────────────────────────────${NC}"
echo ""
echo "  The SysML/KerML EBNF grammar files (.kebnf/.kgbnf) are only"
echo "  available in the GitHub release ZIP."
echo ""
echo "  Visit: ${GITHUB_RELEASE}"
echo ""
echo "  Extract doc/*.kebnf, doc/*.kgbnf, and doc/*.html into:"
echo "    ${TARGET}/github-pilot/"
echo ""
echo "  Or with gh CLI:"
echo "    gh release download --repo Systems-Modeling/SysML-v2-Release \\"
echo "      --pattern '*.zip' --dir /tmp/sysml-release"
echo "    unzip -j /tmp/sysml-release/*.zip '*/doc/*.kebnf' \\"
echo "      '*/doc/*.kgbnf' '*/doc/*.html' -d ${TARGET}/github-pilot/"
echo ""

echo -e "${BOLD}══════════════════════════════════════════════════════════════${NC}"

if [ "$FAIL" -gt 0 ]; then
    echo -e "${RED}Completed with ${FAIL} failure(s).${NC}"
    exit 1
else
    echo -e "${GREEN}All downloads completed successfully.${NC}"
    exit 0
fi
