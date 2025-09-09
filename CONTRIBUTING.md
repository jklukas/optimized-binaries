# Contributing to Optimized Binaries

## 🚀 Quick Start

1. **Fork and clone** the repository or make a new branch from `main`
2. **Make your changes** (add new binaries, fix bugs, etc.)
3. **Test locally** with `./test-local.sh`
4. **Submit a pull request**
5. **Tag a release** to trigger automated deployment

## 📋 Types of Contributions

### Adding New Binaries/Tools

The most common contribution is adding new binary configurations to optimize download sizes for other tools.

#### Example: Adding a New Tool

1. **Edit `config.json`** to add your tool:

```json
{
  "clang-format": { ... },
  "your-new-tool": {
    "version": "1.2.3",
    "binaries": [
      {
        "kind": "archive",
        "url": "https://releases.example.com/your-tool-1.2.3-linux.tar.gz",
        "sha256": "abc123...",
        "file": "your-tool-1.2.3/bin/your-tool",
        "os": "linux",
        "cpu": "x86_64", 
        "platform": "linux-x86_64"
      }
    ]
  }
}
```

2. **Required fields:**
   - `version`: Tool version (used in output filename)
   - `url`: Download URL for source archive
   - `sha256`: SHA256 checksum for verification
   - `file`: Path to binary within the archive
   - `platform`: Platform ID (used in filename: `tool-version-platform.tar.gz`)

3. **Find SHA256 checksums:**
```bash
# Download the file and compute checksum
curl -L -O "https://releases.example.com/tool.tar.gz"
sha256sum tool.tar.gz  # Linux
shasum -a 256 tool.tar.gz  # macOS
```

#### Supported Archive Formats

- `.tar.xz` - Most common for LLVM releases
- `.tar.gz` - Standard gzipped tarballs
- More formats can be added to the script if needed

### Updating Existing Tools

To update to a newer version:

1. **Update the version** in `config.json`
2. **Update URLs** to point to new release
3. **Update SHA256 checksums** for new archives
4. **Update file paths** if they changed in the new version

## 🧪 Testing Your Changes

### Local Testing

Always test your changes before submitting:

```bash
# Test the optimization process
./test-local.sh

# Test with a custom config
./optimize-binaries.sh my-test-config.json

# Keep original archives for debugging
KEEP_ARCHIVES=true ./optimize-binaries.sh
```

### What to Verify

- [ ] Archives download successfully
- [ ] SHA256 checksums match
- [ ] Binaries extract correctly
- [ ] Output files are properly named
- [ ] File sizes show significant reduction
- [ ] Binaries are executable (when testable on your platform)

## 🏷️ Creating Releases

Releases are triggered automatically by git tags that match specific patterns.

### Tag Naming Convention

Use the format: `<tool-name>-<version>`

Examples:
- `clang-format-16.0.0`
- `my-tool-1.2.3`

### Release Process

1. **Commit your changes:**
```bash
git add config.json
git commit -m "Add my-tool 1.2.3 configuration"
git push origin main
```

2. **Create and push a tag:**
```bash
# Create annotated tag
git tag -a my-tool-1.2.3 -m "Release my-tool 1.2.3 optimized binaries"

# Push the tag (this triggers GitHub Actions)
git push origin my-tool-1.2.3
```

3. **Monitor the build:**
   - Go to GitHub Actions tab
   - Watch the "Optimize Binaries" workflow
   - Check for any errors in the logs

4. **Verify the release:**
   - Check the Releases page on GitHub
   - Download and test the generated binaries
   - Verify file sizes and naming

### Manual Release Trigger

You can also trigger releases manually:

1. Go to **Actions** → **Optimize Binaries** → **Run workflow**
2. Optionally specify:
   - Custom config file
   - Custom tag name
3. Click **Run workflow**

## 🔧 Development Setup

### Prerequisites

Install required tools:

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install curl jq xz-utils

# macOS
brew install jq xz

# Verify installation
./optimize-binaries.sh --help
```

## 🎯 Project Goals

This project aims to:

- **Reduce download sizes** by 90%+ for binary tools
- **Simplify deployment** with automated GitHub Actions
- **Support multiple platforms** (Linux, macOS)
- **Maintain security** through checksum verification
- **Stay minimal** using only bash scripts and standard tools

When contributing, keep these goals in mind and prefer simple, robust solutions.

## 📈 Release Management

### Versioning Strategy

- Use **upstream versions** for tool releases (e.g., `clang-format-16.0.0`)
- For project changes, use semantic versioning (e.g., `v1.2.3`)
- Multiple tools can be released simultaneously

### Release Artifacts

Each release includes:
- Optimized `.tar.gz` files for each platform
- GitHub release with download links
- Workflow artifacts (retained for 30 days)
- Release notes with size comparisons
