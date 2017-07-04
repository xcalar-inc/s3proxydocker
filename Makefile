.PHONY: build import

run: build
	docker-compose up -d

build: keystore.jks keystore.crt
	docker-compose build

import: keystore.crt
	keytool -keystore $(JAVA_HOME)/lib/security/cacerts  -import -alias aws -file $< -trustcacerts -storepass changeit

%.jks:
	keytool -keystore $@ -alias aws -storepass password -genkey -keyalg RSA -keypass password \
		-validity 3650 \
		-ext san=dns:s3.amazonaws.com,dns:s3-us-west-2.amazonaws.com,dns:s3.us-west-2.amazonaws.com,dns:localhost \
		-dname 'CN=*.s3.amazonaws.com, OU=Corp, O=Internal, L=San Jose, S=CA, C=US'

%.crt: %.jks
	keytool -keystore $< -alias aws -storepass password -exportcert -rfc > $@
