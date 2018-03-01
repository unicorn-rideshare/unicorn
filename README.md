# unicorn rails

###### *Reference implementation for `provide.services` platform APIs and the `provide.network` sidechain.*

#### Getting started

These instructions are specific to setting up a local development environment on OSX. The `Dockerfile` illustrates how to setup an environment on Ubuntu 16.04 LTS. Setting up an environment on virtually any other Linux distro is likely trivial, although it has not been tested.

#### OSX

- Make sure you have [rvm](https://rvm.io/rvm/install) installed

- Open a new shell after `rvm` has been installed

- Install the appropriate ruby version using `rvm`:

  `# rvm install ruby-2.3.1`

- Install the following dependencies (note that the package names below are actually the `apt` package names):

  `# nodejs npm g++ qt5-default qt5-qmake libqt5webkit5-dev libxml2-dev libxslt1-dev libcurl4-openssl-dev libpq-dev`

- Clone this repository and ensure the project gemset has been initialized:

  `# git clone git@github.com:provideapp/unicorn.git && pushd unicorn`

- Install dependencies:

  `# gem install bundler`

  `# bundle install`

- Setup PostgreSQL database and run migrations:

  `# rake db:create`

  `# rake db:migrate`

- Run the test suite:

  `# RAILS_ENV=test rake db:create`

  `# rake`

- Run a local rails server bound to all local interfaces:

  `# rails s -b 0.0.0.0`

- OSX/homebrew troubleshooting `bundle install` failures:

  - capybara-webkit installation issues (i.e.: *"sh: qmake: command not found"*):

    `# brew install qt@5.5 && brew link --force qt@5.5`

  - Nokogiri gem installation issues (i.e.: *"An error occurred while installing nokogiri (1.7.0.1), and Bundler cannot continue"*):

    `# gem install nokogiri -v '1.7.0.1' -- --with-xml2-dir=/usr/local/opt/libxml2/include/libxml2`
