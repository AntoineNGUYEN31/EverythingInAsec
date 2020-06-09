# Install microk8s from the edge channel (Rancher requires Helm 2.15.1 or above)
$ sudo snap install microk8s --classic --edge
# Enable useful plugins
$ sudo microk8s.enable dns dashboard storage ingress helm

# Allow running priviledged Pods (required by Rancher's `cattle-node-agent`)
$ sudo sh -c 'echo "--allow-privileged=true" >> /var/snap/microk8s/current/args/kube-apiserver'
$ sudo systemctl restart snap.microk8s.daemon-apiserver.service

# Setup and install Tiller (part of Helm)
$ sudo microk8s.kubectl create serviceaccount tiller --namespace kube-system
$ sudo microk8s.kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
$ sudo microk8s.helm init --service-account=tiller

# Install cert-manager user by Rancher
$ sudo microk8s.helm repo add jetstack https://charts.jetstack.io
$ sudo microk8s.kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.9/deploy/manifests/00-crds.yaml
$ sudo microk8s.kubectl create namespace cert-manager
$ sudo microk8s.kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true
$ sudo microk8s.helm install --name cert-manager --namespace cert-manager --version v0.9.1 jetstack/cert-manager

# Install stable Rancher
$ sudo microk8s.helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
$ sudo microk8s.helm install rancher-stable/rancher --name rancher --namespace cattle-system  --set replicas=1 --set hostname=${HOSTNAME}.home
