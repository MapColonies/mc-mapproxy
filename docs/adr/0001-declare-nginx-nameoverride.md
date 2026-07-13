---
status: accepted
---

# Declare `nginx.nameOverride: nginx-mapproxy` on the nginx subchart

## Context

The common nginx chart `2.2.1` changed how the nginx workload is identified: the
Deployment/Service `app` label, `spec.selector.matchLabels.app`, container name,
and subchart resource names now derive from `nameOverride | default "nginx"`
instead of the release-derived full name used in `2.1.5`. Left at the default, our
nginx renders the generic `app: nginx`, which is not specific to this service and
would collide with any other nginx release sharing a namespace.

## Decision

Declare `nginx.nameOverride: nginx-mapproxy` explicitly in `helm/values.yaml`. The
workload renders `app: nginx-mapproxy` and resource names `<release>-nginx-mapproxy-*`.
We declare it (rather than relying on a default) so the workload identity is obvious
from the values file and does not silently shift if the chart's default changes again.

## Considered Options

- **Accept the chart default (`app: nginx`)** — generic and namespace-collision-prone.
- **Pin `nameOverride` to reproduce the old `<release>-nginx` value** — release-name
  dependent and fragile; only serves to dodge the selector change.

## Consequences

The rendered `spec.selector` differs from what a `2.1.5`-based release has live, and a
Deployment's selector is immutable. Upgrading a **live** environment therefore requires
deleting the existing nginx Deployment so it is recreated (an `immutable field` error
otherwise). This is called out for whoever deploys later — **this change performs no
deployment to any environment.**
