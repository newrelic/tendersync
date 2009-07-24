# Tendersync

Authors: Markus Roberts and Bill Kayser

Tendersync allows you to sync documents stored in the 
[ENTP Tender](http://www.tenderapp.com)
`faqs` section with a local filesystem, allowing you to manage your
documents with git or subversion.

It includes a command for creating an index document for any given
section.

Find out more about Tender by visiting [the Tender site](http://www.tenderapp.com).

## Features

* List remote sections and documents under the `/faqs` area
* Pull single documents or entire tree from Tender site to local
  filesystem
* Push local changes back to Tender one at a time or en masse
* Manage document meta-data, like keywords, in headers
* Push changed versions to the server

## Synopsis

Create a working directory where you want to store the tender docs in a hierarchy
and run tendersync from there.

    sudo gem install tendersync
    cd $workdir
    tendersync -h

## Using Tendersync

To get started, you need to pass in your account information.  You
only need to do this once.  A local file `.tendersync` is created with
the configuration information.

This will get you set up:

    tendersync -u user@me.com -p password --docurl=http://company.tenderapp.com

To verify it worked run the `ls` command:

    tendersync ls

Tender documents are organized into sections defined by you.  At New
Relic, we have faqs, docs, and troubleshooting.  You can specify
commands to apply to one or more sections by passing in section names
with -s:

    tendersync -s docs -s troubleshooting pull

### Examples

Start with:

    tendersync -h

Download all your docs:

    tendersync pull 

Download just the faq docs:

    tendersync pull -s faqs

Create a git repository and save all the documents:

    git init
    git add .
    git commit -m "First version of docs on Tender"

Upload docs to the server:

    tendersync post faqs/sinatra_support
    tendersync post docs/install-*
    tendersync post -s docs

Upload everything to the server (regardless of whether the content has
changed or not):
  
    tendersync post

### Using the `index` Command

You can generate a table of contents for any section with the index
command.  By default index will generate a single file named
`SECTION_table_of_contents`.

In this file will be a list of all the files in the given section with
links to those files.  Under each file link will be a bullet list of
the topmost sections in the document.  If these sections are preceeded
by anchor links (A elements with the name attribute) then the bullets
will have links to those sections.

It will look something like this:

<pre>
  ## Installation and configuration
  ### [Agent Installation (Ruby)](agent-installation)
  * [Installing the Plug-in](agent-installation#Installing_the_Plug-in)
  * [Installing the Gem](agent-installation#Installing_the_Gem)
</pre>

#### Customizing the amount of detail in the Index

You can show sections deeper than one level in a particular document
using the `-d` option.  The default is 1.

    tendersync index -d 2

#### Definiting TOC groups

If you want to divide the table of contents into groups of related
documents, you can pass in a title for a group and a regular expression
to match against document titles that belong in that group. These group
definitions will be saved so you only need to enter them once.

Enter a group using the `-g` option passing in a title and regular
expression separated by a semi-colon.

    tendersync index -g "Page Details;/page/i"

You can add multiple groups with additional -g options:

    tendersync index -g "Page Details;/page/i" -g "Installation Info;/installation/i"

If you want to remove a group definition, you need to remove it 
manually from the `.tendersync` file.

## THANKS

All due regards, credit, thanks, etc., to the ENTP team for a great tool.

## LICENSE

Copyright (c) 2009 New Relic, Inc.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
