# Dockerize your S3Proxy Instance - Make it Run Anywhere!

[S3Proxy](https://github.com/andrewgaul/s3proxy) allows applications using the S3 API to access other storage backends, e.g., local file system, Google Cloud Storage, Microsoft Azure, OpenStack Swift. Users can use this solution to test, deploy, and run S3Proxy instance in a docker container.

## Container Environment:
* Apache Maven 3.3.9
* Maven home: /usr/share/maven
* Java version: 1.8.0_66-internal, vendor: Oracle Corporation
* Java home: /usr/lib/jvm/java-8-openjdk-amd64/jre
* Default locale: en, platform encoding: UTF-8
* jetty-9.2.z-SNAPSHOT

## Prerequisites
- Setup [docker](https://www.docker.com/)
- Understand fundamentals of S3Proxy: configuration and setup - [S3Proxy](https://github.com/andrewgaul/s3proxy)

## Getting Started
- Update [s3proxy.conf](/s3proxy.conf) with your own storage provider backend. I have provided an example of s3proxy.conf for Azure storage. For more options against other storage providers, checkout [S3Proxy's wiki](https://github.com/andrewgaul/s3proxy/wiki/Storage-backend-examples)
- If you have a need for `s3proxy.virtual-host`, update [s3proxy.conf](/s3proxy.conf) with your own docker ip.

To find the docker ip:
```
$ docker-machine ip [docker machine name]

Sample output:
192.168.99.100
```
- Build docker image:

`$ make build`

- Run S3Proxy container:

`$ docker run -t -i -p 8080:8080 s3proxy`

If you cannot get to the internet from the container, use the following:

`$ docker run --dns 8.8.8.8 -t -i -p 8080:8080 s3proxy`

## Verifying Output
Sample output should be something like this:

```
I 12-08 01:35:30.616 main org.eclipse.jetty.util.log:186 |::] Logging initialized @1046ms
I 12-08 01:35:30.642 main o.eclipse.jetty.server.Server:327 |::] jetty-9.2.z-SNAPSHOT
I 12-08 01:35:30.665 main o.e.j.server.ServerConnector:266 |::] Started ServerConnector@7331196b{HTTP/1.1}{0.0.0.0:8080}
I 12-08 01:35:30.666 main o.eclipse.jetty.server.Server:379 |::] Started @1097ms
```

`docker ps` output should be similar to this:
```
$ docker ps
CONTAINER ID        IMAGE                    COMMAND                  CREATED             STATUS              PORTS                     NAMES
789186d1debf        s3proxy                  "/bin/sh -c './target"   5 seconds ago       Up 4 seconds        0.0.0.0:8080->8080/tcp    tender_feynman
```
Since we mapped port 8080 to 8080, you can navigate to [docker ip]:8080. For example: http://192.168.99.100:8080/

## Updating Hosts File
If you are running this locally using a local ip, you will need to update your `/etc/hosts` file to add entries for the subdomains.
For example, if the root of the site is running at `http://192.168.99.100:8080/`, then make sure you add an entry in the `/etc/hosts` file for each subdomain.
If the container name is `democontainer`, then add a subdomain as follows in the hosts file.

```
192.168.99.100  democontainer.192.168.99.100
```
To verify, navigate to [CONTAINER NAME].[DOCKER MACHINE IP]:8080. For example: http://democontainer.192.168.99.100:8080/

## S3 SSL support
For SSL to work you'll need to create a self signed certificate in a Java keystore, and set [s3proxy.conf](s3proxy.conf)
to use it.

Let jclouds know about the keystore and that you'll like an SSL endpoint via [s3proxy.conf](s3proxy.conf) and add any
jcloud provider settings. This is done via the .env file. Copy the included env.sample to .env, and modify the provider
settings.

```
JCLOUDS_PROVIDER=azureblob
JCLOUDS_IDENTITY=storageaccount
JCLOUDS_CREDENTIAL=secretkey
```

The included Makefile will build a keystore.jks and keystore.crt for you, before building the
docker images.

```
$ make
keytool -keystore keystore.jks -alias aws -storepass password -genkey -keyalg RSA -keypass password \
	-validity 3650 \
	-ext san=dns:s3.amazonaws.com,dns:s3-us-west-2.amazonaws.com,dns:s3.us-west-2.amazonaws.com,dns:localhost \
	-dname 'CN=*.s3.amazonaws.com, OU=Corp, O=Internal, L=San Jose, S=CA, C=US'
keytool -keystore keystore.jks -alias aws -storepass password -exportcert -rfc > keystore.crt
docker-compose build
Building s3proxy
Step 1/11 : FROM java
 ---> d23bdf5b1b1b
Step 2/11 : FROM maven:3
 ---> d089198872b5
Step 3/11 : WORKDIR /opt
 ---> Using cache
 ---> b79905759a53
Step 4/11 : RUN git clone -b master https://github.com/andrewgaul/s3proxy.git
 ---> Using cache
 ---> 019eff749ba2
Step 5/11 : WORKDIR /opt/s3proxy
 ---> Using cache
 ---> a137eb9cea25
Step 6/11 : RUN mvn package
 ---> Using cache
 ---> d50a3b78e2cd
Step 7/11 : ADD ./s3proxy.conf /opt/s3proxy/s3proxy.conf
 ---> Using cache
 ---> 77dae5b002e7
Step 8/11 : ADD ./keystore.jks /opt/s3proxy/
 ---> d4a327a52e79
Removing intermediate container 6a4930ed3510
Step 9/11 : EXPOSE 8080
 ---> Running in c92c9b793dea
 ---> 82477a6f54c8
Removing intermediate container c92c9b793dea
Step 10/11 : EXPOSE 8443
 ---> Running in a9dd9d3211f9
 ---> 6000414563f7
Removing intermediate container a9dd9d3211f9
Step 11/11 : ENTRYPOINT ./docker-entrypoint.sh
 ---> Running in 4444fea0f596
 ---> 669fdfdf16c4
Removing intermediate container 4444fea0f596
Successfully built 669fdfdf16c4
Successfully tagged s3proxydocker_s3proxy:latest
docker-compose up -d
Recreating s3proxy ...
Recreating s3proxy ... done
```

Next redirect the SSL target to localhost via /etc/hosts:

`127.0.0.1      s3.amazonaws.com s3-us-west-2.amazonaws.com`

Set some environment variables for aws cli to work properly

```
export AWS_CA_BUNDLE=$(pwd)/keystore.crt
export AWS_DEFAULT_REGION=us-west-2
```

If you set s3proxy.authorization to something other then none, you'll need to also set the following:

```
export AWS_SECRET_ACCESS_KEY=local-credential
export AWS_ACCESS_KEY_ID=local-identity
```

Now you should be able to use the aws cli as normal:

```
$ aws s3 ls
1969-12-31 16:00:00 dataflows
1969-12-31 16:00:00 datasets

$ aws s3 ls s3://datasets/
      PRE ChicagoData/
      PRE CreditRisk/
```


## Testing with a Sample App
Refer to [the AWS Java sample app](https://github.com/ritazh/aws-java-sample) repo to test your S3Proxy deployment. It is a simple Java application illustrating usage of the AWS S3 SDK for Java.


## Other Deployment Options
You can push S3Proxy as a docker app to various platforms.

### Deploying to Platforms like Dokku
 [Dokku](http://dokku.viewdocs.io/dokku/) is a Docker powered open source Platform as a Service that runs on any hardware or cloud provider. Dokku can use the S3Proxy [Dockerfile](Dockerfile) to instantiate containers to deploy and scale S3Proxy with few easy commands. Follow the [Depoy-to-Dokku](Deploy-to-Dokku.md) guide to host your own S3Proxy in Dokku.

### Deploying to Platforms like Cloud Foundry
 [Cloud Foundry](https://www.cloudfoundry.org/) is an open source PaaS that enables developers to deploy and scale applications in minutes, regardless of the cloud provider. Cloud Foundry with Diego can pull the S3Proxy Docker image from a Docker Registry then run and scale it as containers. Follow the [Depoy-to-Cloud-Foundry](Depoy-to-Cloud-Foundry.md) guide to host your own S3Proxy in Cloud Foundry.

## Acknowledgements

Many thanks to @andrewgaul and @kahing for developing and maintaining S3Proxy.

