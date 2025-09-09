# optimized-binaries

🚀 **Releases of optimized binaries pruned from upstream sources**

This project solves the problem of large, bloated binary distributions by extracting and repacking only the specific binaries you need. Instead of downloading massive archives (often 100MB+) that contain entire toolchains, get just the binary you want in a compact package (typically 90%+ smaller).

## 🎯 Problem Solved

When you need tools like `clang-format`, you typically have to download huge archives like:
- `clang+llvm-16.0.0-arm64-apple-darwin22.0.tar.xz` (187MB) → Just need `clang-format` (2.1MB)
- `clang+llvm-16.0.0-x86_64-linux-gnu-ubuntu-18.04.tar.xz` (215MB) → Just need `clang-format` (2.8MB)

This project automatically downloads, extracts, and repacks just the binaries you need.

## 🏗️ Project Structure

```
├── config.json              # Configuration for binaries to optimize
├── optimize-binaries.sh      # Main optimization script
├── test-local.sh            # Local testing script
├── .github/workflows/
│   └── optimize-binaries.yml # GitHub Actions for automated releases
└── README.md                # This file
```

## ⚙️ Configuration

Edit `config.json` to define which binaries to optimize:

```json
{
  "clang-format": {
    "version": "16.0.0",
    "binaries": [
      {
        "kind": "archive",
        "url": "https://github.com/llvm/llvm-project/releases/download/llvmorg-16.0.0/clang+llvm-16.0.0-arm64-apple-darwin22.0.tar.xz",
        "sha256": "2041587b90626a4a87f0de14a5842c14c6c3374f42c8ed12726ef017416409d9",
        "file": "clang+llvm-16.0.0-arm64-apple-darwin22.0/bin/clang-format",
        "os": "macos",
        "cpu": "arm64",
        "platform": "macos-arm64"
      }
    ]
  }
}
```

### Configuration Fields

- `version`: Tool version (used in output filename)
- `url`: Download URL for the source archive
- `sha256`: SHA256 checksum for verification
- `file`: Path to the binary within the archive
- `platform`: Platform identifier (used in output filename: `tool-version-platform.tar.gz`)

## 🚀 Usage

### Local Usage

1. **Install dependencies:**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install curl jq xz-utils
   
   # macOS  
   brew install jq xz
   ```

2. **Run optimization:**
   ```bash
   ./optimize-binaries.sh
   ```

3. **Test locally (optional):**
   ```bash
   ./test-local.sh
   ```

### GitHub Actions (Automated Releases)

The project includes automated GitHub Actions that will:

1. **Trigger on:**
   - Manual workflow dispatch
   - Git tags matching `clang-format-*` or `v*`

2. **Output:**
   - GitHub release with optimized binaries
   - Artifacts for workflow runs
   - Files named: `clang-format-<version>-<platform>.tar.gz`

3. **Manual trigger:**
   - Go to Actions → "Optimize Binaries" → "Run workflow"
   - Optionally specify custom config file and tag name

## 📦 Output

The script generates optimized archives named:
```
clang-format-16.0.0-macos-arm64.tar.gz
clang-format-16.0.0-linux-x86_64.tar.gz
```

Each archive contains just the binary, typically achieving 90%+ size reduction.

## 💡 Advanced Usage

### Environment Variables

- `KEEP_ARCHIVES=true` - Keep original downloaded archives (default: false)

### Custom Configuration

```bash
./optimize-binaries.sh my-custom-config.json
```

### Multiple Tools

You can configure multiple tools in the same config file:

```json
{
  "clang-format": { ... },
  "some-other-tool": { ... }
}
```

## 🔧 Requirements

- `bash` 4.0+
- `curl` - For downloading files
- `jq` - For JSON parsing  
- `tar` - For archive extraction/creation
- `xz` - For .xz archive support
- `sha256sum` (Linux) or `shasum` (macOS) - For checksum verification

## 🤝 Contributing

1. Fork the repository
2. Add your binary configuration to `config.json`
3. Test locally with `./test-local.sh`
4. Submit a pull request

## 📄 License

This project is released into the public domain. The optimized binaries retain their original licenses from upstream sources.

## ❓ FAQ

**Q: Why not use package managers?**
A: Package managers are great, but sometimes you need specific versions, cross-platform consistency, or want to avoid system dependencies.

**Q: Are the checksums verified?**
A: Yes! The script verifies SHA256 checksums before processing archives.

**Q: Can I add other tools besides clang-format?**
A: Absolutely! Just add them to `config.json` following the same structure.
