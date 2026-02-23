# CLAUDE.md — ExtensionsDevTools

Development utilities for MikoPBX module development, JS compilation, Docker container management, and feature branch workflows.

## Repository Structure

```
ExtensionsDevTools/
├── babel/          # ES6+ to ES5 JavaScript compiler (Docker-based)
├── docker/         # Docker container management for dev environments
├── modules/        # Module scaffolding scripts
└── worktrees/      # Git worktree management for feature branches
```

## Tools

### docker/dev-compose.sh — Container & Module Management

Replaces manual `docker-compose -f ... -f ... -f ...` flag chains with declarative `modules.yml` config and auto-generated overlay.

**How it works:**
- Script lives here but operates from `../../dev_docker/` (where docker-compose files and container data reside)
- Creates `dev_docker/` on first run if absent
- Copies `modules.yml.example` as starting template
- Parses `modules.yml`, scans module directories, generates docker-compose overlay with volume mounts
- Bash 3 compatible (works with macOS default `/bin/bash`)

**Commands:**
```bash
./docker/dev-compose.sh up          # generate overlay + start container
./docker/dev-compose.sh down        # stop container
./docker/dev-compose.sh restart     # down + clear logs + up
./docker/dev-compose.sh enable  ID  # enable module in modules.yml + restart
./docker/dev-compose.sh disable ID  # disable module in modules.yml + restart
./docker/dev-compose.sh migrate     # run module DB migrations (no restart needed)
./docker/dev-compose.sh status      # show container + enabled modules
./docker/dev-compose.sh list        # list all modules with on/off status
./docker/dev-compose.sh generate    # regenerate overlay file only
./docker/dev-compose.sh ssh         # shell into container
```

**Environment variables:**
- `DEV_COMPOSE_BASE` — base docker-compose file (default: `docker-compose-modules-api-refactoring.yml`)
- `DEV_DOCKER_DIR` — override work directory (default: `../../dev_docker`)

**modules.yml format:**
```yaml
modules:
  ModuleUsersUI:
    enabled: true
  ModuleExampleAmi:
    path: ../Extensions/EXAMPLES/AMI/ModuleExampleAmi  # custom path
    enabled: true
  ModulePhoneBook:
    enabled: false  # listed but not mounted
```

Convention: if `path` omitted, defaults to `../Extensions/{ModuleID}`.

**Volume mapping per module** — auto-detects and mounts only existing directories:
- `App`, `Lib`, `Messages`, `Models`, `bin`, `agi-bin`, `Sounds` → `/storage/.../custom_modules/{ID}/`
- `vendor`, `composer.json`, `composer.lock` → `/storage/.../custom_modules/{ID}/`
- `public/assets/js`, `public/assets/css` → `/var/tmp/www_cache/{js,css}/{ID}`
- `App/Views` → `/var/tmp/www_cache/view/{ID}`

### docker/modules.yml.example — Module Configuration Template

Default module list matching the current `start-modules-api-refactoring.sh` setup. Copied to `dev_docker/modules.yml` on first `dev-compose.sh` run.

### babel/ — JavaScript Compiler

Docker-based ES6+ to ES5 transpiler using Babel with airbnb preset.

```bash
docker run --rm -v "/path/to/project:/project" \
  ghcr.io/mikopbx/babel-compiler:latest \
  "/project/path/to/file.js"
```

### modules/ — Module Scaffolding

Scripts to create new MikoPBX modules from ModuleTemplate.

```bash
./modules/create_module.sh 'ModuleMyFeature'
```

### worktrees/ — Feature Branch Management

Git worktree setup for parallel feature development with auto-generated docker-compose configs.

## Related

- `Core/src/Core/System/Upgrade/UpdateModulesDatabase.php` — CLI script for module DB migration (used by `dev-compose.sh migrate`)
- `Core/src/Core/System/Upgrade/UpdateDatabase.php` — `updateModulesDbStructure()` is public, safe to call directly (idempotent)
