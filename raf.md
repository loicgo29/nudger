Supprimer le swap du fichier /etc/fstab pour que ce soit permanent :
Édite /etc/fstab :

sudo nano /etc/fstab


Commente la ligne contenant /swap.img en ajoutant # au début.

Redémarrer kubelet :

sudo systemctl restart kubelet
sudo systemctl status kubelet
