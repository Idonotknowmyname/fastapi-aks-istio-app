# Example Fastapi app on Azure Kubernetes Service and Istio
This repository contains the files necessary to create and deploy a FastAPI app on Azure Kubernetes Service, managing a canary deployment of two versions of the service, with an 80/20 split achieved using Istio.

## Prerequisites
In order to run the commands to make this work you need the following binaries available on your machine and in your PATH (in brackets you can see the version I tested this with, but it might still be working with different ones although I cannot guarantee it):
 - `docker` (20.10.8)
 - `az` (2.30.0)
 - `kubectl` (1.19.2)
 - `istioctl` (1.12.0)
 - `helm` (3.7.1)
 - `terraform` (1.0.11)
 - `make` (GNU Make, 3.81)

Furthermore you also need:
 - To have authenticated the azure CLI with `az login`, with an account that has access to creating the necessary resources
 - To have the docker daemon running on your local machine (and be able to run docker commands)

## How to run
To set up the whole application (infrastructure + code + deployment) just run:
```bash
# Create infra with terraform and get AKS credentials
make infrastructure
# Build and push docker image
make docker
# Deploy istio and the application onto the cluster
make deployment

# OR

make all
```

This will take a few minutes as it takes sometime to spin up the AKS cluster. Once complete, you can run the following command to get the public ip address to access the application:
```bash
export APP_HOST=$(kubectl -n istio-system get svc istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

Finally, you can make an HTTP request to `http://${APP_HOST}/hello` to test the app's output, here is an example using `curl`:
```bash
curl "http://${APP_HOST}/hello"
```
You will see that approximately 80% of the times you will get a certain version returned in the message, while 20% of the times you will get a different one (achieved using Istio virtual services and routing rules).

## Cleanup
From the final state, you can remove the deployment and its infrastructure by running:
```bash
make clean-deployment
make clean-infrastructure

# OR

make clean
```

The only remaining things that are not removed are the local docker image built and the kubectl context of the cluster in the kubeconfig. Next time you run `make all` they will be overwritten.

## Note
I have not tested this on other machines/accounts, so there might be an issue with creating the container registry if it has already been created on another account/machine.