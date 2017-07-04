#!/bin/bash

cat > /tmp/s3proxy.conf<<EOF
LOG_LEVEL=${LOG_LEVEL:-UNSET}
s3.proxy.virtual-host=${S3PROXY_VIRTUALHOST:-UNSET}
s3proxy.endpoint=${S3PROXY_ENDPOINT:-UNSET}
s3proxy.secure-endpoint=${S3PROXY_SECURE_ENDPOINT:-UNSET}
s3proxy.authorization=${S3PROXY_AUTHORIZATION:=UNSET}
s3proxy.cors-allow-all=${S3PROXY_CORS_ALLOW_ALL:-UNSET}
s3proxy.identity=${S3PROXY_IDENTITY:-UNSET}
s3proxy.credential=${S3PROXY_CREDENTIAL:-UNSET}
s3proxy.keystore-path=${S3PROXY_KEYSTORE_PATH:-UNSET}
s3proxy.keystore-password=${S3PROXY_KEYSTORE_PASSWORD:-UNSET}
jclouds.provider=${JCLOUDS_PROVIDER:-UNSET}
jclouds.identity=${JCLOUDS_IDENTITY:-UNSET}
jclouds.credential=${JCLOUDS_CREDENTIAL:-UNSET}
jclouds.endpoint=${JCLOUDS_ENDPOINT:-UNSET}
jclouds.region=${JCLOUDS_REGION:-UNSET}
jclouds.filesystem.basedir=${JCLOUDS_BASEDIR:-UNSET}
EOF
sed -i -e '/=UNSET$/d' /tmp/s3proxy.conf
cat s3proxy.conf >> /tmp/s3proxy.conf

exec /opt/s3proxy/target/s3proxy --properties /tmp/s3proxy.conf
