Supprimer le swap du fichier /etc/fstab pour que ce soit permanent :
Édite /etc/fstab :

sudo nano /etc/fstab


Commente la ligne contenant /swap.img en ajoutant # au début.

Redémarrer kubelet :

sudo systemctl restart kubelet
sudo systemctl status kubelet








--------
olution

Charger le module br_netfilter :

sudo modprobe br_netfilter


Vérifier qu’il est actif :

lsmod | grep br_netfilter


S’assurer que le paramètre sysctl est activé :

sudo sysctl net.bridge.bridge-nf-call-iptables=1


Pour le rendre persistant après reboot, ajouter dans /etc/sysctl.conf ou /etc/sysctl.d/99-kubernetes.conf :

net.bridge.bridge-nf-call-iptables = 1


Puis appliquer :

sudo sysctl --system


Redémarrer le DaemonSet Flannel :

kubectl delete pod -n kube-flannel -l app=flannel


Après ça, kube-flannel devrait démarrer correctement, et tes pods (CoreDNS, XWiki, etc.) pourront obtenir des IP et démarrer.

Si tu veux, je peux te donner la commande unique pour corriger tout ça et relancer Flannel sur ton cluster. Veux‑tu que je fasse ça ?

Vous avez dit :
$ sudo modprobe br_netfilter
vagrant@vagrant:~/nudger/k8s-apps/xwiki/xwiki$ lsmod | grep br_netfilter
br_netfilter           32768  0
bridge                311296  1 br_netfilter
vagrant@vagrant:~/nudger/k8s-apps/xwiki/xwiki$
ChatGPT a dit :

Parfait ! Le module br_netfilter est maintenant chargé. ✅

Il reste à activer le paramètre sysctl pour que Flannel puisse utiliser le bridge correctement :

sudo sysctl net.bridge.bridge-nf-call-iptables=1


Pour que ce paramètre soit persistant après reboot :

echo "net.bridge.bridge-nf-call-iptables = 1" | sudo tee /etc/sysctl.d/99-kubernetes.conf
sudo sysctl --system


Ensuite, redémarre les pods Flannel pour appliquer le changement :

kubectl delete pod -n kube-flannel -l app=flannel


Après ça, les pods Flannel devraient passer en Running et ton réseau de pods fonctionner.


