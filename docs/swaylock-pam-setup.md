# Swaylock PAM Setup for Non-NixOS Systems

On non-NixOS systems (like Ubuntu), swaylock requires PAM (Pluggable Authentication Modules) to be configured to verify your password.

## Quick Check

Test if swaylock works:
```bash
swaylock
# Try to unlock with your password
```

If you get "pam_authenticate failed" or cannot unlock, follow the setup below.

## Ubuntu/Debian Setup

1. Create the PAM configuration file for swaylock:
```bash
sudo nano /etc/pam.d/swaylock
```

2. Add the following content:
```
# PAM configuration for swaylock
auth include login
```

3. Save and exit (Ctrl+X, Y, Enter)

4. Test swaylock again:
```bash
swaylock
```

## Alternative: Use system auth

If the above doesn't work, try this configuration instead:
```bash
sudo nano /etc/pam.d/swaylock
```

```
# PAM configuration for swaylock
auth sufficient pam_unix.so try_first_pass nullok
auth required pam_deny.so
```

## Troubleshooting

If swaylock still doesn't work:

1. Check if you're in the required groups:
```bash
groups
# You should see: video, input
```

2. Add yourself to the groups if needed:
```bash
sudo usermod -a -G video,input $USER
# Log out and back in
```

3. Check swaylock permissions:
```bash
ls -la $(which swaylock)
```

4. If using the Nix-installed swaylock, ensure it has the right permissions:
```bash
# The Nix store path will be read-only, which is expected
# PAM should still work if configured correctly
```

## Current Configuration

Your swayidle is configured to:
- Lock screen after 5 minutes of inactivity
- Turn off displays after 10 minutes
- Lock before system sleep/suspend
- Lock on explicit lock command (Mod+Ctrl+Q or Mod+Shift+Q)

## Manual Lock

You can manually lock your screen with:
- `Mod+Ctrl+Q` or `Mod+Shift+Q` (configured in sway)
- Run `swaylock` in terminal
- `loginctl lock-session` (works with swayidle)
