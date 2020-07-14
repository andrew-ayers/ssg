# Bash Static Site Generator v1.0.0 #

SSG is a "static site generator" written in Bash, with a few external references to various required utilities (pandoc being chief among them) needed in order to build a site using Markdown files. It was originally based on [this example](https://skilstak.io/building-an-ssg-with-pandoc-and-bash/).

I wasn't able to get the code in the example to work as-is, but it did inspire me to play around with it, and ultimately led to me to create this tool. This tool, of course, isn't unique; it was written primarily for generating my own website, and I hope it may come in handy for others, or at least serve as a template for others to learn from or build upon. If you come up with anything useful or interesting, let me know!

### Installation and Usage ###

1. Download (and extract) or clone the repo to a desired folder
2. Install the following dependencies:

   * caddy - local web server (user-definable)
   * chromium-browser - local web browser (user-definable)
   * gzip - compression for tar file (uploaded to remote server)
   * nohup - for silencing browser startup output when not in verbose mode
   * pandoc - what actually builds the html files from the markdown/templates
   * readlink - for script base path retrieval
   * scp - secure copy to upload tar.gz file to remote server
   * sed - stream editor (used for a search/replace operation for tags)
   * tar - archives files of static site (for upload to remote server)

3. Note that you can re-define your own local web server and browser to fit your needs; see System Variables below for details
4. Set the `ssg.sh` file to be executable (`chmod +x ssg.sh`)
5. Make sure the script location is in your path
6. Run the script to display how to use it (`ssg.sh --help`)
7. Switch to the example folder (`cd .\example`) and you will find a set of folders and `README.md` files for a simple static site. You can run the generator in this folder (via `ssg.sh`) to build the example site

**WARNING:** In order for a site to be generated properly, the static site generator (`ssg.sh`) must be run within the root level folder of the static site, which contains the needed folders and files for the build to succeed. Running the generator inside any other folder is ***not reccommended*** and ***may result in data loss.***

### System Variables ###

A set of user-defined system variables needs to be created in a file named `settings.sh`. Create this file in the same folder path of the generator, and paste in the following lines of code, then save it:

    # Path to temporary folder (eg: for tar.gz file uploaded to remote server)
    temppath="/tmp"

    # Path to the backup folder
    backuppath="../backup"

    # Settings/options for secure copy to remote server
    ssh_login="{your login to remote server}"
    scp_path="{explicit path on remote server to your website}"

    # Settings and options for local server and browser processes
    server="caddy"
    server_options="-quiet"
    local="http://localhost:2015"
    browser="chromium-browser"

    # List of non-article content type nodes
    exclusions="about|contact|resources|resume|tags"

These variables (at a minimum ssh_login and scp_path) will need to be updated  to reflect your current server settings or preferences:

1. **temppath** - this path should point to a folder to hold temporary files created during generation process (eg: for tar.gz file uploaded to remote server)
   
2. **backuppath** - this path should point to a folder for site backup (prior to generation)
   
3. **ssh_login** - login username for ssh; assumes that your system (and the remote server) is set up to use key-based authentication
   
4. **scp_path** - explicit path on remote server that your website is served from
   
5. **server** - command line to start local web server
   
6. **server_options** - command line options / flags to pass to local web server
   
7. **local** - url for web browser access to local web server
   
8. **browser** - command line to start local browser (pointed to "local" url)
   
9. **exclusions** - a pipe-delimited set of content nodes to exclude from being run through the article node generation process. Tags are not created for excluded nodes (Note: Each node listed should be seperated by the pipe character symbol for proper parsing by the generator)

**Warning:** Remember to add `settings.sh` to your git exclusion list (ie - `.git/info/exclude` or `.gitignore`) if you intend to use git for versioning the generator, especially if you are using github, and/or if there is any sensitive login information used in the settings file.

### Backup Process ###

When the generator is run, the current version of the site is backed up to the user defined backup folder (see `settings.sh` file, above). 

Each backup file is named "site_{date}_{timestamp}"; this allows you to easily revert to an old copy of the site should it be necessary.

### Post-Generation Site Structure ###

Per the example site (included in the repo), the basic site structure after generation conforms to the following layout:

    site(root)
       ├── about
       │    ├── index.html
       │    └── README.md
       ├── article
       |    ├── 1.jpg
       |    ├── 2.jpg
       |    ├── index.html
       |    └── README.md
       ├── contact
       │    ├── index.html
       │    └── README.md
       ├── resources       
       │    ├── css
       │    |    └── site.css
       │    └── templates
       │         ├── about.html
       │         ├── article.bash
       │         ├── article.html
       │         ├── contact.html
       │         ├── home.html
       │         ├── resume.html
       │         └── tags.html
       ├── resume
       │    ├── index.html
       │    └── README.md
       ├── tags
       │    ├── index.html
       │    └── README.md
       ├── index.html
       └── README.md

The organization of the site content is mostly flat. Each folder with a 
README markdown file is considered a content node. This flat layout is meant to keep the URLs easy to use and remember, without needing anything additional like mod-rewrite or other "tricks":

    https://YOURSITE
    https://YOURSITE/contact
    https://YOURSITE/tags
    https://YOURSITE/some-article

The flatness also allows the site to grow in an unlimited way, and allowing for linking easily between the content nodes.

Both the root-level `README.md` and the index.html are automatically created by the generator at run-time; any changes made by the user will be lost when the site is re-generated. These files act as the "homepage" of the site; assuming your web server software is set up to render "index.html" when the user browses to a folder on the site.

In addition to the root-level content node, the "tags" content node is also built dynamically by the generator, and any user modification to it will also be lost when the site is re-generated. Tags are dynamically built from article content nodes. If any changes are needed to either of these node types, the generator code will need to be updated (Note: These restrictions may change in the future).

Always name the markdown files (in the content nodes) as `README.md`. This naming also allows others to access the markdown file as easily as the html files. Think of your site as a web of `README.md` files as well as of HTML files.

### Site Templates ###

Templates are special html files stored in the resources folder of the site (see the above site layout). Each serves as a "shell" for the contents of each content node. The contents are usually derived from the `README.md` file for the content node. 

Various so-called "template variables" may be defined by the user in the YAML front matter; the remaining content is placed in the `$body$` template variable. These variables in the template are replaced inline (by pandoc) during generation with their respective contents and the index.html file is built from the Markdown. They are referenced in the template by surrounding their name using the "\$" (dollar sign) symbol.

Note: There is one "special" template that shouldn't be altered by the user (unless you are sure that understand what you are doing); this template is named "article.bash". It consists of several exports to allow the generator to access the front matter of the article Markdown at generation time, for various purposes (such as tag generation).

More information about templates, variable referencing, and more may be found in the [documentation for pandoc](https://pandoc.org/MANUAL.html#templates).

### Content Nodes ###

More extensive information about content node front-matter, title blocks, and markdown may be found in the [manual for pandoc.](https://pandoc.org/MANUAL.html)

Each content node's `README.md` file consists of two sections:

1. YAML front-matter definitions ([pandoc documentation](https://pandoc.org/MANUAL.html#extension-pandoc_title_block))
2. Node content as markdown ([pandoc documentation](https://pandoc.org/MANUAL.html#pandocs-markdown))

Front-matter is defined in a YAML section, delimited by three dashes, with the YAML variable settings located in between:

    ---
    icon: 'name of an icon from a font icon set'
    title: 'Title of the Article'
    date: 'The date/time the article was published'
    tags: 'tag1, tag2, tag3, tag4'
    comments: 'Set to yes or no - if yes, show comments (not implemented)'
    abstract: 'A short sentence to say what the content is about'
    ---

Most of these settings are easy enough to understand, but a few deserve a bit more explanation:

The `icon` setting can be useful in a template to allow the addition of a custom icon or other indicator to represent a particular category for the content. For instance, if you have an article about sports, you might show an image of people playing at a sporting event, or an icon of a ball, etc. This field can be used for a name to that resource. This makes it really easy to use custom web font icons as category indicators, but you could also easily use images or other media as well.

The `date` setting can be anything you want, but it is best to keep it as short as possible, since it is used to build the tags and home page content nodes.

For example, I set mine in the format of "YYYY-MM-DD @ HH:MM:SS" (so if I want to reference April 20th of 2020 at 5:32pm, I'll set it to "2020-04-20 @ 17:32:00"). 

The `tags` setting is used for generating the tags and tags page, and also for setting SEO keywords meta tag in the article.

The `comments` setting should be set to "yes" or "no" to reflect whether on a given article you want to allow comments to be left by people coming to your site (Note: This functionality is not currently implemented for use).

After the YAML front-matter end delimeter (---), add a blank line, then write your markdown-formatted content for the node (this will be stored in the `$body$` template variable).

### Markdown Cheatsheet ###

If you are unfamiliar with the Markdown syntax, or need a refresher, a good cheatsheet can be found [here](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet).

### License ###

Unless otherwise specified, all code is licensed as [GPLv3](http://www.gnu.org/licenses/gpl-3.0.en.html) and is Copyright (c) 2020 by Andrew L. Ayers

See the `LICENSE.md` file for more information.

Also:

* If you wish to make a pull request against this repo, go for it, just know that any such request may or may not be used...
* I make no guarantees that any of the code will compile properly or work at all!
* I take no responsibility for your use or misuse of any of this code!
* Caveat emptor!

### Who do I cuss out? ###

If you notice any discrepancies or issues with this documentation, or the code, or if you just want to send me a love letter (or hate mail):

* Andrew L. Ayers - andrewa AT phoenixgarage DOT org [ [www.phoenixgarage.org](https://www.phoenixgarage.org/) ]