#!/bin/bash

set -euo pipefail
set -o nounset

if [ -d "$1" ]
then
  readonly CTX="$1"
else 
  readonly CTX=$(dirname `readlink -f $0`)
fi

# Installs puppet, git, etc
install_deps()
{
  if $(which apt)
  then 
    apt-get install -y git puppet gnupg2 ruby-dev build-essential
  else
    {
      rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm
    } || {
      echo '[i] Already added rpm'
    }

    yum groupinstall -y "Development tools"
    yum install -y git puppet gpg ruby-devel
  fi
}

# Utilities related to puppet
install_gems()
{
  if ! $(gem list -i gpgme)
  then
    echo '[i] Installing gems'
    # @todo ? should be moved to Gemfile?
    gem install r10k librarian-puppet puppet-lint hiera-eyaml hiera-eyaml-gpg ruby_gpg gpgme
  fi
}

# Some quick validation before running the script
preinstall()
{
  if [[ `id -u` -ne 0 ]]
  then
    echo '[!] You need to run this as sudo!'
    return 1
  fi

  if [[ ! -f  "${CTX}/README.md" ]]
  then
    echo '[!] Script must be in context of the repo it came with'
    return 2
  fi
}

# Configuring puppet after installation
configure()
{
  if [ "$CTX" != '/etc/puppet' ]
  then
    # Copy and overwrite
    cp -rf $CTX/* /etc/puppet
    cp -rf $CTX/.git /etc/puppet/.git
  fi

  # @todo cleanup old environment
  cd /etc/puppet

  # If not .git directory ... is not a repo
  if [ ! -d .git ]
  then
    echo '[!] Does not appear to be a git repo'
    return 3
  fi

  # If there is a master branch rename to production
  { 
    git branch | grep production 
  } || {
    echo '[i] Creating production branch off master'
    git branch production
  }
}

# Final touches
postinstall()
{
  # Force set a path to ensure r10k can run
  PATH=/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/usr/sbin:/home/vagrant/bin
  cd /etc/puppet
  r10k deploy environment -p
}

main()
{
  echo "[i] Installing puppet, running from ${CTX} ..."
  preinstall
  install_deps
  install_gems
  configure
  postinstall
}

main
