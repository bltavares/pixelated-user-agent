#!/bin/bash
#
# Copyright (c) 2014 ThoughtWorks, Inc.
#
# Pixelated is free software: you can redistribute it and/or modify

# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Pixelated is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Pixelated. If not, see <http://www.gnu.org/licenses/>.

set -x
set -e

PACKAGE_VERSION="$1"
BUILD_PATH=/tmp/pix-user-agent-build
PIXELATED_LIB_PATH=$BUILD_PATH/var/lib/pixelated
PIXELATED_VIRTUALENV_PATH=$PIXELATED_LIB_PATH/virtualenv

# create build folder
[[ ! -d "$BUILD_PATH" ]] && mkdir $BUILD_PATH
rm -rf $BUILD_PATH/*

# create internal folders
mkdir -p $PIXELATED_LIB_PATH

# build web-ui code
cd web-ui
bundle install --path=~/pixelated-gems
npm install
node_modules/bower/bin/bower install
./go package
cd ..

# build virtual env
cd service
virtualenv $PIXELATED_VIRTUALENV_PATH
. $PIXELATED_VIRTUALENV_PATH/bin/activate
pip install --upgrade pip
pip install --upgrade setuptools
python setup.py install
pip uninstall -y scrypt
pip install scrypt
deactivate

cd $PIXELATED_VIRTUALENV_PATH
for file in $(grep -l '/tmp/pix-user-agent-build' bin/*); do 
        sed -i 's|/tmp/pix-user-agent-build||' $file;
done
cd -
cd ..

cd $BUILD_PATH
[[ ! -f '/tmp/gems/bin/fpm' ]] && GEM_HOME=/tmp/gems gem install fpm
GEM_HOME=/tmp/gems /tmp/gems/bin/fpm -s dir -v ${PACKAGE_VERSION} -t deb -n pixelated-user-agent -C . .
