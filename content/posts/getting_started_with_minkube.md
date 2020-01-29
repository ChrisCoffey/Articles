---
title: "Getting_started_with_minkube"
date: 2019-12-21T10:57:51-05:00
draft: true
toc: false
tags:
    - devops
    - k8s
---

Experience report on getting K8s up and running on OSX for a Haskell project

### Installing K8S
- minikube: https://kubernetes.io/docs/setup/learning-environment/minikube/
    - check that my machine supports VT-x (what is this?)
    - Make sure a hypervisor is instaled
        - I'm running with virtualbox
    - install via brew
    - validate the install via `minikube start --vm-driver=virtualbox`
        - This takes a while and consumes 20GB of disk space
    - What does this actually do?
        - Creates a single-node cluster on my local machine
            - What's a single-node cluster in the context of K8s?
- Interacting with the k8s cluster
    - Docs suggest `kubectl create deployment hello-minikube --image=k8s.gcr.io/echoserver:1.10`
        - I received an error saying "error: no matches for kind "Deployment" in version "extensions/v1beta1""
            - Because no good experience report is successful unless something goes wrong
            - Running `kubectl version` has some surprising results:
```
Client Version: version.Info{Major:"1", Minor:"10", GitVersion:"v1.10.3", GitCommit:"2bba0127d85d5a46ab4b778548be28623b32d0b0", GitTreeState:"clean", BuildDate:"2018-05-21T09:17:39Z", GoVersion:"go1.9.3", Compiler:"gc", Platform:"darwin/amd64"}
Server Version: version.Info{Major:"1", Minor:"17", GitVersion:"v1.17.0", GitCommit:"70132b0f130acc0bed193d9ba59dd186f0e634cf", GitTreeState:"clean", BuildDate:"2019-12-07T21:12:17Z", GoVersion:"go1.13.4", Compiler:"gc", Platform:"linux/amd64"}
```
            - notice the BuildDate for the clent version
            - Turns out that I had a stale version of kubectl installed due to a docker-for-mac install
                - relinking `kubectl` from the `minikube` install resolved this: `brew link --overwrite kubernetes-cli`
                ```
                Client Version: version.Info{Major:"1", Minor:"17", GitVersion:"v1.17.0", GitCommit:"70132b0f130acc0bed193d9ba59dd186f0e634cf", GitTreeState:"clean", BuildDate:"2019-12-13T11:52:47Z", GoVersion:"go1.13.4", Compiler:"gc", Platform:"darwin/amd64"}
                Server Version: version.Info{Major:"1", Minor:"17", GitVersion:"v1.17.0", GitCommit:"70132b0f130acc0bed193d9ba59dd186f0e634cf", GitTreeState:"clean", BuildDate:"2019-12-07T21:12:17Z", GoVersion:"go1.13.4", Compiler:"gc", Platform:"linux/amd64"}
                ```
    - After updating the `kubectl` version and creating a deployment using the gcr echoserver image, its time to actually do something with k8s, right?
        - but first, explose the deployment on my local machine as a Service (what's a service?)
            - kubectl expose deployment hello-k8s --type=NodePort --port=8080
        - So, this somehow created a Pod (what's a pod?)
            - but now we need to wait for the pod to start
                - `kubectl get pod` lists the statuses of all the pods
        - Once its in `RUNNING` status I can grab the url of my echo service:
            - `minikube service hello-k8s` launches a browser tab with informatin about the local cluster
                - Why did we switch from kubectl to minikube here?
- Stopping the cluster
    - This is complicated. It invovles tearing down the k8s service first, then the minikube VM environment
        1. `kubectl delete services hello-k8s`
        2. `kubectl delete deployment hello-k8s`
        3. `minikube stop`
        4. If you want to complete remove it, `minikube delete` does the trick
- Using local images
    - I'm working on an app locally. I don't want to go through a "push to DockerHub -> pull from DockerHub into K8s -> build image" cycle every time I update things. I'd like to use my local Docker daemon.
        - Minikube has an embedded Docker daemon that can be bound to the `docker` command via `eval $(minikube docker-env)`
    - Persistent volumes are also possible, but to preserve them a cross minikube boots (it uses a tempfs by default), they need to be in one of these directories:
        - /data
        - /var/lib/minikube
        - /var/lib/docker
        - what's a PersistentVolume in k8s. Does it differ from Docker's version?
    - Its also possible to mount a host folder directly into the vm.
        - For virtualbox I have `/Users` mounted directly into my vm

### How does K8s work??
- Declarative control, but via an API rather than static config files
    - Effectively a "descriptive" version of system management.
        - Once a K8s object is created, the cluster works to ensure that object always exists
        -
- Core abstractions
    - Pod
        - Clusters of containers that run as single units
            - Basically a wrapper around a container that abstracts away the underlying container implementation
        - May have an `init` container that runs before any of the applicatin containers start up
        - Not intended to be created standalone, but rather created via a k8s service
    - Service
    - Volume
    - Namespace
