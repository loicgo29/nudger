 vagrant halt 
 vagrant destroy -f
rm -rf .vagrant
echo "lsof -i :50022"

PORT=50022

echo "Recherche des processus utilisant le port $PORT..."
PID=$(lsof -ti :$PORT)

if [ -z "$PID" ]; then
  echo "Aucun processus trouvé sur le port $PORT."
  exit 0
fi

echo "Processus trouvés :"
ps -p $PID

read -p "Voulez-vous tuer ces processus ? (y/n) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Envoi de SIGTERM aux processus $PID..."
  kill -15 $PID
  sleep 2

  # Vérification si les processus sont toujours actifs
  if lsof -ti :$PORT > /dev/null; then
    echo "Les processus résistent, envoi de SIGKILL..."
    kill -9 $PID
  fi

  echo "Processus terminés."
else
  echo "Annulation."
fi
