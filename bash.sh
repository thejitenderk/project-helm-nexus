# dry run first
helm template todolist ./todolist -f values.yaml

# install all 3 microservices at once
helm install todolist ./todolist -f values.yaml

# upgrade
helm upgrade todolist ./todolist -f values.yaml