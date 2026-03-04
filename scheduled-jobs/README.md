# Scheduled Jobs: Log Rotation

## Scenario

A log rotation script (`/usr/local/bin/rotate_logs.sh`) must run every day at **02:00 AM** to prevent the `/var/log/app/` partition from filling up.

Your job: Implement this using both legacy **Cron** and modern **Systemd Timers**, ensuring the job is reliable even if the server is temporarily powered off.

## Controls Applied

| Feature | Tool | Why |
|---|---|---|
| **Schedule** | `0 2 * * *` / `OnCalendar` | Standard window for maintenance tasks |
| **Persistence** | `Persistent=true` | Ensures the job runs after a reboot if the window was missed |
| **Environment** | Absolute Paths | Avoids the common "command not found" PATH trap in automation |
| **Verification** | `journalctl` | Centralized logging for troubleshooting execution failures |

## The PATH Trap

Both Cron and Systemd run with a very restricted `PATH`. 
* **Cron:** Usually defaults to `/usr/bin:/bin`. 
* **Systemd:** Does not load shell profiles (`.bashrc`, etc.).

**Best Practice:** Always use absolute paths for executables (e.g., `/usr/bin/tar` instead of `tar`) within your scripts or unit files.

## Implementation: Cron

1. Edit the crontab: `crontab -e`
2. Add the entry: `0 2 * * * /usr/local/bin/rotate_logs.sh`
3. Verify the daemon is running: `systemctl status crond`
4. Check logs: `journalctl -u crond` (Note: Cron provides limited detail on script internal failures).

## Implementation: Systemd Timers

**This is the preferred modern method.** It requires two files in `/etc/systemd/system/`:

1. **`.service` file:** Defines *what* to run (the script).
2. **`.timer` file:** Defines *when* to run (the trigger).

### The `Persistent=true` Directive
Unlike Cron, which simply skips a job if the system is down at 2 AM, `Persistent=true` tells Systemd to check when the service last ran. If the scheduled time was missed during downtime, Systemd triggers it immediately upon boot.

## Cron vs. Systemd Timers

| Feature | Cron | Systemd Timers |
| :--- | :--- | :--- |
| **Logging** | Sent to mail/syslog (messy) | Integrated in `journald` (clean) |
| **Reliability** | Misses jobs if powered off | `Persistent` catches up missed runs |
| **Dependencies** | Runs blindly | Can wait for network/mounts to be ready |
| **Debugging** | Hard to test manually | `systemctl start [service]` to test anytime |

## Files

* `log-rotate.service` — Unit definition for the rotation task.
* `log-rotate.timer` — Schedule definition with persistence enabled.


# 1. Load new files
systemctl daemon-reload

# 2. Enable and start timer
systemctl enable --now log-rotate.timer

# 3. List active timers
systemctl list-timers --all

# 4. Test the script
systemctl start log-rotate.service