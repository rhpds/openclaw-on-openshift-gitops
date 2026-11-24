# OpenClaw on OpenShift — GitOps (tenant model)

Two Argo app-of-apps for the **tenant** strategy: one shared cluster,
one namespace per order.

| chart | deployed by | what it owns |
| --- | --- | --- |
| `cluster/` | `agd_v2/claws-on-openshift-cluster` | the shared platform — RHOAI, ODF/MCG, MaaS-over-MaaS, the claw operator, observability, the MLflow trace collector, the MCP catalog, the session broker |
| `tenant/` | `agd_v2/claws-on-openshift-tenant` | ONE seat — the Claw, its MCP servers, its MaaS key, its audience Route and in-pod setup |

`components/` is shared by both and sits at the repo root, which is why
Applications reference `components/<name>` and not a path under
`cluster/` or `tenant/`.

## This is not the only way the demo is deployed

The **all-in-one cluster** variant — one cluster, N seats, ordered as
Field Sourced Content — lives in the demo repo
(`blues-man/fantaco-redhat-summit-2026`, `clawoperator-openclaw/gitops`)
and is deliberately NOT mirrored here. The two differ in more than
packaging: there, seats are a fleet created by an ApplicationSet and the
platform knows how many there are; here, tenants arrive one order at a
time and the cluster chart knows nothing about them.

Consequences worth knowing before copying anything between them:

- **Per-namespace resources belong to the tenant.** The seat RoleBinding
  and the collector egress NetworkPolicy are rendered by the seat chart,
  not looped over a seat count by the platform.
- **Cluster-scoped names carry the tenant namespace.** One Application
  per tenant means a fixed ClusterRoleBinding name would have each
  tenant replace the previous one's subject and silently strip its
  permissions.
- **The namespace and quota are not ours.** `ocp4_workload_tenant_namespace`
  creates both; the seat chart adopts the namespace to label it
  (`Prune=false`) and leaves the quota alone.

## Vendored content

`claw_skills/`, `workspace-templates/`, `helm/` and `broker-pg/` are
copied from the demo repo so this repo is self-contained — the skills
injection hook fetches them from *this* repo at the Application's own
revision. They have to be re-synced by hand when the demo repo changes.
