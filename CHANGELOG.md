# Changelog

## 0.20260426.0

- Drop `SINGULARITY_BINDPATH=/opt/hf-cache:/opt/hf-cache`. It conflicted with
  muxi-server's explicit `--bind /opt/hf-cache` and produced a noisy
  "destination is already in the mount point list" warning on every formation
  spawn. Bind ownership now lives entirely in the caller (muxi-server), which
  is the correct pattern -- explicit binds beat hidden environment magic and
  keep the diagnostic surface clean. The `/opt/hf-cache` stub directory in
  this image is preserved so callers that don't pass `--bind` still have a
  valid mount target.

## 0.20260422.0

- Forward `/opt/hf-cache` into SIF executions via `SINGULARITY_BINDPATH=/opt/hf-cache:/opt/hf-cache`.
- Create `/opt/hf-cache` in the runtime-runner image so the outer Docker bind mount always has a valid target.
