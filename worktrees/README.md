# Git Worktree Management for MikoPBX

Create isolated feature development environments with Docker infrastructure.

## Overview

The `create-feature-worktree.sh` script automates the creation of:
- Git worktree for feature branch
- Docker Compose configuration with unique ports
- Start/stop scripts
- Test environment configuration
- Development documentation

## Usage

Run from the **Core** repository directory:

```bash
# Basic usage - creates feature branch from current branch
./create-feature-worktree.sh my-feature

# Specify base branch
./create-feature-worktree.sh my-feature develop

# Specify custom ports (SSH:HTTP:HTTPS)
./create-feature-worktree.sh my-feature develop 8030:8188:8451

# List all registered projects and ports
./create-feature-worktree.sh --list

# Clean obsolete entries
./create-feature-worktree.sh --clean
```

## What Gets Created

```
../project-my-feature/          # Git worktree
├── tests/api/.env              # API test configuration
├── tests/api/.env.example      # Configuration template
└── CLAUDE.local.md             # Development guide

../dev_docker/
├── docker-compose-my-feature.yml   # Docker configuration
├── start-my-feature.sh             # Start script
├── README-my-feature.md            # Docker setup docs
├── .ports-registry                 # Port allocations
└── tmp/projects/my-feature/        # Container data
    ├── cf/                         # Configuration
    └── storage/                    # Storage data
```

## Port Management

Ports are automatically allocated to avoid conflicts:
- **SSH**: Starting from 8228
- **HTTP**: Starting from 8186
- **HTTPS**: Starting from 8449

The script maintains a `.ports-registry` file to track allocations.

### View registered ports

```bash
./create-feature-worktree.sh --list
```

Output:
```
PROJECT                        SSH        HTTP       HTTPS      CREATED
----------------------------------------------------------------------------------------------
my-feature                     8228       8186       8449       2025-01-07 10:30:00
another-feature                8229       8187       8450       2025-01-08 14:20:00
```

## Working with Feature Branches

### Start development

```bash
# Switch to feature worktree
cd ../project-my-feature

# Start Docker container
../dev_docker/start-my-feature.sh

# Access web interface
open http://localhost:8186
```

### Default credentials

- **Web**: admin / 123456789MikoPBX#1
- **SSH**: root / 123456789MikoPBX#1

### Container management

```bash
# View logs
docker logs -f mikopbx_my-feature

# Stop container
cd ../dev_docker
docker-compose -f docker-compose-my-feature.yml down

# Restart container
docker-compose -f docker-compose-my-feature.yml restart

# Access container shell
docker exec -it mikopbx_my-feature /bin/sh
```

### Run API tests

```bash
cd tests/api
pytest                    # Run all tests
pytest test_01_auth.py -v # Run specific test
```

## Cleanup

### Remove a feature worktree

```bash
# From Core directory
git worktree remove ../project-my-feature

# Optionally remove Docker files
rm ../dev_docker/docker-compose-my-feature.yml
rm ../dev_docker/start-my-feature.sh
rm ../dev_docker/README-my-feature.md
rm -rf ../dev_docker/tmp/projects/my-feature

# Clean registry
./create-feature-worktree.sh --clean
```

## Requirements

- Git with worktree support
- Docker and Docker Compose
- Bash shell
- Standard Unix utilities (sed, grep, mkdir, etc.)

## Integration with Claude Code

The script automatically creates `CLAUDE.local.md` with:
- Project-specific configuration
- Container access points
- Test setup instructions
- Container management commands

This enables Claude Code to work effectively with the feature environment.
