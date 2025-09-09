#!/bin/bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check dependencies
check_dependencies() {
    local deps=("curl" "jq" "tar" "sha256sum" "xz")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    # Handle macOS differences
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! command -v sha256sum &> /dev/null && command -v shasum &> /dev/null; then
            # Create sha256sum alias for macOS
            alias sha256sum='shasum -a 256'
        elif ! command -v shasum &> /dev/null; then
            missing+=("shasum")
        fi
    fi
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing required dependencies: ${missing[*]}"
        exit 1
    fi
}

# Verify SHA256 checksum
verify_checksum() {
    local file="$1"
    local expected="$2"
    
    log "Verifying checksum for $file"
    
    local actual
    if [[ "$OSTYPE" == "darwin"* ]]; then
        actual=$(shasum -a 256 "$file" | cut -d' ' -f1)
    else
        actual=$(sha256sum "$file" | cut -d' ' -f1)
    fi
    
    if [[ "$actual" != "$expected" ]]; then
        error "Checksum mismatch for $file"
        error "Expected: $expected"
        error "Actual:   $actual"
        return 1
    fi
    
    success "Checksum verified for $file"
}

# Download file with progress
download_file() {
    local url="$1"
    local output="$2"
    local expected_sha="$3"
    
    if [[ -f "$output" ]]; then
        log "File $output already exists, verifying checksum..."
        if verify_checksum "$output" "$expected_sha"; then
            return 0
        else
            warn "Checksum failed, re-downloading..."
            rm -f "$output"
        fi
    fi
    
    log "Downloading $(basename "$output")..."
    curl -L --progress-bar -o "$output" "$url"
    
    verify_checksum "$output" "$expected_sha"
}

# Extract binary from archive and repack
process_binary() {
    local tool="$1"
    local version="$2"
    local url="$3"
    local sha256="$4"
    local file_path="$5"
    local platform="$6"
    
    local archive_name=$(basename "$url")
    local output_name="${tool}-${version}-${platform}.tar.gz"
    local temp_dir=$(mktemp -d)
    
    log "Processing $tool for $platform..."
    
    # Download archive
    download_file "$url" "$archive_name" "$sha256"
    
    # Extract the specific binary
    log "Extracting $file_path from $archive_name..."
    
    if [[ "$archive_name" == *.tar.xz ]]; then
        tar -xf "$archive_name" -C "$temp_dir" "$file_path"
    elif [[ "$archive_name" == *.tar.gz ]]; then
        tar -xzf "$archive_name" -C "$temp_dir" "$file_path"
    else
        error "Unsupported archive format: $archive_name"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Create output directory structure
    local binary_name=$(basename "$file_path")
    local output_dir="$temp_dir/output"
    mkdir -p "$output_dir"
    
    # Copy binary to output directory
    cp "$temp_dir/$file_path" "$output_dir/$binary_name"
    
    # Make sure binary is executable
    chmod +x "$output_dir/$binary_name"
    
    # Create optimized tar.gz
    log "Creating optimized archive: $output_name"
    local current_dir=$(pwd)
    (cd "$output_dir" && tar -czf "$current_dir/$output_name" "$binary_name")
    
    # Get sizes for comparison
    local original_size=$(stat -c%s "$archive_name" 2>/dev/null || stat -f%z "$archive_name")
    local optimized_size=$(stat -c%s "$output_name" 2>/dev/null || stat -f%z "$output_name")
    local reduction=0
    if [[ -n "$optimized_size" && "$optimized_size" -gt 0 && "$original_size" -gt 0 ]]; then
        reduction=$((100 - (optimized_size * 100 / original_size)))
    fi
    
    local size_display="unknown size"
    if [[ -n "$optimized_size" && "$optimized_size" -gt 0 ]]; then
        if command -v numfmt &> /dev/null; then
            size_display="$(numfmt --to=iec "$optimized_size")"
        else
            size_display="${optimized_size} bytes"
        fi
    fi
    
    success "Created $output_name ($size_display, ${reduction}% smaller than original)"
    
    # Clean up
    rm -rf "$temp_dir"
    
    # Optionally remove original archive to save space
    if [[ "${KEEP_ARCHIVES:-false}" != "true" ]]; then
        rm -f "$archive_name"
    fi
}

# Main function
main() {
    local config_file="${1:-config.json}"
    
    if [[ ! -f "$config_file" ]]; then
        error "Configuration file $config_file not found"
        exit 1
    fi
    
    log "Checking dependencies..."
    check_dependencies
    
    log "Reading configuration from $config_file..."
    
    # Get list of tools
    local tools=($(jq -r 'keys[]' "$config_file"))
    
    for tool in "${tools[@]}"; do
        log "Processing tool: $tool"
        
        local version=$(jq -r ".[\"$tool\"].version" "$config_file")
        local binaries_count=$(jq -r ".[\"$tool\"].binaries | length" "$config_file")
        
        log "Version: $version, Binaries: $binaries_count"
        
        for ((i=0; i<binaries_count; i++)); do
            local url=$(jq -r ".[\"$tool\"].binaries[$i].url" "$config_file")
            local sha256=$(jq -r ".[\"$tool\"].binaries[$i].sha256" "$config_file")
            local file_path=$(jq -r ".[\"$tool\"].binaries[$i].file" "$config_file")
            local platform=$(jq -r ".[\"$tool\"].binaries[$i].platform" "$config_file")
            
            process_binary "$tool" "$version" "$url" "$sha256" "$file_path" "$platform"
        done
    done
    
    success "All binaries processed successfully!"
}

# Show usage
usage() {
    echo "Usage: $0 [config.json]"
    echo ""
    echo "Environment variables:"
    echo "  KEEP_ARCHIVES=true  Keep original downloaded archives"
    echo ""
    echo "Examples:"
    echo "  $0                  # Use default config.json"
    echo "  $0 my-config.json   # Use custom config file"
    echo "  KEEP_ARCHIVES=true $0  # Keep original archives"
}

# Handle arguments
if [[ $# -gt 1 ]] || [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

# Run main function
main "$@"
