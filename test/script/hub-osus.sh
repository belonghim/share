REGISTRY=labhost.jooan.local:8443
REPO=ocp4

cat <<EOF
---
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: osus-$REPO
  namespace: policies
spec:
  disabled: false
  remediationAction: enforce
  policy-templates:
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: osus-$REPO
      spec:
        object-templates:
        - complianceType: musthave
          objectDefinition:
            apiVersion: updateservice.operator.openshift.io/v1
            kind: UpdateService
            metadata:
              name: $REPO
              namespace: openshift-update-service
            spec:
              replicas: 2
              releases: $REGISTRY/$REPO/openshift/release-images
              graphDataImage: $REGISTRY/$REPO/openshift/graph-image:latest
            status:
              conditions:
              - status: "True"
                type: ReconcileCompleted
        - complianceType: musthave
          objectDefinition:
            apiVersion: v1
            kind: ConfigMap
            metadata:
              name: osus-$REPO
              namespace: policies
            data:
              graphUrl: '{{ ( (cat (lookup "updateservice.operator.openshift.io/v1" "UpdateService" "openshift-update-service" "$REPO").status.policyEngineURI "/api/upgrades_info/v1/graph") | replace " " "") }}'
        - complianceType: musthave
          objectDefinition:
            apiVersion: apps/v1
            kind: Deployment
            metadata:
              name: $REPO
              namespace: openshift-update-service
            status:
              availableReplicas: 2
              conditions:
              - status: "True"
                type: Available
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: digest-$REPO
      spec:
        evaluationInterval:
          comliant: 5m
          noncomliant: 5m
        object-templates:
        - complianceType: mustnothave
          objectDefinition:
            apiVersion: v1
            kind: Pod
            metadata:
              namespace: openshift-update-service
            status:
              phase: Failed
---
apiVersion: policy.open-cluster-management.io/v1
kind: PlacementBinding
metadata:
  name: osus-$REPO
  namespace: policies
placementRef:
  name: placement-opp-hub
  kind: Placement
  apiGroup: cluster.open-cluster-management.io
subjects:
- name: osus-$REPO
  kind: Policy
  apiGroup: policy.open-cluster-management.io
EOF
