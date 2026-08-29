This folder contains helper files to update the `notesy-app` Django settings to read security-related host lists from environment variables.

Usage:

1. From your `notesy-app` repository root, run:

   bash /path/to/notesy-infrastructure/patches/apply_notesy_settings_patch.sh

2. Inspect the changes and run tests. Commit and push the change and open a PR.

Files:
- `notesy-settings.patch` — a unified patch that replaces relevant parts of `notesy/settings.py` to read `CSRF_TRUSTED_ORIGINS` and `DJANGO_ALLOWED_HOSTS` from environment variables.
- `apply_notesy_settings_patch.sh` — helper script to apply the patch (requires `git` and `patch`).
