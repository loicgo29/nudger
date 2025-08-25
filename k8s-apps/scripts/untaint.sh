kubectl taint nodes master1 node-role.kubernetes.io/control-plane:NoSchedule-
kubectl config set-context --current --namespace=nudger-xwiki
