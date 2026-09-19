# Devops-test

## Resource Choices

Requested 50m CPU and 64Mi memory for the service — it's a tiny Flask app doing basically nothing CPU-intensive, so this is close to the floor. Limited to 200m CPU and 128Mi memory, giving 4x headroom over the request for occasional spikes without letting one pod hog a node.

## What I Deliberately Skipped

- **Persistent storage** — the service is stateless, no need for it.
- **Autoscaling (HPA)** — fixed 2 replicas is fine for a demo; in production I'd add this based on CPU/request rate.
- **Secrets management** — APP_NAME/VERSION are non-sensitive and go through a ConfigMap; nothing here warranted a Secret.
- **Network policies** — out of scope for the time given; in production I'd restrict pod-to-pod traffic to only what's needed.
- **TLS on the Ingress** — no cert-manager setup; demo.local is plain HTTP for local testing.

## What I'd Add for Production

- Sealed-secrets or external-secrets for anything sensitive
- Horizontal Pod Autoscaler
- Prometheus + Grafana for metrics and alerting
- Network policies restricting traffic to only what's needed
- Multi-region deployment with health-check based routing
- Distributed tracing (e.g. OpenTelemetry) across services

## Part 4: Debug Lab Summary

Found and fixed 5 of 6 defects in the broken chart:

1. **Job had `restartPolicy: Always`** — invalid for Kubernetes Jobs, blocked the entire helm release. Fixed to `OnFailure`.
2. **Missing `runAsUser` alongside `runAsNonRoot`** — the prebuilt image uses a named non-root user (`nonroot`), which Kubernetes can't verify without an explicit numeric UID. Added `runAsUser: 65532` (the image's actual UID, confirmed via `docker inspect`) across backend, gateway, reporter, and the migrate Job.
3. **App defaulting to the wrong port** — the app listens on 8081 unless a `PORT` env var is set, but the chart's probes and Service all expected 8080. Added the missing `PORT` env var.
4. **Gateway pointed at backend in the wrong namespace** — `BACKEND_URL` referenced `backend.default.svc` instead of `backend.debug-lab.svc`, causing DNS resolution failures.
5. **RoleBinding bound to the wrong ServiceAccount** — the reporter Role was correctly scoped, but the RoleBinding's subject pointed at `default` instead of `reporter`, so the actual pod's identity had no permissions.

The 6th defect (reporter pod still failing to parse the Kubernetes API's pod-list response, even after RBAC was confirmed correct via `kubectl auth can-i`) I wasn't able to fully isolate in the time available. Full details on what I ruled out and what I'd try next are in `lab/FINDINGS.md`.

## How I Used AI

Used Claude throughout this take-home, especially for Part 4 — walking through kubectl/helm error output, ruling out causes, and figuring out next diagnostic steps. This was a genuine back-and-forth troubleshooting session over many iterations (stale ReplicaSets, an immutable Job spec, a few YAML indentation mistakes along the way), not a single generated answer. I ran every command myself and made all the actual fixes to the chart.
