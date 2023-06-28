#!/bin/sh

PRODUCT='NAKIVO Backup & Replication'
#URL="http://10.10.18.187:8080/NBR/linux/10.7.2/10.7.2.69768._GA.sh"
#SHA256="8b9bd3d2cecda3084ccc6f3bdf18ca23e3879811319bd77ad9daf26b500c6944"

URL="http://10.10.18.187:8080/NBR/linux/10.9.0/10.9.0.74160-BETA.sh"
SHA256="a8abe44bd42e25d92f9c78c86b5d1d40822e759fbfc772ab4e5fdf899be3c44e"

#URL="http://10.10.18.187:8080/NBR/linux/10.9.0/10.9.0.75563.sh"
#SHA256="91528d51f0899ed53e3c7e6a38f37762d49fe8db54ed907f9ac00bdf31e01d00"

#URL="http://10.10.18.187:8080/NBR/linux/10.8.0/10.8.0.73174_GA.sh"
#SHA256="f4b3cc2466e44d4832b8df84dbc2b6da4f9de58abc229e8830d3d82d41ad3aba"

PRODUCT_ROOT="/usr/local/nakivo"
INSTALL="inst.sh"

curl --fail --tlsv1.2 -o $INSTALL $URL
if [ $? -ne 0 -o ! -e $INSTALL ]; then
    echo "ERROR: Failed to get $PRODUCT installer"
    rm $INSTALL >/dev/null 2>&1
    exit 1
fi

CHECKSUM=`sha256 -q $INSTALL`
if [ "$SHA256" != "$CHECKSUM" ]; then
    echo "ERROR: Incorrect $PRODUCT installer checksum"
    rm $INSTALL >/dev/null 2>&1
    exit 2
fi

sh ./$INSTALL -f -y -i "$PRODUCT_ROOT" --eula-accept --extract 2>&1
if [ $? -ne 0 ]; then
    echo "ERROR: $PRODUCT install failed"
    rm $INSTALL >/dev/null 2>&1
    exit 3
fi
rm $INSTALL >/dev/null 2>&1

#disable default HTTP ports redirect
SVC_PATH="$PRODUCT_ROOT/director"
awk 'BEGIN{A=0} /port="80/{A=1} {if (A==0) print $0} />/{A=0}' $SVC_PATH/tomcat/conf/server-linux.xml >$SVC_PATH/tomcat/conf/server-linux.xml_ 2>/dev/null
mv $SVC_PATH/tomcat/conf/server-linux.xml_ $SVC_PATH/tomcat/conf/server-linux.xml >/dev/null 2>&1

#enforce EULA
PROFILE=`ls "$SVC_PATH/userdata/"*.profile 2>/dev/null | head -1`
if [ "x$PROFILE" != "x" ]; then
    sed -e 's@"system.licensing.eula.must.agree": false@"system.licensing.eula.must.agree": true@' "$PROFILE" >"${PROFILE}_" 2>/dev/null
    mv "${PROFILE}_" "$PROFILE" >/dev/null 2>&1
fi

service nkv_dirsvc start >/dev/null 2>&1
