## paso: identified that net-auditor container could not see host connections
ran `ss -tulnp` on the host and compared with `docker logs net-auditor` —
host showed nginx:80 and sshd:22, container showed nothing.

## trampa: `docker run` command order matters — image always goes last,
command goes after the image. also `-l` flag missing from `ss` inside
container — without it you only see ESTABLISHED connections, not LISTEN.

## comando clave: 
docker rm -f net-auditor
docker run -dit --network=host --name net-auditor alpine \
  sh -c "apk add --no-cache iproute2 > /dev/null 2>&1; \
  while true; do echo '=== $(date) ==='; ss -tnp; sleep 5; done"

## decisión: bridge vs host network mode
docker uses bridge by default — each container gets its own isolated
network namespace (same mechanism as `ip netns` in F1). the container
cannot see host sockets because it lives in a separate namespace.
--network=host removes that isolation: the container shares the host
network namespace instead of having its own isolated one.
use host mode only for monitoring/auditing tools that need full visibility
of the host network stack. never for regular apps in production — it
removes the network isolation that protects the host.