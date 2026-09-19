# Q1: Migrating 40 Ingress objects to Gateway API with no downtime

## Approach

Start by auditing all 40 Ingress objects to catalogue what's actually in use — TLS setup, custom annotations (rate-limiting, auth, rewrites), and which ones are high-traffic versus low-risk. Not all 40 need the same care.

Install a Gateway API controller (e.g. Envoy Gateway or Cilium) alongside the existing ingress-nginx, rather than replacing it outright. Both controllers can run at the same time pointing at the same backend services, since Gateway API and Ingress are separate resource types that don't conflict.

Migrate in batches, starting with the lowest-risk routes:

1. Convert 3-5 simple Ingress objects (no custom annotations, low traffic) to HTTPRoute + Gateway resources first. Test directly against the new controller's IP/port before touching DNS.
2. Once confirmed working, gradually shift a percentage of real traffic over (weighted DNS or a load balancer split) rather than an all-or-nothing cutover.
3. Repeat in batches of 5-10, moving from low-risk to high-risk (auth-protected, high-traffic) as confidence builds.
4. Once all 40 are running cleanly on Gateway API and monitored for a full traffic cycle (at least one full day, ideally a week), decommission the old ingress-nginx controller and remove the old Ingress objects.

Keep both controllers live throughout, so any batch can be rolled back instantly by just pointing traffic back at the old Ingress — no redeploying anything.

## What's likely to break

- **TLS**: if cert-manager is issuing certs via Ingress annotations, it needs a Gateway API-compatible Certificate/ClusterIssuer setup — this is usually the first thing to test.
- **Custom nginx annotations**: rate-limiting, custom rewrites, and auth snippets in ingress-nginx are nginx-specific and don't have a 1:1 Gateway API equivalent. These need to be redone in the new controller's API (or a policy CRD, depending on the controller chosen).
- **DNS/LB IP changes**: if the Gateway controller gets a different external IP than ingress-nginx, DNS TTLs need to be short during the transition to avoid stale routing.
- **Path-matching differences**: Ingress path types (`Prefix`, `Exact`) and Gateway API `HTTPRouteMatch` don't always map perfectly — needs manual verification per-route, not just an automatic conversion.
- **Webhook/admission timing**: briefly, in-flight requests during a batch cutover can 5xx if the old and new resource don't overlap cleanly for a few seconds. This is minimized by running both controllers in parallel rather than a hard cutover.

## Mitigation

- Never touch DNS or DNS-facing config until the Gateway API route is proven working via direct IP/port testing.
- Roll out oldest and least critical services first, save auth-protected and high-traffic services for last.
- Keep the rollback trivial: don't delete anything from ingress-nginx until Gateway API has run successfully in production for a full traffic cycle.
- Monitor error rates and latency per-route during each batch, not just in aggregate — a spike in one route is easy to miss if you're only watching total traffic.
