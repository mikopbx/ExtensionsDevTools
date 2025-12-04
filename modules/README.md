# MikoPBX Module Creation Tools

Scripts for creating new MikoPBX modules from the official template.

## Overview

These tools automate the creation of new MikoPBX modules by cloning the [ModuleTemplate](https://github.com/mikopbx/ModuleTemplate) repository and customizing it with your module name.

## Available Scripts

| Script | Language | Description |
|--------|----------|-------------|
| `create_module.sh` | Shell | Main module creation script (recommended) |
| `mod_replace.py` | Python | Alternative implementation with GitPython |
| `mod_replace.sh` | Shell | Legacy replacement script |

## Quick Start

### Using Shell Script (Recommended)

```bash
# Navigate to your working directory
cd /path/to/your/modules

# Create a new module
./create_module.sh 'ModuleMyNewFeature'
```

### Using Python Script

```bash
# Requires GitPython: pip install GitPython
python mod_replace.py 'ModuleMyNewFeature'
```

## Naming Convention

**Important**: Module names MUST start with `Module` prefix.

```bash
# Correct
./create_module.sh 'ModuleCallRecording'
./create_module.sh 'ModuleUserManagement'

# Will be auto-corrected to include prefix
./create_module.sh 'CallRecording'  # Becomes ModuleCallRecording
```

## What Gets Created

The script creates a complete module structure:

```
ModuleMyNewFeature/
├── app/
│   ├── controller/
│   ├── form/
│   ├── model/
│   └── view/
├── bin/
├── db/
├── Lib/
│   ├── MyNewFeatureConf.php
│   ├── MyNewFeatureMain.php
│   ├── WorkerMyNewFeatureAMI.php
│   └── WorkerMyNewFeatureMain.php
├── Messages/
├── Models/
├── public/
│   └── assets/
│       ├── css/
│       ├── img/
│       └── js/
│           └── src/
├── Setup/
└── module.json
```

## Name Transformations

The scripts automatically convert your module name to various formats:

| Format | Example |
|--------|---------|
| CamelCase | `ModuleMyNewFeature` |
| dash-style | `module-my-new-feature` |
| underline_style | `module_my_new_feature` |
| Short prefix | `mod_my_new_feature_` |

## Requirements

### For Shell Scripts

- Git
- Standard Unix utilities: echo, sed, tr, xargs, find, dirname, rm, mkdir

### For Python Script

- Python 3.x
- GitPython library: `pip install GitPython`

## Manual Alternative

If Git is not available, you can manually:

1. Download [ModuleTemplate](https://github.com/mikopbx/ModuleTemplate/archive/refs/heads/develop.zip)
2. Extract to your working directory
3. Rename files and replace text manually

## Examples

### Create a Call Recording Module

```bash
./create_module.sh 'ModuleCallRecording'
```

Creates:
- `ModuleCallRecording/`
- `Lib/CallRecordingConf.php`
- `Lib/CallRecordingMain.php`
- CSS/JS files with `module-call-recording` naming

### Create a User Management Module

```bash
./create_module.sh 'ModuleUserManagement'
```

Creates:
- `ModuleUserManagement/`
- `Lib/UserManagementConf.php`
- `Lib/UserManagementMain.php`
- Database prefix: `mod_user_management_`

## After Creation

1. Navigate to your new module directory
2. Edit `module.json` with your module details
3. Implement your business logic
4. Test with MikoPBX development environment

See [MikoPBX Module Development Guide](https://docs.mikopbx.com/modules/) for detailed documentation.
