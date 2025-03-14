#!/bin/sh

myself() {
  hostname
}

is_kubernetes() {
  if [ -f /var/run/secrets/kubernetes.io/serviceaccount/token ]; then
    return 0
  else
    return 1
  fi
}

volumes() {
  # Inspect own container to find out which volumes are actually mounted at /volumes and print their name
  docker inspect $(myself) --format '{{json .Mounts}}' | jq -r ".[] | select(.Destination | startswith(\"/volumes\")) | .Name"
}

get_mounts() {
  cts=$(docker ps -q)

  # For every volume passed as argument
  for volume in $@; do
    # For every running container
    for ct in $cts; do
      # Inspect it and determine if mounts a specific volume by its name
      docker inspect "$ct" --format "{{json .Mounts}}" | jq -e -r ".[] | select(.Name == \"$volume\")" > /dev/null && echo "$volume $ct"
      # jq -e makes jq exit with non-zero if there is no output, so the only printed containers are the ones that mount the volume
    done
  done
}

backup_docker() {
  volumes=$(volumes)

  # Getting all mounts for all volumes that are under /volumes in my own container |
  # Getting only the container IDs |
  # uniq |
  # Removing myself from the result

  # This way we get only the containers that are running and of which we are mounting the volumes under /volumes

  cts=$(get_mounts "$volumes" | cut -d ' ' -f 2 | uniq | grep -v $(myself))

  echo "Stopping containers"
  docker stop $cts

  sleep 10

  eval "$COMMANDS_PRE"

  echo "Backing up /volumes"
  restic backup /volumes

  if [ $? -eq 0 ]; then
    eval "$COMMANDS_SUCCESS"
  else
    eval "$COMMANDS_FAIL"
  fi

  eval "$COMMANDS_POST"

  echo "Starting containers"
  docker start $cts
  docker start $cts # Sometimes containers have dependencies on others and wont start at the first time
}

backup_kubernetes() {

  DEPLOYMENTS=$(kubectl get deployments -o jsonpath='{.items[*].metadata.name}')
  REPLICAS=$(kubectl get deployments -o jsonpath='{.items[*].spec.replicas}')
  
  for DEPLOYMENT in $DEPLOYMENTS; do
    kubectl scale deployment $DEPLOYMENT --replicas=0
  done
  
  # Check if all deployments have been scaled down
  ALL_SCALED_DOWN=false
  while [ $ALL_SCALED_DOWN = false ]; do
    ALL_SCALED_DOWN=true
    for DEPLOYMENT in $DEPLOYMENTS; do
      CURRENT_REPLICAS=$(kubectl get deployment $DEPLOYMENT -o jsonpath='{.spec.replicas}')
      if [ "$CURRENT_REPLICAS" != "0" ]; then
        ALL_SCALED_DOWN=false
        break
      fi
    done
    if [ $ALL_SCALED_DOWN = false ]; then
      sleep 2
    fi
  done
  
  eval "$COMMANDS_PRE"
  
  restic backup /volumes
  
  if [ $? -eq 0 ]; then
    eval "$COMMANDS_SUCCESS"
  else
    eval "$COMMANDS_FAIL"
  fi
  
  eval "$COMMANDS_POST"
  
  i=0
  for DEPLOYMENT in $DEPLOYMENTS; do
    kubectl scale deployment $DEPLOYMENT --replicas=$(echo $REPLICAS | cut -d' ' -f$((i+1)))
    i=$((i+1))
  done

}

if is_kubernetes; then
  backup_kubernetes
else
  backup_docker
fi
