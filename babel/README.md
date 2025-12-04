# Babel JS Compiler for MikoPBX

Transpiles ES6+ JavaScript to ES5 for browser compatibility in MikoPBX projects.

## Quick Start with Docker (Recommended)

Use the pre-built container from GitHub Container Registry:

```bash
docker pull ghcr.io/mikopbx/babel-compiler:latest
```

### Compile a single file

```bash
docker run --rm -v "/path/to/project:/project" ghcr.io/mikopbx/babel-compiler:latest "/project/path/to/file.js"
```

### Example for MikoPBX Core

```bash
docker run --rm -v "/Users/nb/PhpstormProjects/mikopbx/Core:/project" \
  ghcr.io/mikopbx/babel-compiler:latest \
  "/project/sites/admin-cabinet/assets/js/src/main/form.js"
```

### Example for MikoPBX Extensions

```bash
docker run --rm -v "/Users/nb/PhpstormProjects/mikopbx/Extensions:/project" \
  ghcr.io/mikopbx/babel-compiler:latest \
  "/project/ModuleExample/public/assets/js/src/module-example-index.js"
```

## File Path Conventions

The compiler automatically determines output paths based on input:

| Input Pattern | Output Directory |
|--------------|------------------|
| `Core/sites/admin-cabinet/assets/js/src/**/*.js` | `js/pbx/` (same subfolder structure) |
| `Extensions/.../public/assets/js/src/*.js` | Parent `js/` directory |
| `*/sites/admin-cabinet/assets/js/src/**/*.js` | `js/pbx/` (same subfolder structure) |

## Configuration

### Babel Config (`babel.config.json`)

```json
{
  "presets": [["airbnb", {
    "targets": {
      "chrome": 50,
      "ie": 11,
      "firefox": 45
    }
  }]]
}
```

### Target Browsers
- Chrome 50+
- Internet Explorer 11
- Firefox 45+

## Local Development

If you need to build the container locally:

```bash
cd babel
docker build -t mikopbx-babel-compiler .
```

### Run locally built container

```bash
docker run --rm -v "/path/to/project:/project" mikopbx-babel-compiler "/project/path/to/file.js"
```

## Using with Node.js directly

If you prefer not to use Docker:

```bash
cd babel
npm install
node babel-compile.js /path/to/file.js
```

Or use Babel CLI directly:

```bash
./node_modules/.bin/babel "$INPUT_FILE" --out-dir "$OUTPUT_DIR" --source-maps inline --presets airbnb
```

## Integration with IDEs

### PhpStorm / WebStorm File Watcher

1. Go to **Settings > Tools > File Watchers**
2. Add new watcher with:
   - **Program**: `docker`
   - **Arguments**: `run --rm -v "$ProjectFileDir$:/project" ghcr.io/mikopbx/babel-compiler:latest "/project/$FilePath$"`
   - **Working directory**: `$ProjectFileDir$`
   - **Output paths**: Leave empty (auto-detected)

### VS Code Task

Add to `.vscode/tasks.json`:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Babel Compile",
      "type": "shell",
      "command": "docker run --rm -v \"${workspaceFolder}:/project\" ghcr.io/mikopbx/babel-compiler:latest \"/project/${relativeFile}\""
    }
  ]
}
```

## Files

| File | Description |
|------|-------------|
| `Dockerfile` | Docker image definition |
| `docker-entrypoint.sh` | Container entry point script |
| `babel-compile.js` | Node.js compilation script |
| `babel.config.json` | Babel configuration |
| `package.json` | Node.js dependencies |
