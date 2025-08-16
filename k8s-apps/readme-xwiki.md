kubectl taint nodes --all node-role.kubernetes.io/control-plane-
kubectl apply -f namespace.yaml
kubectl apply -f xwiki/mysql/
kubectl apply -f xwiki/xwiki/
kubectl apply -f xwiki/ingress/ 
sudo mkdir /data/mysql-pv
sudo chmod 777 /data/mysql-pv/
sudo mkdir /data/xwiki
chmod 777 /data/xwiki/
