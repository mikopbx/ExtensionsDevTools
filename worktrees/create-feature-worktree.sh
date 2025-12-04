#!/bin/bash

# MikoPBX Feature Worktree Setup Script
# Run this from the Core directory to create a new feature branch with worktree and Docker setup

set -e

# Get the directory paths
CORE_DIR="$(pwd)"
DEV_DOCKER_DIR="$(dirname "$CORE_DIR")/dev_docker"
PORTS_REGISTRY="$DEV_DOCKER_DIR/.ports-registry"

function show_usage() {
    echo "Usage: $0 <feature-name|--list|--clean> [base-branch] [ports]"
    echo ""
    echo "Creates a new feature branch, git worktree, and Docker infrastructure"
    echo ""
    echo "Arguments:"
    echo "  feature-name   The name for your feature branch"
    echo "  base-branch    Optional base branch (default: current branch)"
    echo "  ports          Optional port configuration (SSH:HTTP:HTTPS), e.g., '8028:8086:8449'"
    echo ""
    echo "Commands:"
    echo "  --list         List all registered projects with their ports"
    echo "  --clean        Remove entries for non-existing projects"
    echo ""
    echo "Examples:"
    echo "  $0 my-new-feature"
    echo "  $0 api-improvements develop"
    echo "  $0 bug-fix master 8030:8188:8451"
    echo "  $0 --list"
    echo "  $0 --clean"
    echo ""
}

function get_current_branch() {
    git rev-parse --abbrev-ref HEAD
}

function init_ports_registry() {
    mkdir -p "$DEV_DOCKER_DIR"
    if [ ! -f "$PORTS_REGISTRY" ]; then
        echo "# MikoPBX Projects Port Registry" > "$PORTS_REGISTRY"
        echo "# Format: PROJECT_NAME|SSH_PORT|HTTP_PORT|HTTPS_PORT|CREATED_DATE" >> "$PORTS_REGISTRY"
    fi
}

function register_ports() {
    local project_name="$1"
    local ssh_port="$2"
    local http_port="$3"
    local https_port="$4"
    local created_date=$(date +"%Y-%m-%d %H:%M:%S")

    init_ports_registry

    # Remove old entry if exists
    if grep -q "^${project_name}|" "$PORTS_REGISTRY"; then
        sed -i.bak "/^${project_name}|/d" "$PORTS_REGISTRY" && rm -f "${PORTS_REGISTRY}.bak"
    fi

    # Add new entry
    echo "${project_name}|${ssh_port}|${http_port}|${https_port}|${created_date}" >> "$PORTS_REGISTRY"
}

function get_registered_ports() {
    local project_name="$1"

    if [ -f "$PORTS_REGISTRY" ]; then
        grep "^${project_name}|" "$PORTS_REGISTRY" | cut -d'|' -f2-4 | tr '|' ':'
    fi
}

function list_registered_ports() {
    init_ports_registry

    echo "Registered MikoPBX Projects and Ports:"
    echo "======================================"
    printf "%-30s %-10s %-10s %-10s %-20s\n" "PROJECT" "SSH" "HTTP" "HTTPS" "CREATED"
    echo "----------------------------------------------------------------------------------------------"

    while IFS='|' read -r project ssh http https created; do
        if [[ ! "$project" =~ ^# ]]; then
            printf "%-30s %-10s %-10s %-10s %-20s\n" "$project" "$ssh" "$http" "$https" "$created"
        fi
    done < "$PORTS_REGISTRY"
}

function clean_ports_registry() {
    init_ports_registry

    local temp_file="${PORTS_REGISTRY}.tmp"
    local removed_count=0

    echo "Cleaning ports registry..."

    # Keep header
    grep "^#" "$PORTS_REGISTRY" > "$temp_file"

    # Check each project
    while IFS='|' read -r project ssh http https created; do
        if [[ ! "$project" =~ ^# ]]; then
            local safe_name=$(echo "$project" | sed 's/[^a-zA-Z0-9]/-/g')
            local compose_file="$DEV_DOCKER_DIR/docker-compose-${safe_name}.yml"
            local project_dir="../project-${project}"

            if [ -f "$compose_file" ] || [ -d "$project_dir" ]; then
                echo "${project}|${ssh}|${http}|${https}|${created}" >> "$temp_file"
            else
                echo "  Removing: $project (no files found)"
                ((removed_count++))
            fi
        fi
    done < "$PORTS_REGISTRY"

    mv "$temp_file" "$PORTS_REGISTRY"
    echo "✓ Removed $removed_count obsolete entries"
}

function is_port_in_use() {
    local port="$1"

    if [ -f "$PORTS_REGISTRY" ]; then
        grep -v "^#" "$PORTS_REGISTRY" | grep -q "|${port}|" && return 0
        grep -v "^#" "$PORTS_REGISTRY" | grep -q "|.*|${port}|.*|" && return 0
    fi

    return 1
}

function get_next_available_ports() {
    init_ports_registry

    local ssh_port=8228
    local http_port=8186
    local https_port=8449

    # Read all registered ports
    local used_ports=""
    if [ -f "$PORTS_REGISTRY" ]; then
        used_ports=$(grep -v "^#" "$PORTS_REGISTRY" | cut -d'|' -f2-4 | tr '|' '\n' | sort -n | uniq)
    fi

    # Find next available SSH port
    while echo "$used_ports" | grep -q "^${ssh_port}$" || lsof -i ":${ssh_port}" >/dev/null 2>&1; do
        ssh_port=$((ssh_port + 1))
    done

    # Find next available HTTP port
    while echo "$used_ports" | grep -q "^${http_port}$" || lsof -i ":${http_port}" >/dev/null 2>&1; do
        http_port=$((http_port + 1))
    done

    # Find next available HTTPS port
    while echo "$used_ports" | grep -q "^${https_port}$" || lsof -i ":${https_port}" >/dev/null 2>&1; do
        https_port=$((https_port + 1))
    done

    echo "$ssh_port:$http_port:$https_port"
}

function create_feature_branch() {
    local feature_name="$1"
    local base_branch="$2"
    
    echo "Creating feature branch '$feature_name' based on '$base_branch'..."
    
    # Fetch latest changes
    git fetch origin
    
    # Create the new branch
    if git show-ref --verify --quiet "refs/heads/$feature_name"; then
        echo "Branch '$feature_name' already exists locally"
        read -p "Do you want to delete and recreate it? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git branch -D "$feature_name"
            git checkout -b "$feature_name" "$base_branch"
        else
            echo "Using existing branch '$feature_name'"
        fi
    else
        git checkout -b "$feature_name" "$base_branch"
    fi
}

function create_worktree() {
    local feature_name="$1"
    local project_dir="../project-$feature_name"
    
    echo "Creating git worktree for branch '$feature_name'..."
    
    # Remove existing worktree if it exists
    if [ -d "$project_dir" ]; then
        echo "Removing existing worktree at $project_dir..."
        git worktree remove "$project_dir" --force 2>/dev/null || rm -rf "$project_dir"
    fi
    
    # Create the worktree
    git worktree add "$project_dir" "$feature_name"
    
    echo "✓ Worktree created at $project_dir"
}

function create_test_env_file() {
    local feature_name="$1"
    local http_port="$2"
    local project_dir="../project-$feature_name"
    local env_file="$project_dir/tests/api/.env"
    local env_example="$project_dir/tests/api/.env.example"
    local safe_name=$(echo "$feature_name" | sed 's/[^a-zA-Z0-9]/-/g')

    echo "Creating/updating tests/api/.env file..."

    # Create tests/api directory if it doesn't exist
    mkdir -p "$project_dir/tests/api"

    # Copy .env.example if it exists in Core and doesn't exist in project
    if [ -f "$CORE_DIR/tests/api/.env.example" ] && [ ! -f "$env_example" ]; then
        cp "$CORE_DIR/tests/api/.env.example" "$env_example"
        echo "✓ Copied .env.example to project"
    fi

    # Create or update .env file
    cat > "$env_file" << EOF
# MikoPBX REST API Test Configuration for ${feature_name}
# Auto-generated by create-feature-worktree.sh
# See .env.example for all available options and deployment scenarios

# ============================================================================
# API Configuration (Required)
# ============================================================================
MIKOPBX_API_URL=http://localhost:${http_port}/pbxcore/api/v3
MIKOPBX_API_USERNAME=admin
MIKOPBX_API_PASSWORD=123456789MikoPBX#1

# ============================================================================
# Execution Mode Configuration
# ============================================================================
# Docker container name (for local development)
MIKOPBX_CONTAINER=mikopbx_${safe_name}

# Execution mode (auto-detected if not set)
# Options: docker|api|ssh|local
MIKOPBX_EXECUTION_MODE=docker

# SSH configuration (uncomment for remote SSH access)
#MIKOPBX_SSH_HOST=192.168.1.100
#MIKOPBX_SSH_USER=root
#MIKOPBX_SSH_PORT=22

# ============================================================================
# Database Paths (defaults are fine for standard deployments)
# ============================================================================
#MIKOPBX_DB_PATH=/cf/conf/mikopbx.db
#MIKOPBX_CDR_DB_PATH=/storage/usbdisk1/mikopbx/astlogs/asterisk/cdr.db

# ============================================================================
# Storage Paths (defaults are fine for standard deployments)
# ============================================================================
#MIKOPBX_STORAGE_PATH=/storage/usbdisk1/mikopbx
#MIKOPBX_MONITOR_PATH=/storage/usbdisk1/mikopbx/astspool/monitor
#MIKOPBX_LOG_PATH=/storage/usbdisk1/mikopbx/log

# ============================================================================
# Test Configuration
# ============================================================================
ENABLE_CDR_SEED=1
ENABLE_CDR_CLEANUP=1
ENABLE_SYSTEM_RESET=0
EOF

    echo "✓ Created tests/api/.env with container-specific settings"
}

function update_claude_local() {
    local feature_name="$1"
    local http_port="$2"
    local https_port="$3"
    local ssh_port="$4"
    local project_dir="../project-$feature_name"
    local claude_local="$project_dir/CLAUDE.local.md"

    echo "Creating/updating CLAUDE.local.md..."

    # Copy template from Core if doesn't exist
    if [ ! -f "$claude_local" ] && [ -f "$CORE_DIR/CLAUDE.local.md" ]; then
        cp "$CORE_DIR/CLAUDE.local.md" "$claude_local"
    fi

    # Update or create CLAUDE.local.md with project-specific info
    cat > "$claude_local" << EOF
# Local Development Guide for MikoPBX - ${feature_name} Feature

This guide provides instructions for local development, debugging, and testing of MikoPBX using Docker.

## Project Configuration

**Feature Branch**: \`${feature_name}\`
**Container Name**: \`mikopbx_$(echo "$feature_name" | sed 's/[^a-zA-Z0-9]/-/g')\`

### Access Points
- **HTTP**: http://localhost:${http_port}
- **HTTPS**: https://localhost:${https_port}
- **SSH**: ssh root@localhost -p ${ssh_port}

### Default Credentials
- **Web**: admin / 123456789MikoPBX#1
- **SSH**: root / 123456789MikoPBX#1

## JavaScript Development

### Babel Transpilation
The project transpiles ES6+ JavaScript to ES5 for browser compatibility using Docker containers. Use \`mikopbx-babel-compile\` skill

### Development Workflow
1. Make changes in your local IDE
2. Files are automatically synced to the container
3. For JS changes, run the appropriate Babel transpilation command
4. Test changes in the web interface or via API
5. Check logs for any errors


### Playwright Debugging
- For debugging via MCP Playwright, use browser: \`http://localhost:${http_port}\`
- Login credentials:
  - Username: \`admin\`
  - Password: \`123456789MikoPBX#1\`


## Python API Tests Configuration

Tests are configured via \`tests/api/.env\` file with the following settings:

\`\`\`bash
MIKOPBX_API_URL=http://localhost:${http_port}/pbxcore/api/v3
MIKOPBX_CONTAINER=mikopbx_$(echo "$feature_name" | sed 's/[^a-zA-Z0-9]/-/g')
MIKOPBX_EXECUTION_MODE=docker
\`\`\`

### Running Tests
\`\`\`bash
# From project directory
cd tests/api
pytest

# Run specific test
pytest test_01_auth.py -v

# Run with verbose output
pytest -v -s
\`\`\`

For more details, see \`tests/api/README_CONFIG_REFACTORING.md\`


## ⛔ ABSOLUTE PRIORITIES - READ FIRST

### 🔍 MANDATORY SEARCH TOOL: ast-grep (sg)

**OBLIGATORY RULE**: ALWAYS use \`ast-grep\` (skill: \`mikopbx-code-search\`) as your PRIMARY and FIRST tool for ANY code search, pattern matching, or grepping task. This is NON-NEGOTIABLE.


**Enforcement**: If you use \`grep -r\` for code searching without attempting mikopbx-code-search skill first, STOP and retry with ast-grep. This is a CRITICAL requirement.
- Каждый раз перезапускай контейнер перед проверкой backend кода

## Container Management

### Start Container
\`\`\`bash
../dev_docker/start-$(echo "$feature_name" | sed 's/[^a-zA-Z0-9]/-/g').sh
\`\`\`

### View Logs
\`\`\`bash
docker logs -f mikopbx_$(echo "$feature_name" | sed 's/[^a-zA-Z0-9]/-/g')
\`\`\`

### Stop Container
\`\`\`bash
cd ../dev_docker
docker-compose -f docker-compose-$(echo "$feature_name" | sed 's/[^a-zA-Z0-9]/-/g').yml down
\`\`\`


### Delete Logs
\`\`\`bash
rm -rf tmp/projects/$(echo "$feature_name" | sed 's/[^a-zA-Z0-9]/-/g')/storage/usbdisk1/mikopbx/log
\`\`\`




### Restart Container
\`\`\`bash
cd ../dev_docker
docker-compose -f docker-compose-$(echo "$feature_name" | sed 's/[^a-zA-Z0-9]/-/g').yml restart
\`\`\`

### Access Container Shell
\`\`\`bash
docker exec -it mikopbx_$(echo "$feature_name" | sed 's/[^a-zA-Z0-9]/-/g') /bin/sh
\`\`\`
EOF

    echo "✓ Created/updated CLAUDE.local.md with project-specific configuration"
}

function create_docker_infrastructure() {
    local feature_name="$1"
    local ssh_port="$2"
    local http_port="$3"
    local https_port="$4"

    local safe_name=$(echo "$feature_name" | sed 's/[^a-zA-Z0-9]/-/g')
    local compose_file="$DEV_DOCKER_DIR/docker-compose-$safe_name.yml"
    local start_script="$DEV_DOCKER_DIR/start-$safe_name.sh"
    local readme_file="$DEV_DOCKER_DIR/README-$safe_name.md"

    echo "Creating Docker infrastructure..."

    # Register ports for this project
    register_ports "$feature_name" "$ssh_port" "$http_port" "$https_port"

    # Create test environment file
    create_test_env_file "$feature_name" "$http_port"

    # Update CLAUDE.local.md
    update_claude_local "$feature_name" "$http_port" "$https_port" "$ssh_port"
    
    # Create dev_docker directory if it doesn't exist
    mkdir -p "$DEV_DOCKER_DIR"
    
    # Create project cache directories
    mkdir -p "$DEV_DOCKER_DIR/tmp/projects/$safe_name"/{cf,storage,assets/{js,css,img}}
    
    # Create docker-compose.yml
    cat > "$compose_file" << EOF
services:
  mikopbx-${safe_name}:
    ports:
      - "${ssh_port}:${ssh_port}"  # SSH port
      - "${http_port}:${http_port}"  # Web port  
      - "${https_port}:${https_port}"  # HTTPS port
    container_name: "mikopbx_${safe_name}"
    hostname: "mikopbx-${safe_name}"
    image: "mikopbx/develop:2025.ARM.10"
    entrypoint: "/sbin/docker-entrypoint"
    restart: unless-stopped
    volumes:
      - ./resources/15-xdebug.ini:/etc/php.d/15-xdebug.ini:ro
      - ./resources/version.ini:/etc/version:ro
      - ./resources/nginx.disablecaches.conf:/etc/nginx/mikopbx/locations/static.conf:ro
      - ../Core/vendor:/offload/rootfs/usr/www/vendor:ro
      - ./tmp/projects/${safe_name}/cf:/cf
      - ./tmp/projects/${safe_name}/storage:/storage
      - ../project-${feature_name}/sites/admin-cabinet:/offload/rootfs/usr/www/sites/admin-cabinet:ro
      - ../project-${feature_name}/src:/offload/rootfs/usr/www/src:ro
      - ../project-${feature_name}/tests:/offload/rootfs/usr/www/tests:ro
      - ./tmp/projects/${safe_name}/storage/usbdisk1/mikopbx/tmp/www_cache/files_cache:/offload/rootfs/usr/www/sites/pbxcore/files/cache:rw
      - ../project-${feature_name}/sites/admin-cabinet/assets/js:/offload/rootfs/usr/www/sites/admin-cabinet/assets/js:rw
      - ../project-${feature_name}/sites/admin-cabinet/assets/css:/offload/rootfs/usr/www/sites/admin-cabinet/assets/css:rw
      - ../project-${feature_name}/sites/admin-cabinet/assets/img:/offload/rootfs/usr/www/sites/admin-cabinet/assets/img:rw
      - ../project-${feature_name}/src/AdminCabinet/Views/Modules:/offload/rootfs/usr/www/src/AdminCabinet/Views/Modules:rw
      - ../Core/src/Core/System/RootFS/etc/nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ../Core/src/Core/System/RootFS/etc/nginx/mikopbx/lua/:/etc/nginx/mikopbx/lua/:ro
      - ../Core/src/Core/System/RootFS/etc/nginx/mikopbx/locations/longpool.conf:/etc/nginx/mikopbx/locations/longpool.conf:ro
    environment:
      - PHP_IDE_CONFIG=serverName=mikopbx-${safe_name}
      - PBX_NAME=PHP8.3-$(echo "${feature_name}" | sed 's/.*/\u&/')
      - PBX_DESCRIPTION=MikoPBX with ${feature_name} feature pass  123456789MikoPBX#1
      - WEB_ADMIN_PASSWORD=123456789MikoPBX#1
      - SSH_PASSWORD=123456789MikoPBX#1
      - SSH_DISABLE_SSH_PASSWORD=0
      - AUTO_UPDATE_EXTERNAL_IP=0
      - SEND_METRICS=0
      - PBX_FIREWALL_ENABLED=1
      - PBX_FAIL2BAN_ENABLED=1
      - SSH_PORT=${ssh_port}
      - WEB_PORT=${http_port}
      - WEB_HTTPS_PORT=${https_port}
      - ID_WWW_USER=501
      - ID_WWW_GROUP=501
      - BROWSERSTACK_USERNAME=bsuser63039
      - BROWSERSTACK_ACCESS_KEY=hqQXx7KMkEj3yMqoHArr
      - BROWSERSTACK_LOCAL=true
      - BROWSERSTACK_LOCAL_IDENTIFIER=local_test_${safe_name}
      - BROWSERSTACK_DAEMON_START=true
      - SERVER_PBX=https://maclic.miko.ru:${https_port}
      - MIKO_LICENSE_KEY=MIKO-GW0DC-QEQQD-WN87S-C88PG
      - SSH_RSA_KEYS_SET=ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDZ3hd6/gqPxMMCqFytFdVznYD3Debp2LKTRiJEaS2SSIRHtE9jMNJjCfMR3CnScjKFh19Hfg/SJf2/rmXIJOHNjZvZZ7GgPTMBYllj3okniCA4/vQQRd6FMVPa9Rhu+N2kyMoQcuDEhzL5kEw0ge5BJJcmNjzW+an3fKqB7QwfMQ== jorikfon@MacBook-Pro-Nikolay.local
      - BUILD_NUMBER=miko-local-vscode-${safe_name}
      - SELENIUM_COOKIE_DIR=C:/Users/hello/Documents
      - CONFIG_FILE=/offload/rootfs/usr/www/tests/AdminCabinet/config/local.conf.json.template
EOF

    # Create start script
    cat > "$start_script" << EOF
#!/bin/bash

# Start MikoPBX ${feature_name} Container
echo "Starting MikoPBX ${feature_name} container..."

# Navigate to dev_docker directory
cd "\$(dirname "\$0")"

# Stop any existing container
docker-compose -f docker-compose-${safe_name}.yml down

# Start the container
docker-compose -f docker-compose-${safe_name}.yml up -d

# Wait for container to start
echo "Waiting for container to start..."
sleep 5

# Show container status
echo "Container status:"
docker ps | grep mikopbx_${safe_name}

echo ""
echo "MikoPBX ${feature_name} is starting up..."
echo "Web interface will be available at:"
echo "  - HTTP:  http://localhost:${http_port}"
echo "  - HTTPS: https://localhost:${https_port}"
echo "  - SSH:   ssh root@localhost -p ${ssh_port}"
echo ""
echo "Default credentials:"
echo "  - Web: admin / 123456789MikoPBX#1"
echo "  - SSH: root / 123456789MikoPBX#1"
echo ""
echo "To view logs: docker logs -f mikopbx_${safe_name}"
echo "To stop: docker-compose -f docker-compose-${safe_name}.yml down"
EOF

    # Create README
    cat > "$readme_file" << EOF
# MikoPBX ${feature_name} Docker Setup

This setup creates a separate Docker container for testing the MikoPBX ${feature_name} feature.

## Ports Configuration

The container uses unique ports to avoid conflicts with other MikoPBX containers:

- **SSH**: ${ssh_port}
- **HTTP**: ${http_port}
- **HTTPS**: ${https_port}

## Directory Mapping

The container mounts source code from \`../project-${feature_name}\` instead of \`../Core\`, allowing you to test the ${feature_name} feature in isolation.

## Quick Start

1. Start the container:
   \`\`\`bash
   ./start-${safe_name}.sh
   \`\`\`

2. Access the web interface:
   - HTTP: http://localhost:${http_port}
   - HTTPS: https://localhost:${https_port}

3. SSH access:
   \`\`\`bash
   ssh root@localhost -p ${ssh_port}
   \`\`\`

## Default Credentials

- Web interface: admin / 123456789MikoPBX#1
- SSH: root / 123456789MikoPBX#1

## Container Management

- **View logs**: \`docker logs -f mikopbx_${safe_name}\`
- **Stop container**: \`docker-compose -f docker-compose-${safe_name}.yml down\`
- **Restart container**: \`docker-compose -f docker-compose-${safe_name}.yml restart\`
- **Access shell**: \`docker exec -it mikopbx_${safe_name} /bin/sh\`

## Data Persistence

Container data is stored in:
- \`./tmp/projects/${safe_name}/cf/\` - Configuration files
- \`./tmp/projects/${safe_name}/storage/\` - Storage data, logs, etc.
EOF

    # Make start script executable
    chmod +x "$start_script"
    
    echo "✓ Docker compose file created: $compose_file"
    echo "✓ Start script created: $start_script"
    echo "✓ README created: $readme_file"
}

function main() {
    # Handle special commands first
    if [ "$1" = "--list" ]; then
        list_registered_ports
        exit 0
    fi

    if [ "$1" = "--clean" ]; then
        clean_ports_registry
        exit 0
    fi

    if [ $# -lt 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_usage
        exit 0
    fi

    local feature_name="$1"
    local base_branch="${2:-$(get_current_branch)}"
    local ports="$3"

    # Validate we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "Error: Not in a git repository. Please run this script from the Core directory."
        exit 1
    fi

    # Check if project already has registered ports
    local existing_ports=$(get_registered_ports "$feature_name")

    # Parse or generate ports
    if [ -n "$ports" ]; then
        IFS=':' read -r ssh_port http_port https_port <<< "$ports"
        if [ -z "$ssh_port" ] || [ -z "$http_port" ] || [ -z "$https_port" ]; then
            echo "Error: Invalid port format. Use SSH:HTTP:HTTPS (e.g., 8028:8086:8449)"
            exit 1
        fi
    elif [ -n "$existing_ports" ]; then
        IFS=':' read -r ssh_port http_port https_port <<< "$existing_ports"
        echo "ℹ️  Found existing ports for project '$feature_name'"
    else
        ports_result=$(get_next_available_ports)
        IFS=':' read -r ssh_port http_port https_port <<< "$ports_result"
    fi

    echo "Setting up feature development environment"
    echo "Feature name: $feature_name"
    echo "Base branch: $base_branch"
    echo "Ports: SSH=$ssh_port, HTTP=$http_port, HTTPS=$https_port"
    echo ""

    # Create feature branch
    create_feature_branch "$feature_name" "$base_branch"

    # Switch back to base branch to create worktree
    git checkout "$base_branch"

    # Create worktree
    create_worktree "$feature_name"

    # Create Docker infrastructure
    create_docker_infrastructure "$feature_name" "$ssh_port" "$http_port" "$https_port"

    echo ""
    echo "✅ Setup complete!"
    echo ""
    echo "Your feature branch '$feature_name' has been created with:"
    echo "  - Git worktree at: ../project-$feature_name"
    echo "  - Docker setup in: ../dev_docker/"
    echo "  - Ports registry: $PORTS_REGISTRY"
    echo ""
    echo "Configuration files created:"
    echo "  - ../project-$feature_name/tests/api/.env (Python tests config)"
    echo "  - ../project-$feature_name/tests/api/.env.example (template)"
    echo "  - ../project-$feature_name/CLAUDE.local.md (development guide)"
    echo ""
    echo "Useful commands:"
    echo "  $0 --list   # List all projects and their ports"
    echo "  $0 --clean  # Clean up obsolete project entries"
    echo ""
    echo "Next steps:"
    echo "1. cd ../project-$feature_name  # Switch to your feature worktree"
    echo "2. ../dev_docker/start-$(echo "$feature_name" | sed 's/[^a-zA-Z0-9]/-/g').sh  # Start Docker container"
    echo "3. Access web interface: http://localhost:$http_port"
    echo "4. Run Python tests: cd tests/api && pytest"
    echo ""
    echo "For more details:"
    echo "  - Docker setup: ../dev_docker/README-$(echo "$feature_name" | sed 's/[^a-zA-Z0-9]/-/g').md"
    echo "  - Development guide: ../project-$feature_name/CLAUDE.local.md"
    echo "  - Test configuration: ../project-$feature_name/tests/api/README_CONFIG_REFACTORING.md"
}

# Run main function
main "$@"