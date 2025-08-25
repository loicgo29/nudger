mysql:8.0.43 → x86-64-v2 → crash immédiat sur M1 (Fatal glibc error)
mysql:5.7 → ARM64 → instable / pas compatible avec XWiki moderne

il n’existe pas de image MySQL officielle pleinement stable pour ARM64 qui fonctionne parfaitement avec XWiki sur M1.

Solutions viables
Passer à MariaDB multi-arch
	mariadb:10.11 ou mariadb:10.9 sont multi-arch et ARM64 native.
	XWiki supporte MariaDB comme backend MySQL.
	Stable sur M1 et performant.
Utiliser un service MySQL externe sur x86 (sur un autre host ou cloud)
	Ton pod XWiki ARM64 se connecte à un MySQL x86 distant.
	Stable mais plus complexe à gérer localement.
Forcer émulation x86 (--platform=linux/amd64)
	Fonctionne mais lente et fragile sous Kubernetes sur M1, à éviter pour un déploiement réaliste.
Donc, la solution la plus robuste pour ton environnement local M1/K8s est passer à MariaDB ARM64.
-----------
kubectl taint nodes master1 node-role.kubernetes.io/control-plane:NoSchedule-

kubectl config set-context --current --namespace=nudger-xwiki

passwd
New password:
Retype new password:
passwd: password updated successfully
root@master1:~# passwd dev-loic
New password:
Retype new password:
passwd: password updated successfully
root@master1:~#
sudo usermod -aG sudo dev-loic
