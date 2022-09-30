# edname

edname is a simple utility that helps you rename files and directories with the help of your favorite text editor!

## Install

`sudo make install`

You should also check your [$EDITOR](https://bash.cyberciti.biz/guide/$EDITOR_variable) environment variable and set up your `.bashrc` according to your preference.
You may also consider installing [trash-cli](https://github.com/andreafrancia/trash-cli).

## Usage

`edname .`

A list of files in your current directory will pop up in `$EDITOR`(vi if unset).
Once you make changes and close the editor, each directory path and filename will be recreated.
It is important that you don't add or delete lines from the file, each line corresponds to the original filepath.
You can easily rename not just files but also folders, and create or delete new folders on the fly.
You can even swap filenames as easily as swapping one line of text for another.

## How it works

The script:
* Creates a hardlinked backup directory of all files/folders in the target path
* Presents `$EDITOR` a list of filepaths in the target path
* Removes all filepaths from the target
* Copies all files in the backup directory using to the target path using their new names, recreating directories as necessary
* Finally, it keeps the backup either in the target directory itself or in your trashcan if [trash-cli](https://github.com/andreafrancia/trash-cli) is installed.

## Warnings

If the directories have any special permissions, they **will be lost** as the directories are simply recreated with `mkdir -p`.
If there are empty directories they **will be lost**.
If the filepaths include very special characters such as newlines it is possible the script will break.
The script is carefully written to restore the backup on any kind of error.
Still, I am not responsible for any data loss that may occur.

It is best to use this on "normal" file trees that are not huge (it would be a very bad idea to call `edname /`).
If you make a mistake use `ctrl-c` or purposefully add lines to the editor window so it errors out before removing files (a check ensures the line count is the same). 

This software is provided as-is without warranty.
See [LICENSE](LICENSE) for details.

## TODO

* Restore empty directories
* Restore directory permissions where possible
* Support deleting files
