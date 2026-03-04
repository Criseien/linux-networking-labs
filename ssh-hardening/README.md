# SSH Hardening

## Scenario

A security auditor flags your bastion host (`10.0.1.5`):

- Root login is allowed over SSH
- Password authentication is enabled
- No user restriction — any system user can attempt access

Your job: harden sshd without locking yourself out.

## Controls Applied

| Directive | Value | Why |
|---|---|---|
| `PermitRootLogin` | `no` | Root should never be directly accessible remotely |
| `PasswordAuthentication` | `no` | Passwords are brute-forceable; keys are not |
| `AllowUsers` | specific users | Limits attack surface to legitimate users only |
| `PermitEmptyPasswords` | `no` | Defense in depth |
| `MaxAuthTries` | `3` | Limits brute-force attempts per connection |
| `ClientAliveInterval` | `300` | Drops idle sessions |

## Order of Application

**This order matters. Skipping steps can lock you out.**

1. Generate SSH key pair on your local machine
2. Copy public key to the server (`ssh-copy-id` or manual)
3. Open a second terminal and **validate key-based login works**
4. Edit `/etc/ssh/sshd_config` with the controls above
5. Run `sshd -T` to verify effective configuration (catches syntax errors)
6. Run `systemctl reload sshd` — not restart
7. Open a third terminal and validate the new config works
8. Close your original session

## The Trap: `reload` vs `restart`

`systemctl restart sshd` kills the sshd process entirely. Any active SSH sessions — including your current one — are terminated. If the new config has an issue, you lose your rescue session.

`systemctl reload sshd` sends SIGHUP to the process. sshd reloads configuration without killing active sessions. Always use `reload` when hardening a live server.

## Verify Effective Config

```bash
sshd -T | grep -E 'permitrootlogin|passwordauthentication|allowusers'
```

## Files

- `sshd_config.example` — hardened sshd_config with inline comments