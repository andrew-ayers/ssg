#!/bin/bash
#
# Bash Static Site Generator v1.0.0
#
# Copyright (c) 2020 by Andrew L. Ayers
#
# Fork it: https://github.com/andrew-ayers/ssg
#
# This is free software; see the source and/or git repository for copying 
# conditions. There is no warranty, not even for merchantability or fitness 
# for a particular purpose.
#
################################################################################
#
# License:
#
# Unless otherwise specified, all code is licensed as GPLv3:
#
# http://www.gnu.org/licenses/gpl-3.0.en.html
#
# Copyright (C) 2020 by Andrew L. Ayers
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3 of the License, or (at your option) any later 
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT 
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with 
# this program; if not, write to the Free Software Foundation, Inc., 51 Franklin 
# Street, Fifth Floor, Boston, MA 02110-1301  USA
#
################################################################################

# Get the name of the script
script_name=`basename "$0"`

# Version information
version_info="v1.0.0"

# Initialize various flags for command line options
do_browser=0
do_server=0
do_publish=0
do_buildall=0
do_verbose=0

# Initialize various user-definable system variables
DIR="$(dirname "$(readlink -f "$0")")"

source "$DIR/settings.sh"

################################################################################

usage () {
    clear
    echo
    echo "usage: $script_name [-ba | --buildall] [-p | --publish] [-b | --browser] [-s | --server]"
    echo "       [-vr | --version] [-v | --verbose] [-h | --help]"
    echo
    echo "  -ba or --buildall  build all pages (including about, resume, and contact)"
    echo "  -p  or --publish   publish the generated site to remote server"
    echo "  -b  or --browser   start browser ($browser @ $local)"
    echo "  -s  or --server    start local webserver ($server)"
    echo "  -vr or --version   show the version infomation"
    echo "  -v  or --verbose   show verbose output (note: errors are always shown)"
    echo "  -h  or --help      show usage information"
    echo
    echo "If no parameters are passed, ssg will run as if the -ba -b -s parameters were passed"
    echo
    echo "If only the -v or --verbose parameters is passed, ssg will run as if the -ba -b -s -v"
    echo "parameters were passed"
    echo
    exit 1
}

version () {
    clear
    echo
    echo "Bash Static Site Generator $version_info"
    echo "Copyright (c) 2020 by Andrew L. Ayers"
    echo "https://github.com/andrew-ayers/ssg"
    echo
    echo "This software is licensed as GPLv3:"
    echo
    echo "http://www.gnu.org/licenses/gpl-3.0.en.html" 
    echo
    echo "See the included LICENSE.md file and/or git repository for"
    echo "copying conditions and information. There is no warranty, not"
    echo "even for merchantability or fitness for a particular purpose."
    echo
    exit 1
}

out () {
    if [ "$do_verbose" == "1" ]; then
        echo ${1%}
    fi
}

start_server () {
    out "Restarting local webserver ($server)"
    killall -q $server; $server $server_options &
}

start_browser () {
    out "Starting browser session"

    if [ "$do_verbose" == "1" ]; then
        $browser "$local"
    else
        # Use nohup to silence output per https://stackoverflow.com/a/33673112
        nohup $browser "$local" >/dev/null 2>&1
    fi    
}

backup_site () {
    if [ ! -d $backuppath ]; then
        out "Backup directory created."
        mkdir $backuppath
    fi

    out "Creating site backup"
    tar -czf "$backuppath/site_`date +%Y%m%d_%H%M%S`.tar.gz" .
    
    out "Backup completed"
}

publish_site () {
    if [ ! -d "$temppath" ]; then
        echo "Temporary build directory does not exist - site not published"
        return 1
    else
        out "Creating site gzip archive"
        tar -czf "$temppath/site.tar.gz" .

        if [ -f "$temppath/site.tar.gz" ]; then
            out "Verifying remote server upload path"
            
            ssh -q "$ssh_login" "test -e $scp_path"

            if [ $? -eq 1 ]; then
                echo "Unable to find remote server upload path - site not published"
                do_temp_cleanup
                return 1
            fi

            out "Uploading gzip archive to remote server"
            scp "$temppath/site.tar.gz" "$ssh_login:$scp_path/site.tar.gz"

            if [ $? -eq 0 ]; then
                out "Uncompressing gzip archive on remote server"
                ssh "$ssh_login" "cd $scp_path; tar -xzf site.tar.gz && rm site.tar.gz"
                out "Site published to remote server"
            fi
        else
            echo "Site gzip archive not found in build directory - site not published"
            do_temp_cleanup
            return 1
        fi
    fi

    do_temp_cleanup

    return 0
}

do_temp_cleanup () {
    out "Cleaning up local temp directory"
    
    if [ -e "$temppath/site.tar.gz" ]; then
        rm "$temppath/site.tar.gz"
    fi
    
    out "Cleanup completed."
}

initialize () {
    out "Initializing generator"

    # Backup the site first
    backup_site

    # Delete root README.md
    if [ -e README.md ]; then
        rm README.md
    fi

    # Delete all tag markdown files, or create empty tags folder
    if [ -d "./tags" ]; then
        if [ -e "./tags/*.md" ]; then
            rm "./tags/*.md"
        fi
    else
        mkdir "./tags"
    fi
}

build () {
    local dir=${1%}
    local template=${2%}
    local output=${3%}

    pandoc -s "./$dir"README.md --template="resources/templates/$template" -o "./$dir"$output
}

build_articles () {
    local articles=`ls -dt */ | egrep -v "$exclusions"`

    for path in $articles; do
        if [ -e "$path"README.md ]; then
            
            out "Building article content node $path"
            build_article_components $path
            build_root_readme $path

            rm "$path"front_matter.sh

            # Reset article path mtime reference
            touch --reference="./$path"README.md "./$path"
        fi
    done
}

build_article_components () {
    local dir=${1%}

    # Build front-matter shell script
    build "$dir" article.bash front_matter.sh 

    # Build article
    build "$dir" article.html index.html
}

build_tag_md () {
    # Clean passed in tag of any extra newlines
    local tag=$(echo ${1%}|tr -d '\n')
    local dir=${2%}

    if [ ! -f "./tags/$tag.md" ]; then
        printf "\n\n<p class=\"anchor\">" >> "./tags/$tag.md"
        printf "\n<a id=\"$tag\" class=\"anchor\"></a>" >> "./tags/$tag.md"
        printf "\n</p>" >> "./tags/$tag.md"
        printf "\n<h2>$tag:</h2>" >> "./tags/$tag.md"
    fi
    
    printf "\n\n**[$fm_title](../$dir)** - *$fm_date*" >> "./tags/$tag.md"
    printf "\n\n> $fm_abstract" >> "./tags/$tag.md"
    printf "\n\n" >> "./tags/$tag.md"
}

build_root_readme_tag_line () {
    local dir=${1%}

    printf "\n\n**Tags:** *" >> README.md

    local tag=""

    for raw in $fm_tags; do
        if [ -n "$tag" ]; then
            printf ", " >> README.md
        fi

        tag=`echo $raw | sed 's/,//g'`
        
        printf "[$tag](./tags#$tag)" >> README.md

        build_tag_md "$tag" "$dir"
    done

    printf "*" >> README.md
}

build_root_readme () {
    local dir=${1%}

    source "$dir"front_matter.sh

    printf "**[$fm_title](./$dir)** - *$fm_date*" >> README.md
    printf "\n\n> $fm_abstract" >> README.md

    build_root_readme_tag_line "$dir"

    printf "\n\n----\n\n" >> README.md
}

build_home () {
    # Build home index.html
    out "Building home page"
    build "./" home.html index.html
}

build_tags () {
    if [ -d "./tags" ]; then
        if [ -e "./tags/README.md" ]; then
            rm "./tags/README.md"
        fi

        # Concatenate all tag.md files into README.md
        local break=" "
        for file in `ls -a ./tags/*.md`; do
            if [ -z "$break" ]; then
                # Add a section break line
                printf "\n\n----\n\n" >> ./tags/README.md
            fi

            cat "$file" >> ./tags/README.md

            break=""
        done

        # Delete all tag.md files, leaving README.md
        rm `ls -a ./tags/*.md | egrep -v "README.md"`

        # Build tags index.html
        out "Building tags page"
        build "./tags/" tags.html index.html
    fi
}

build_about () {
    # Build about index.html
    out "Building about page"
    build "./about/" about.html index.html
}

build_resume () {
    # Build resume index.html
    out "Building resume page"
    build "./resume/" resume.html index.html
}

build_contact () {
    # Build contact index.html
    out "Building contact page"
    build "./contact/" contact.html index.html
}

############################### DO THE NEEDFUL #################################
#
# Note: The following checks could have been done differently,
# but without the clarity I think it needed - ALA

# If no command line parameters are specified, default to "ssg.sh -ba -b -s"
if [ "$1" == "" ]; then
    do_buildall=1
    do_browser=1
    do_server=1
fi

# If the only command line parameter specified is for verbose mode,
# default to "ssg.sh -ba -b -s -v"
if [ "$1" == "-v" ] || [ "$1" == "--verbose" ]; then
  if [ "$2" == "" ]; then
    do_buildall=1
    do_browser=1
    do_server=1
    do_verbose=1
  fi
fi

# Read parameters from command line for additional actions
while [ "$1" != "" ]; do
    case $1 in
        -ba | --buildall )      do_buildall=1
                                ;;
        -p | --publish )        do_publish=1
                                ;;
        -b | --browser )        do_browser=1
                                ;;
        -s | --server )         do_server=1
                                ;;
        -v | --verbose )        do_verbose=1
                                ;;
        -vr | --version )       version
                                exit
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

initialize
build_articles
build_home
build_tags

if [ "$do_buildall" == "1" ]; then
    build_about
    build_resume
    build_contact
fi

if [ "$do_publish" == "1" ]; then
    publish_site

    if [ $? -eq 1 ]; then 
        echo "Site publishing failed"
    fi
else
    if [ "$do_server" == "1" ]; then
        start_server
    fi

    if [ "$do_browser" == "1" ]; then
        start_browser
    fi
fi

out "Done."
exit 0