if [ "$REGISTRY" = "" ];then REGISTRY=$1;fi
if [ "$REPO" = "" ];then REPO=$2;fi
if [ "$REGISTRY" = "" -o "$REPO" = "" ];then echo "Example: osus.sh <registry> <repo>";exit 1;fi

cat <<EOF
---
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: upgrade-osus-$REPO
  namespace: policies
spec:
  remediationAction: enforce
  disabled: false
  policy-templates:
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: upgrade-osus-$REPO
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
              graphDataImage: $REGISTRY/$REPO/openshift/graph-data:latest
            status:
              conditions:
              - status: "True"
                type: ReconcileCompleted
        - complianceType: musthave
          objectDefinition:
            apiVersion: v1
            kind: ConfigMap
            metadata:
              name: upgrade-osus-$REPO
              namespace: policies
            data:
              graphUrl: '{{ ( (cat (lookup "updateservice.operator.openshift.io/v1" "UpdateService" "openshift-update-service" "$REPO").status.policyEngineURI "/api/upgrades_info/v1/graph") | replace " " "") }}'
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: upgrade-osus-digest
      spec:
        evaluationInterval:
          comliant: 10m
          noncomliant: 10m
        object-templates-raw: |
          {{ \$dg := lookup "v1" "Pod" "openshift-update-service" "graph-data-tag-digest" }}
          {{ if or (eq "Failed" \$dg.status.phase) (eq "Pending" \$dg.status.phase) }}
          - complianceType: mustnothave
            objectDefinition:
              apiVersion: v1
              kind: Pod
              metadata:
                name: graph-data-tag-digest
                namespace: openshift-update-service
          {{ end }}
---
apiVersion: policy.open-cluster-management.io/v1
kind: PlacementBinding
metadata:
  name: upgrade-osus-$REPO
  namespace: policies
placementRef:
  name: placement-hub
  kind: Placement
  apiGroup: cluster.open-cluster-management.io
subjects:
- name: upgrade-osus-$REPO
  kind: Policy
  apiGroup: policy.open-cluster-management.io
EOF
