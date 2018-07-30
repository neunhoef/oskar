ferr(){
    echo "fatal error: $@"
    exit 1
}

ensure(){
	"$@" && return
	ferr "failed to run: createRepo $@"
}

ensureOskar(){
	ensure ./createRepo "$@" && return
	ferr "failed to run: createRepo $@"
}

setup_gpg(){
    exec 3</tmp/createRepoFd3
    export KEYNAME=115E1684
    export GPG_TTY="$(tty)"

    /usr/bin/gpg-agent --homedir=~/.gnupg --daemon --use-standard-socket --allow-loopback-pinentry 2>&3
    gpg2 --import -v -v ~/.gnupg/secring.gpg 2>&3 || ferr "failed to import secret"
    gpg2 --import -v -v ~/.gnupg/pubring.gpg 2>&3 || ferr "faild to import public key"

     ## wozu? - add key to gpg one time (willi - script)
     cd /tmp/
     echo "bla"> Release
     gpg2 --pinentry-mode=loopback --digest-algo SHA512 \
          --passphrase-fd 0 --yes -abs \
          -u "$KEYNAME" \
          -o Release.gpg Release <<<"arangodb" 2>&3
     (( $? != 0 )) && { echo "failed test signing"; cat /tmp/createRepoFd3  exit 1; }
     exec 3<&-
}
