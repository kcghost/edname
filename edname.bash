#!/bin/bash
# Rename files in the current directory with the help of a text editor
# WARNING: Recreates directory structure, so might mess up directory permissions
set -euo pipefail

removedir="false"
target=""

help() {
	echo "$0 [-h] [-r] target"
	echo ""
	echo "-h: Display this help message"
	echo "-r: Automatically remove backup directory (dangerous!)"
	echo ""
	echo "WARNING: Use this tool at your own risk."
	echo "It tries its best to backup and restore on error, but it could still result in data loss."
	echo "It will likely break on edge case filenames and it will wipe any special directory permissions."
	echo "Best used with normal file trees without a huge number of files involved."
}

while [[ $# -gt 0 ]]; do
	case $1 in
		-h)
			help
			exit 0
		;;
		-r)
			removedir="true"
			shift
		;;
		*)
			target=${1%/}
			shift
	esac
done

if [ -z "${target}" ] || [ ! -d "${target}" ]; then
	echo "Please specifiy a target directory!"
	echo ""
	help
	exit 1
fi

# Unlink(remove) file or directory (absolute)
rma() {
	echo "Removing \"${1}\""
	unlink "${1}" || rmdir "${1}" 2>/dev/null
}
export -f rma
# Copy file to dst (relative to target), create path to destination if not existing
cpa() {
	echo "Renaming \"${1}\" to \"${2}\""
	pushd "${target}" >/dev/null
	parent=$(dirname "${2}")
	mkdir -p "${parent}"
	[ ! -f "${2}" ]
	cp -alnx "${bak}/${1}" "${2}"
	popd >/dev/null
}

# TODO: Warn about directories that don't correspond to umask, as they won't be re-created correctly
# TODO: Check we have full permissions on all files?

pushd "${target}" >/dev/null
bak=$(mktemp -d bak.XXXXXXXXXX)
popd

echo "Backing up hardlinked copy to ${target}/${bak}..."
find "${target}" -mindepth 1 -maxdepth 1 -path "${target}/${bak}" -prune -o -print0 | \
sort -z | \
xargs -0 -n 1 cp -alnx -t "${target}/${bak}"
echo "Backed up to ${target}/${bak}"
cleanup_bak() {
	echo "Removing backup copy..."
	rm -rf "${target:?}/${bak}"
}
restore_bak() {
	echo "Restoring backup copy..."
	find "${target}/${bak}" -mindepth 1 -maxdepth 1 -print0 | sort -z | \
	xargs -0 -n 1 cp -alnx -t "${target}"
}
cleanup() {
	cleanup_bak
}
trap cleanup EXIT

tmp_file=$(mktemp)
cleanup_tmp() {
	echo "Removing tmp file..."
	rm "${tmp_file}"
}

cleanup() {
	echo "Editing failed!"
	cleanup_tmp
	restore_bak
	cleanup_bak
}
echo "Opening ${EDITOR:-vi} with filepaths..."
filecount=0

#OIFS="${IFS}"
IFS=$'\n'
for file in $(find "${target}/${bak}" -mindepth 1 -type f -printf '%P\n' | sort); do
	(( filecount=filecount+1 ))
	echo "${file}" >> "${tmp_file}"
done
eval "${EDITOR:-vi} ${tmp_file}"

# TODO: Warn about not handling filepaths with newlines in them?
echo "Asserting expected line count..."
lines=$(wc -l <"${tmp_file}")
[ "${lines}" == "${filecount}" ]

remove_all() {
	echo "Removing all files and directories from target..."
	find "${target}" -mindepth 1 -path "${target}/${bak}" -prune -o -print0 | \
	sort -z -r | \
	xargs -0 -r -n 1 bash -c 'rma "$@"' _
}
remove_all

cleanup() {
	echo "Renaming failed!"
	cleanup_tmp
	remove_all
	restore_bak
	cleanup_bak
}
echo "Linking files to new locations..."
for file in $(find "${target}/${bak}" -mindepth 1 -type f -printf '%P\n' | sort); do
	IFS= read -r line
	echo "${file}"
	cpa "${file}" "${line}"
done < "${tmp_file}"

cleanup() {
	echo "Success!"
	cleanup_tmp
	if [ "${removedir}" != "true" ]; then
		if type "trash-put" > /dev/null; then
			echo "Sending backup directory to trash."
			trash-put "${target}/${bak}"
		else
			echo "Leaving ${target}/${bak}, safe to rm -rf when you verify everything was correctly renamed."
		fi
	else
		cleanup_bak
	fi
}

exit 0
