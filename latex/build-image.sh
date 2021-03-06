#!/usr/bin/env bash
#
#   This file is part of Dockershelf.
#   Copyright (C) 2016-2020, Dockershelf Developers.
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

# Latex packages
if [ "${LATEX_VER_NUM}" == "basic" ]; then
	DPKG_DEPENDS="texlive-fonts-recommended texlive-latex-base texlive-latex-extra \
	    texlive-latex-recommended"
else
	DPKG_DEPENDS="texlive-full"
fi

# Load helper functions
source "${BASEDIR}/library.sh"

# Latex: Install
# ------------------------------------------------------------------------------
# We need to install the packages defined at ${DPKG_DEPENDS} which is a basic
# installation of latex.

msginfo "Installing tools and upgrading image ..."
cmdretry apt-get update
cmdretry apt-get -d upgrade
cmdretry apt-get upgrade
cmdretry apt-get install -d ${DPKG_DEPENDS}
cmdretry apt-get install ${DPKG_DEPENDS}

# Bash: Changing prompt
# ------------------------------------------------------------------------------
# To distinguish images.

cat >> "/etc/bash.bashrc" << 'EOF'

PS1="[\u@\h]:\w\$ "
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