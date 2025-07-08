# Automate Kubernetes(hosted locally) deployments with GitHub Actions 

URL 

1. https://nth-root.nl/en/guides/automate-kubernetes-deployments-with-github-actions


## Learn how you can use GitHub Actions to automatically build, test and deploy your Docker images to Kubernetes when you push a commit to your repository.


1. **Push vs. Pull-based deployments**

```
Before we dive into the details of automating deployments to Kubernetes with GitHub Actions, let's take a step back and look at the two main approaches for automated deployments to Kubernetes: push-based and pull-based deployments.

With a push-based deployment, the CI/CD system is triggered by a commit to the repository, builds the Docker image, pushes it to a container registry, and then notifies Kubernetes to update the image and replace the pods.

With a pull-based deployment, an agent (such as ArgoCD) is running inside the Kubernetes cluster and continuously checks your Git repository and/or container registry for any changes. When it detects a mismatch between your configuration and the actual state of the cluster, it will automatically make the necessary changes to bring the cluster back into the desired state.

Pull-based deployments have the advantage that your cluster will always be in sync with the desired (configured) state and the additional security benefit that you don't need to give an external CI/CD system access to your cluster. On the other hand, push-based deployments are more flexible and easier to set up. In this guide we will focus on push-based deployments using GitHub Actions.
```


2. **About GitHub Actions**

```
GitHub Actions is a powerful tool for automating workflows in your GitHub repositories. It allows you to configure complex workflows which are triggered by events, for example when an issue is created, a pull request is merged or a commit is pushed to a branch.
```

![Alt text](https://nth-root.nl/ci-cd-pipeline.69c351a8.png "A successful GitHub Actions pipeline execution")

```
The advantages of using GitHub Actions instead of a third-party CI/CD platform are the tight integration with GitHub, the ability to define workflows through configuration files stored in your Git repository, and the marketplace with open-source actions which can be used to build complex workflows without writing verbose shell scripts. In this guide we will use popular actions such as docker/build-push-action and localhost/k8s-deploy to build and push a Docker image and apply our Kubernetes manifests to the cluster.
```

3. **Security considerations**

```
Because anyone can publish an action to the GitHub Marketplace, and because actions can execute arbitrary code and access the secrets you pass to them, it is important to consider the security implications of using third-party actions in your workflows. Using malicious actions can lead to supply chain attacks or the stealing of tokens and other secrets.

In this guide we will use popular actions published by verified and trusted organizations such as GitHub, Docker etc. These verified publishers are indicated by a checkmark in the GitHub Marketplace. If you use other actions from the GitHub Marketplace, make sure to review the source code of the action and evaluate the trustworthiness of their publisher before using them in your workflows.
```

4. **Creating a new GitHub Actions workflow**

```
GitHub Actions workflows are defined in YAML files which are stored in a .github/workflows directory inside your Git repository. The benefit of this approach is that the workflow definition is versioned along with your code, so it can be reviewed, discussed, and modified together like any other code.

The filename can be anything you like, as long as it ends with .yaml or .yml. A repository can contain multiple workflow files, each defining a different workflow which can be triggered by different events. Each file should at least specify the name of the workflow and the event that triggers it:

name: CI/CD

on: push

jobs:
  (...)
  
In the example above, the workflow is named CI/CD and is triggered when a commit is pushed to any branch.  
```


5. **Running automated tests**

```
Before deploying any changes to Kubernetes you'll want to run your automated tests to ensure that your application works as expected and that existing functionality doesn't break.

The exact steps to run your tests depend on the language and tools you are using, but you will typically need to follow these steps:

1. Start a database container or other services that are required to run your tests.

2. Install the correct version of the compiler or interpreter for your programming language, along with any required libraries, extensions or tools.

3. Check out the source code of your application.

4. Install the dependencies of your application using a package manager.

5. Run the tests and any other quality checks.

The GitHub Marketplace provides a wide range of actions that can be used to perform these steps. For example, a workflow that tests a PHP application might look like this:


name: CI/CD

on: push

jobs:
  test:
    name: Test
    runs-on: ubuntu-latest
    services:
      database:
        image: postgres:17.4
        env:
          POSTGRES_PASSWORD: example
        ports:
          - 5432:5432
    steps:
      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.3'

      - name: Checkout source code
        uses: actions/checkout@v4

      - name: Install dependencies with Composer
        uses: ramsey/composer-install@v3

      - name: Run the tests
        run: vendor/bin/phpunit
		
		
This workflow defines a single job named Test which runs on an Ubuntu runner. It starts a database container and then executes the following steps in sequence:

1. It installs PHP 8.3 using the shivammathur/setup-php action;
2. It checks out the source code of the repository using the actions/checkout action;
3. It installs the dependencies of the application using Composer with the ramsey/composer-install action;
4. It runs the PHPUnit test suite by executing vendor/bin/phpunit.


If any of the steps fail, the job will be marked as failed and the workflow will be stopped.		
```

6. **Building and pushing the Docker image**

```
When the tests have passed, we can start building the Docker image based on our Dockerfile. We will use the docker/login-action, docker/build-push-action and the with the docker/setup-buildx-action to authenticate with the container registry, build the image, and push it to the registry.

The docker/build-push-action allows us to build and push the image in a single step. It takes a list of tags as input, which can be static or dynamic values. This allows us to tag the image with a unique identifier, for example the Git commit hash, which we will later use to deploy the image to Kubernetes:


name: CI/CD

on: push

jobs:
  test:
    (...)

  build:
    name: Build
    runs-on: ubuntu-latest
    steps:
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          (...)

      - name: Build and push the Docker image
        uses: docker/build-push-action@v6
        with:
          tags: |
            ghcr.io/username/package:latest
            ghcr.io/username/package:${{ github.sha }}
			
Note that by default, docker/build-push-action uses the Git context so we don't need to use the actions/checkout action in this job.			
```

7. **Pushing to GitHub Container Registry**

```
Using the GitHub Container Registry (GHCR) simplifies the authentication process because GitHub Actions automatically generates a token that can be used to push and pull images. The scope of this token is limited to the repository the workflow is running in.

Repositories do not automatically have access to containers in the package registry. To grant a repository access to a package, you first have to create the package (by manually pushing an image from the command line), then go to the package settings and under Manage Actions access add the repository with the Write role:

![Alt text](https://nth-root.nl/gha-repository-access.a1b61401.png "GH Repo Access")

After this, you can use ${{ secrets.GITHUB_TOKEN }} in the workflow:

- name: Login to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.repository_owner }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and push the Docker image
        uses: docker/build-push-action@v6
        with:
          push: true
          tags: |
            ghcr.io/username/package:latest
            ghcr.io/username/package:${{ github.sha }}

```

![Alt text]()


















