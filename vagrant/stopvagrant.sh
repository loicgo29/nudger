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

  kill -15 $PID
  # Vérification si les processus sont toujours actifs
