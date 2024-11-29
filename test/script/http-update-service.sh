REPO=release

cat <<EOF
---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: ${REPO}-route
  namespace: openshift-update-service
spec:
  tls:
    insecureEdgeTerminationPolicy: Allow
EOF
