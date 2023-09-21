#!/usr/bin/env bash

set -e

[[ $# -lt 1 ]] && prefix=$HOME || prefix=$1

version=3.27.6

# determine OS and arch
case "$OSTYPE" in
linux*)
os="linux"
arch=$(uname -m)
stub=""
ext=".tar.gz"
[[ "$arch" == "arm64" ]] && arch="aarch64";;
darwin*)
os="macos"
arch="universal"
stub="CMake.app/Contents/"
ext=".tar.gz";;
msys*)
os="windows"
arch=$(uname -m)
stub=""
ext=".zip";;
*)
echo "$OSTYPE not supported"
exit 1;;
esac

# compose URL
name=cmake-${version}-${os}-${arch}
archive=${name}${ext}
archive_path=${prefix}/${archive}
url=https://github.com/Kitware/CMake/releases/download/v${version}/${archive}

# download and extract CMake
echo "${url} => ${archive_path}"
if curl --fail --location --output ${archive_path} ${url}; then
:
else
echo "failed to download ${url}" >&2
exit 1
fi

case "$ext" in
.tar.gz)
tar -x -v -f ${archive_path} -C ${prefix};;
.zip)
unzip ${archive_path} -d ${prefix};;
*)
echo "unknown archive type ${ext}" >&2
exit 1;;
esac

# prompt user to default shell to this new CMake
export PATH=${prefix}/$name/bin:$PATH

case "$SHELL" in
*/zsh)
shell="zsh";;
*/bash)
shell="bash";;
*)
echo "please add to environment variable PATH: ${prefix}/$name/${stub}bin"
exit;;
esac

[[ -z ${shell+x} ]] || echo "please add the following line to file ${prefix}/.${shell}rc"
echo "export PATH=${prefix}/$name/${stub}bin:\$PATH"
