REPO=release

cat <<EOF
---
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: cv-upstream-$REPO
  namespace: policies
spec:
  disabled: false
  remediationAction: enforce
  policy-templates:
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: cv-upstream-$REPO
      spec:
        object-templates:
        - complianceType: musthave
          objectDefinition:
            apiVersion: config.openshift.io/v1
            kind: ClusterVersion
            metadata:
              name: version
            spec:
              upstream: '{{hub fromConfigMap "policies" "osus-$REPO" "graphUrl" hub}}'
            status:
              conditions:
              - status: 'True'
                type: RetrievedUpdates
---
apiVersion: policy.open-cluster-management.io/v1
kind: PlacementBinding
metadata:
  name: clusters-$REPO
  namespace: policies
placementRef:
  name: clusters-placement-$REPO
  kind: Placement
  apiGroup: cluster.open-cluster-management.io
subjects:
- name: cv-upstream-$REPO
  kind: Policy
  apiGroup: policy.open-cluster-management.io
---
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: Placement
metadata:
  name: clusters-placement-$REPO
  namespace: policies
spec:
  predicates:
  - requiredClusterSelector:
      labelSelector:
        matchExpressions:
        - {key: vendor, operator: In, values: ["OpenShift"]}
        - {key: "policies.undeploy", operator: DoesNotExist}
        - {key: "policies.release-repo", operator: In, values: ["$REPO"]}
EOF
