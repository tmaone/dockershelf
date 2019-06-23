#!/usr/bin/env bash
#
#   This file is part of Dockershelf.
#   Copyright (C) 2016-2018, Dockershelf Developers.
#
#   Please refer to AUTHORS.md for a complete list of Copyright holders.
#
#   Dockershelf is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   Dockershelf is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program. If not, see http://www.gnu.org/licenses.

# Exit early if there are errors and be verbose.
set -exuo pipefail

# Some default values.
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

PHP_VER_NUM_MAJOR="$( echo ${PHP_VER_NUM} | awk -F'.' '{print $1}' )"
PHP_VER_NUM_STR="php${PHP_VER_NUM}"
PHP_VER_NUM_MAJOR_STR="php${PHP_VER_NUM_MAJOR}"

MIRROR="http://deb.debian.org/debian"
UBUNTUMIRROR="http://archive.ubuntu.com/ubuntu"

# This is the list of php packages from debian that make up a minimal
# php installation. We will use them later.
PHP_PKGS="${PHP_VER_NUM_STR} \
    ${PHP_VER_NUM_STR}-cli \
    composer"

# Some tools are needed.
DPKG_TOOLS_DEPENDS="aptitude deborphan debian-keyring dpkg-dev gnupg"

# Load helper functions
source "${BASEDIR}/library.sh"

# Apt: Install tools
# ------------------------------------------------------------------------------
# We need to install the packages defined at ${DPKG_TOOLS_DEPENDS} because
# some commands are needed to download and process dependencies.

msginfo "Installing tools and upgrading image ..."
cmdretry apt-get update
cmdretry apt-get -d upgrade
cmdretry apt-get upgrade
cmdretry apt-get install -d ${DPKG_TOOLS_DEPENDS}
cmdretry apt-get install ${DPKG_TOOLS_DEPENDS}

# PHP: Configure sources
# ------------------------------------------------------------------------------
# We will use Debian's repository to install the different versions of PHP.

msginfo "Configuring /etc/apt/sources.list ..."
{
    echo "deb ${MIRROR} ${PHP_DEBIAN_SUITE} main"
} | tee /etc/apt/sources.list.d/php.list > /dev/null

if [ "${PHP_VER_NUM}" == "7.2" ]; then
    {
        echo "deb ${UBUNTUMIRROR} bionic main"
    } | tee /etc/apt/sources.list.d/ubuntu.list > /dev/null

    cmdretry apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3B4FE6ACC0B21F32
fi

cmdretry apt-get update

# Apt: Install runtime dependencies
# ------------------------------------------------------------------------------
# Now we use some shell/apt plumbing to get runtime dependencies.

msginfo "Installing php runtime dependencies ..."
DPKG_RUN_DEPENDS="$( aptitude search -F%p \
    $( printf '~RDepends:~n^%s$ ' ${PHP_PKGS} ) | xargs printf ' %s ' | \
    sed "$( printf 's/\s%s\s/ /g;' ${PHP_PKGS} )" )"
DPKG_DEPENDS="$( printf '%s\n' ${DPKG_RUN_DEPENDS} | \
    uniq | xargs )"

cmdretry apt-get install -d ${DPKG_DEPENDS}
cmdretry apt-get install ${DPKG_DEPENDS}

# PHP: Installation
# ------------------------------------------------------------------------------
# We will install the packages listed in ${PHP_PKGS}

msginfo "Installing PHP ..."
cmdretry apt-get install -d ${PHP_PKGS}
cmdretry apt-get install ${PHP_PKGS}

# Apt: Remove unnecessary packages
# ------------------------------------------------------------------------------
# We need to clear the filesystem of unwanted packages to shrink image size.

msginfo "Removing unnecessary packages ..."
# This is clever uh? I figured it out myself, ha!
cmdretry apt-get purge $( apt-mark showauto $( deborphan -a -n \
                                --no-show-section --guess-all --libdevel \
                                -p standard ) )
cmdretry apt-get autoremove

# This too
cmdretry apt-get purge $( aptitude search -F%p ~c ~g )
cmdretry apt-get autoremove

cmdretry apt-get purge ${DPKG_TOOLS_DEPENDS}
cmdretry apt-get autoremove

# Bash: Changing prompt
# ------------------------------------------------------------------------------
# To distinguish images.

cat >> "/etc/bash.bashrc" << 'EOF'

COLOR_LILAC="\[\033[38;5;105m\]"
COLOR_PURPLE="\[\033[38;5;56m\]"
COLOR_OFF="\[\033[0m\]"
PS1="${COLOR_LILAC}[\u@${COLOR_PURPLE}\h]${COLOR_OFF}:\w\$ "
EOF

# Final cleaning
# ------------------------------------------------------------------------------
# Buncha files we won't use.

msginfo "Removing unnecessary files ..."
find /usr -name "*.py[co]" -print0 | xargs -0r rm -rfv
find /usr -name "__pycache__" -type d -print0 | xargs -0r rm -rfv
rm -rfv "/tmp/"* "/usr/share/doc/"* "/usr/share/locale/"* "/usr/share/man/"* \
        "/var/cache/debconf/"* "/var/cache/apt/"* "/var/tmp/"* "/var/log/"* \
        "/var/lib/apt/lists/"*