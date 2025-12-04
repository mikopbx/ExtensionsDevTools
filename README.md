# MikoPBX Extensions Development Tools

A collection of utilities for MikoPBX module development, JavaScript compilation, and feature branch management.

## Tools Overview

| Tool | Description | Documentation |
|------|-------------|---------------|
| [**babel/**](./babel/) | ES6+ to ES5 JavaScript compiler with Docker support | [babel/README.md](./babel/README.md) |
| [**modules/**](./modules/) | Scripts for creating new MikoPBX modules | [modules/README.md](./modules/README.md) |
| [**worktrees/**](./worktrees/) | Git worktree management for feature development | [worktrees/README.md](./worktrees/README.md) |

## Quick Start

### Compile JavaScript (ES6+ to ES5)

```bash
# Using pre-built Docker container (recommended)
docker pull ghcr.io/mikopbx/babel-compiler:latest

docker run --rm -v "/path/to/project:/project" \
  ghcr.io/mikopbx/babel-compiler:latest \
  "/project/sites/admin-cabinet/assets/js/src/main/form.js"
```

### Create New Module

```bash
cd /path/to/your/modules
./modules/create_module.sh 'ModuleMyFeature'
```

### Setup Feature Development Environment

```bash
# From MikoPBX Core directory
./worktrees/create-feature-worktree.sh my-feature develop
```

## Babel Compiler Docker Image

Pre-built multi-architecture Docker image available at:

```
ghcr.io/mikopbx/babel-compiler:latest
```

Supports:
- **linux/amd64** - Standard Linux/Windows
- **linux/arm64** - Apple Silicon (M1/M2/M3), ARM servers

The image is automatically rebuilt when changes are pushed to the `babel/` directory.

## Repository Structure

```
ExtensionsDevTools/
├── README.md                       # This file
├── LICENSE                         # MIT License
├── babel/                          # JavaScript compiler
│   ├── README.md
│   ├── Dockerfile
│   ├── babel-compile.js
│   ├── babel.config.json
│   ├── docker-entrypoint.sh
│   ├── package.json
│   └── package-lock.json
├── modules/                        # Module creation tools
│   ├── README.md
│   ├── create_module.sh
│   ├── mod_replace.py
│   └── mod_replace.sh
├── worktrees/                      # Feature branch management
│   ├── README.md
│   └── create-feature-worktree.sh
└── .github/
    └── workflows/
        └── docker-publish.yml      # Auto-build Babel container
```

## Requirements

### For Babel Compiler
- Docker (recommended) or Node.js 18+

### For Module Creation
- Git
- Python 3.x with GitPython (optional, for `mod_replace.py`)

### For Worktree Management
- Git with worktree support
- Docker and Docker Compose
- Bash shell

## Integration with Claude Code

This repository provides tools that integrate with Claude Code for MikoPBX development:

1. **Babel compilation** - Compile JavaScript files directly using the Docker container
2. **Feature worktrees** - Automatically generates `CLAUDE.local.md` with project-specific configuration
3. **Module scaffolding** - Quick creation of new modules following MikoPBX conventions

## License

MIT License - see [LICENSE](./LICENSE) file.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Related Resources

- [MikoPBX Documentation](https://docs.mikopbx.com/)
- [ModuleTemplate](https://github.com/mikopbx/ModuleTemplate) - Base template for modules
- [MikoPBX Core](https://github.com/mikopbx/Core) - Main MikoPBX repository
