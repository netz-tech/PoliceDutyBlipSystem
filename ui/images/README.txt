Place shared UI art here. Files referenced by default:
  header-badge.png   -> top circle icon.
  off-duty.png       -> "Go Off Duty" option icon.
  departments/default.png -> fallback for any department without its own icon.

To add department-specific icons:
  1. Save a 128x128 PNG (or similar) into `ui/images/departments/` named after the department key (e.g. `USMS.png`).
  2. Update `iconMap` inside `ui/script.js` to point to that filename if it differs from the default pattern.
