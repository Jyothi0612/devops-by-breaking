# shellcheck shell=bash
docker exec -i "$(k8s_name)" kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-all-egress
  namespace: payments
spec:
  podSelector: {}
  policyTypes: [Egress, Ingress]
  egress: [{}]
  ingress: [{}]
EOF
