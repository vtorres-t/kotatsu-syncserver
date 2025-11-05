echo 'Update & Upgrade Alpine'
apk update & apk upgrade

echo 'Install openjdk21'
apk --no-cache --update add openjdk21

# Package variables
PKG_URL=$(curl -s https://api.github.com/repos/sbs20/scanservjs/releases/latest | grep browser_download_url | cut -d '"' -f 4)
PKG_DIR="/var/www/kotatsusyncserver/"
PKG_UPD="/tmp/kotatsusyncserver/"

# Userspace variables
username=kotatsusyncserver

# Create install/temp folder
if [ -d "$PKG_DIR" ]; then
    echo "Directory found, creating data backup."
    mkdir -p $PKG_UPD
    echo "Backing up configuration and files..."
    cp -a $PKG_DIR/config $PKG_UPD
    cp -a $PKG_DIR/data $PKG_UPD
    if [ -f "/etc/init.d/kotatsusyncserver" ]; then
        echo "Stopping service..."
        rc-service kotatsusyncserver stop
    fi
    echo "Cleaning up previous install"
    rm -rf $PKG_DIR/*
  else
    echo "No previous kotatsusyncserver found in $PKG_DIR, creating install directory"
    mkdir -p $PKG_DIR
fi

# User management
adduser -u 1000 -D $username

# Create install folders
mkdir -p $PKG_CONF

# Download and install latest scanservjs release
curl -L $PKG_URL | tar -zxf - -C $PKG_DIR

# Restore data from backup
if [ -d "$PKG_UPD" ]; then
    echo "Restoring config and data from backup..."
    cp -a -v $PKG_UPD/data $PKG_DIR/
    cp -a -v $PKG_UPD/config $PKG_DIR/
fi

# Create service
if [ -f "/etc/init.d/kotatsusyncserver" ]; then
      rm -rf /etc/init.d/kotatsusyncserver
fi

cat << EOF >> /etc/init.d/kotatsusyncserver
#!/sbin/openrc-run

name="kotatsusyncserver"
pidfile="/run/kotatsusyncserver.pid"
directory="$PKG_DIR"
command="/usr/bin/kotatsusyncserver"
command_args="./server/server.js"
command_background=true
command_user="$username"

depend() {
    need net
}
EOF


# Set permissions
chown -R $username:users $PKG_DIR/config
chown -R $username:users $PKG_DIR/data
chmod +x $PKG_DIR/server/server.js
chmod 755 /etc/init.d/kotatsusyncserver

# Add service
rc-update add kotatsusyncserver default
# Start server
rc-service kotatsusyncserver start

