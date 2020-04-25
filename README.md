

[TOC]

# mephskeleton

## Intro

This service template tool offers a way to create springboot k8s microservices and its CI/CD pipeline. These functionalities ar covered:

* Creation of a multilayer springboot artifact
* Creation of a bitbucket repository to host the micorservice
* Creation of a multibranch Jenkinsfile based pipeline in your Jenkins Server

It's build over a maven archetype (yes maven, didn't have time enough to learn the needed gradle skills :) ). 

## Main features

With this tool we can create a CI pipeline based on Jenkins as automation to run it and a git repository to manage your code versions. This pipeline has thes main traits:

* As it's been said, it generates microservices based on **Springboot framework**, it encapsulates them into **docker images** that will be deployed in **kubernetes**.
* It's based on maven and we use the **multi-module parent's pom for dependency version managment.**
* It's oriented to work with **trunk based development**. Every feature you merge & push to your master branch should be ready to production. 
* It considers two deployment environmnents: **integration & production**. 
  * Every time you push to master your code is deployed in the integration environment.
  * Every time you push to a release branch your code will be deployed to the production environment.

> You could turn it quickly to a CD pipeline if you enable master branch to be deployed to the production environment
> in the supplied Jenkinsfile.

## Cool features: just two tips to enhance pipeline speed

We've tried to focus our efforts in deployment and pipeline speed. If we consider these steps:

* build
* test
* check quality (sonar)
* bulild images
* publish images
* deploy

Not all these steps can be speeded up but, not all of them need to be run every time we run our pipeline. Following simple actions we can reduce our pipeline execution time:

* **Images are splitted in two parts, framework nd business**: this allow the pipeline to deal with them separately and joins them in the final image. So,if you only modify your bussines code and you don't add/modify any dependency, only this part of the image will need to be rebuilt.


* **Use of commit id to tag images** . It enables us to skip some steps that have been processed before with the same version of code:
  * It's **fast to go from integration to production** since steps like building, testing, creating images,.. don't need to be repeated.
  * It's **fast to deploy a version previously deployed** since all these mentioned stops have previously been processed.

## Base Use Case (with shell script pipeline)

To create a new microservice is as easy as launch the create project script:

`
 ./create_project.sh mephistos_bitbucket mephmicroapi
`

this will create in te build_project folder an springboot multilayer application with the default attributes called *mephmicroapi*.

Resulting artifact can be customized setting the groupId for your artifact and/or the package that will contain your classes:

`
 ./create_project.sh mephistos_bitbucket mephmicroapi -g mygroupid -p com.mypackage
`

Scripts in build_pipeline folder can be used to:

* build
* test
* generate and publish images to a registry
* deploy your artifacts to a k8s cluster.

In the *build_pipeline/environment_scripst* you have the chance to manage configuration for the different deploy environments. We consider two deployment environments for your artifacts: 

* production
* integration

And, by default, we manage them through different namespaces in the same kubernetes cluster, although it would be easy to manage them with different clusters if you prefer to managing your kubectl configuration. 

To do so you can add the commands you need to each of the environment scripts defined in the *build_pipeline/environment_scripst* folder. There's a script for each environment where variables used by the pipeline can be redefined and where you can place any code you need to execute regarding each environment. These are the main variables:


| Variables | Use |
| --- | --- | --- |
| K8S_NAMESPACE  K8S_ENV_NAMESPACE_PREFIX  K8S_ENV_NAMESPACE_POSTFIX | The combination of these three variables determine the deployment namespace for our k8s objects.
|RESTAPI_K8S_DOMAIN_NAME  RESTAPI_K8S_DOMAIN_NAME_PREFIX  RESTAPI_K8S_DOMAIN_NAME_POSTFIX | The combination of these variables determine the domain used to map in the k8s ingress the requests to your service.

On the other hand, and used for all environments, we have *build_pipeline/00_env_pipeline.sh* script where you could customize your docker registry / docker registry prefix for your images as well as the login command you need to launch for your registry.

Finally, you there's a sonar step in the pipeline scripts you can run if you define in *build_pipeline/00_env_pipeline.sh* the SONAR_USER, SONAR_PASSWORD and SONAR_URL. You could inject them from the CI/CD tool you are using.

## let's automate: git & jenkins

If you wan't to build a complete pipeline you need to go further with our microservice creation script. You'll need to supply more info so this tool can be able to:

* Create a bitbucket repo for your microservice.
* Create a jenkins pipeline in your jenkins.

To do so you'll need to launch the create project command this way:

`
./create_project.sh -r <registry url> -ns <my base kubernetes namespace>
-bbprojectkey <project key where to create repo> -bbuser <my bitbucket user> 
-bbpass <my bitbucket pass> -bbteam <bitbucket team>  -jurl <jenkins url> 
-japicred <jenkins user:jenkins api key> -jgitcred <your git credentials id in jenkins> <microservice name> <package for java classes>
`

This example works for me using a local docker Desktop kubernetes stack with a local registry at *localhost:5000*:

`
./create_project.sh -r http://localhost:5000 -ns meph -bbprojectkey MEPHISTOS -bbuser mephistos -bbpass xxxxxxx -bbteam 3dteam  -jurl https://bitbucket.org -japicred jenkins_deploy:xxxxxxxxx -jgitcred git_creD_user mynewapi com.meph.mynewapi
`

Another option you can apply is to create a jenkins task to run this command adding just the parameters to set your service name and package.



