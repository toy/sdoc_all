# sdoc-all
Command line tool to get documentation for ruby, rails, gems, plugins and other ruby code in one place

## Getting Started

    sudo gem install voloko-sdoc sdoc_all
    sdoc-all <place for your documentation>; cd <place for your documentation>
    <your favorite editor> config.yml
    rake run

## config.yml

### example

    ---
    min_update_interval: 1 hour
    sdoc:
    - ruby: 1.8.7
    - rails
    - gems:
        exclude:
        - mysql
        - rails
        - actionmailer
        - actionpack
        - activerecord
        - activeresource
        - activesupport
    - plugins: ~/.plugins
    - path: ~/some/path

### options

time to skip updates (for now ruby and plugins are updated)
days, hours, minutes, seconds accepted

    min_update_interval: 1 hour

title of resulting page

    title: "full reference"

list of things you want to document
carefully watch indent - 4 spaces for options

    sdoc:

### ruby

ruby 1.8.6 source will be downloaded for you from ftp.ruby-lang.org and placed in folder sources

    - ruby: 1.8.6

to auto detect ruby version pass `ruby binary` instead of version (this binary will be asked to execute `print "#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}"`)

    - ruby: `ruby`
or

    - ruby: `/usr/bin/ruby`

or

    - ruby: `/usr/bin/env ruby`

…

if you don't want updates use this

    - ruby:
        version: 1.8.6
        update: false

also as ruby has no index page, you can create folder with index.html in it (also there can be stylesheets, images or whatever you want but they should be linked relatively; I choose http://www.zenspider.com/Languages/Ruby/QuickRef.html :) ) and put path to it in config like

    - ruby:
        version: 1.8.6
        index: ruby_quick_ref

to build stdlib documentation for every group not fully present in ruby documentation (based on http://stdlib-doc.rubyforge.org)

    - ruby:
        version: 1.8.6
        stdlib: true

to integrate stdlib to main ruby documentation use

    - ruby:
        version: 1.8.6
        stdlib: integrate

### rails

choose rails version

    - rails: 2.3.2

latest installed version will be used

    - rails

### gems

document all gems

    - gems

document nokogiri and hpricot gems

    - gems: [nokogiri, hpricot]

document nokogiri gem (gem is just an alias to gems)

    - gem: nokogiri

document all installed versions of nokogiri and hpricot gems (not latest)

    - gems:
        only: [nokogiri, hpricot]
        versions: all

document all gems except mysql and gems related to rails

    - gems:
        exclude:
        - mysql
        - rails
        - actionmailer
        - actionpack
        - activerecord
        - activeresource
        - activesupport

### plugins

document plugins in folder ~/.plugins (they will also be updated if they are under git)

    - plugins: ~/.plugins

document plugins in folder sources/plugins

    - plugins

document only dump plugin

    - plugin:
        path: ~/.plugins
        only: dump

document dump, access and data_columns plugins

    - plugins:
        path: ~/.plugins
        only: [dump, access, data_columns]

don't update plugins under git

    - plugins:
        path: ~/.plugins
        update: false

document all plugins except acts_as_fu and acts_as_bar

    - plugins:
        path: ~/.plugins
        exclude: [acts_as_fu, acts_as_bar]

### paths

document file or directory (you can create .document file in directory to tell rdoc what to document)

    - path: ~/lib/bin

it can be a glob (each entry will be documented separately)

    - paths: ~/lib/*

or array (note that name of documentation for each will be relative path from common ancestor)

    - paths: [~/lib/*, ~/scripts/**, /test.rb, /rm-rf.rb]

if you want to specify more options (roots are not globed in this form)

    - paths:
        root: ~/lib/app
        main: README
        paths: [+*, +lib/*.rb, +tasks/*.rake, -*.sw*, -OLD_README]

or array form (mixed type)

    - paths:
      - root: ~/lib/app
        main: SUPAREADME
        paths: [+*, +lib/*.rb, +tasks/*.rake, -*.sw*, -OLD_README]
      - ~/lib/app2
      - root: ~/lib/app3
        main: SUPAREADME
      - root: ~/lib/app3
        paths: *.rb
      - ~/lib/old/app*

## Copyright

Copyright (c) 2010 Ivan Kuchin. See LICENSE.txt for details.
