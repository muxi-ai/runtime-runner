# Changelog

## 0.20260422.0

- Forward `/opt/hf-cache` into SIF executions via `SINGULARITY_BINDPATH=/opt/hf-cache:/opt/hf-cache`.
- Create `/opt/hf-cache` in the runtime-runner image so the outer Docker bind mount always has a valid target.
