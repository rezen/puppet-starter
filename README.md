# puppet
Puppet is a handy-dandy tool to help your provision your servers in a consistent and reliable manner! 
It is powered by ruby and uses a custom template language to create specs for installing and 
configuring your box. This guide is to help you get up and running!

You can use puppet with a **master -> agent** or **masterless**. With a **master -> agent** setup, all the modules and
manifests are stored on the **puppet-master** from which the **agent** can request the manifests from.

## Install
The steps below are for setup in master, masterless or testing environments. 
Setting up an agent involves slightly different steps.
```bash
yum install -y git puppet gpg
gem install r10k librarian-puppet puppet-lint

# The default directory for puppet conf
cd /etc/puppet

# Make sure is production
puppet config print environment

# Use r10k to setup environments & install modules
r10k deploy environment -p

# Should list modules from /etc/puppet/modules:/etc/puppet/modules-external
puppet module list
```

## Notables
- `hiera.yaml` Config for using hiera with puppet
- `puppet.conf` The primary puppet config
- `Puppetfile` Used by `librarian-puppet` and/or `r10k` as spec of modules & versions of to install
- `r10k.yaml` If you are using r10k
- `hierdata/` Location of hiera yaml configs
- `modules/` Default location of custom modules

### Usage
##### master -> agent
With a master & agent setup you need to configure the agent to point to 
the puppet master's address in it's `puppet.conf`. I won't go into detail because there 
are lots of guides out there that already do a fantastic walkthrough of the setup. 
I included a few links below but here is the summary of the steps.

- Setup master
  - Install puppet
  - Install deps
  - Use `r10k` to get environments filled
  - Setup certs
- Setup agent/s
  - Install puppet
  - Configure to point to master
  - Setup & start puppet service
- On master sign agent cert
- Provision!

###### Guides
- https://docs.puppet.com/puppet/3.8/reference/post_install.html#configure-a-puppet-agent-node
- https://www.digitalocean.com/community/tutorials/how-to-install-puppet-to-manage-your-server-infrastructure



```bash
# Run on the agent
puppet agent -t

# ... Install for specific environment
puppet agent -t --environment dev_firewall
```

##### masterless
There aren't really additional steps to setting up a masterless setup, just provision away!

```bash
puppet apply environments/production/manifests/site.pp --debug

# Install with specific configs
puppet apply --hiera_config=./hiera.yaml  --modulepath=./modules:./modules-external ./manifests/site.pp --debug
```


## Tips
- Always have `puppetlibs/stdlib` module installed!
- Make sure in `puppet.conf` to set `environmentpath`
- `puppet-lint` is your friend!
- Print config for specific environment<br />
  `puppet config print modulepath --environment production`
- `puppet apply -e 'notify { "Execute inline!" : }'"`
- `puppet describe --list` To see available resources
- ` puppet describe package`
- Includes `facter` with installer which gives system info
- `puppet facts find yaml`
- `facter os.family` maps to `$facts['os']['family']` in modules/manifests
- `puppet apply --ordering=random` To test if your module is ordering safe
- If you don't use `r10k` you can `librarian-puppet install --path /etc/puppet/modules-external/`
- `puppet resource package` Show installed packages

### Overriding Configs
One issue I ran into was a community module I was using defined a file that I wanted to overwrite.
Since I couldn't redefine the file, I needed a way to adjust the content. You have to the *careful
because with the examples you overwrite all previous adjustments.

**Same module**  
```puppet
# For changing definitions in same module
file {'module.conf':
  ensure => file,
}

# ... I can adjust properties later
File['module.conf'] {
  owner => 'www-data',
}
```

**Separate module**  
```puppet
# For changing definitions in another module
include othermodule

File <| title == "module.conf" |> {
  content => template('mymodule/setenv.sh.erb'),
}
```
- https://docs.puppet.com/puppet/2.7/lang_resources.html#amending-attributes-with-a-collector
- https://serverfault.com/questions/438658/how-to-extend-a-file-definition-from-an-existing-module-in-the-node

## Modules
Modules encapulate functionality & definitions of resources for specific installations and/or configurations. For example, `puppetlabs/mysql` includes everything you need to install mysql, configure, add users, create databases, etc.

With Puppet, community modules are a big perk! You can search the modules on https://forge.puppet.com. Before writing your own module from scratch, make sure to check if there is already an existing one you can use.

If you use community modules mixed with your own, make sure to separate them out. I like to separate with `modules` and `modules-external`. With `librarian-puppet` you can manage your modules and use a `Puppetfile` to configure your required modules.

#### Structure
```
/module-name/
|-- examples
|-- facts.d
|-- files
|   `-- name.conf
|-- lib
|   `-- puppet
|       |-- provider
|       `-- type
|-- manifests
|   |-- config.pp
|   |-- init.pp
|   `-- services.pp
|-- spec
|-- templates
`-- manifest.json
```
The manifests directory is a big part of modules, with `init.pp` being the primary declaration of the module. The manifests directory filenames map to namespaces within the module directory.

###### Example
- `manifests/config.pp` => `class module-name::config {}`
- `manifests/init.pp` => `class module-name {}`
- `manifests/services.pp` => `class module-name::services {}`

Example with `module-name/manifests/config.pp`

```puppet
class module-name::config {
  package { 'module-name': }
  # ...
}
```

#### Resources
- https://www.devco.net/archives/2012/12/13/simple-puppet-module-structure-redux.php
- https://docs.puppet.com/guides/module_guides/bgtm.html
- http://elatov.github.io/2014/09/writing-better-puppet-modules/
- http://www.example42.com/tutorials/PuppetTutorial/#slide-10
- http://fullstack-puppet-docs.readthedocs.io/en/latest/puppet_modules.html
- http://www.slideshare.net/PuppetLabs/puppetcamp-module-design-talk-45084826
- http://www.morethanseven.net/2014/02/05/a-template-for-puppet-modules/
- http://www.slideshare.net/PuppetLabs/whatnottodo
- https://www.digitalocean.com/community/tutorials/getting-started-with-puppet-code-manifests-and-modules

## Environments
Puppet uses environments to help determine what manfists/configurations needs to run. By default puppet uses the production environment and the corresponding modules & manifests.  To view the existing environment configuration use `puppet config print | grep env`.

You configure `environmentpath` in `puppet.conf`.

When using puppet commands, to specify another environment, you can use the flag `--environment=dev`.

#### Structure
When you peek in the directory configured as the `environmentpath` it should look like this.
```
/environments/
|-- production
|   |-- hieradata
|   |-- manifests
|   |-- modules
|   |-- environment.conf
|   `-- puppet.conf
|-- dev/
|    |-- hierdata
|    ` ..
`-- other
    |-- hierdata
    `..
```


#### r10k
This tool allows you to use git to manage your environments with git and maps your branch names to environment directories. For example if you have a branch named `dev` in your repo, when you use `r10k`, it will setup your modules/manifests etc in the `$environmentpath/dev/` directory.

The easiest way to use & manage r10k is have your `/etc/puppet` directory set as git repo. You can make a branch per environment and have changes that are targed to that branch


```shell
$ cd /etc/puppet
$ git branch
    dev
  * dev_firewall
    master
$ ls /etc/puppet/environments
dev  dev_firewall  master
```

###### Usage
`r10k deploy environment -p`


## Hiera
TODO
```bash
yum install -y ruby-dev make
gem install hiera-eyaml hiera-eyaml-gpg ruby_gpg gpgme
```
Heira allows you to more effectively extract configuration detail into config files instead of manifests.


## Agents
TODO
`puppet secret_agent` For testing agent?



#### Resources
- https://puppet.com/blog/encrypt-your-data-using-hiera-eyaml
- https://github.com/sihil/hiera-eyaml-gpg
- https://blog.benroberts.net/2014/12/setting-up-hiera-eyaml-gpg/
- https://docs.puppet.com/hiera/3.2/puppet.html
- https://www.safaribooksonline.com/blog/2013/07/26/managing-your-hiera-data/

## Links
Misc. links and hiera and/or masterless puppet.
- https://adamcod.es/2016/04/08/introduction-to-puppet.html
- http://lzone.de/cheat-sheet/Puppet
- https://github.com/puppetlabs/r10k
- https://github.com/olindata/awesome-puppet
- http://terrarum.net/blog/puppet-infrastructure-with-r10k.html
- https://www.jethrocarr.com/2016/01/23/secure-hiera-data-with-masterless-puppet/
- https://techpunch.co.uk/development/how-to-build-a-puppet-repo-using-r10k-with-roles-and-profiles
- http://garylarizza.com/blog/2014/02/17/puppet-workflow-part-2/
- https://puppet.com/resources
- https://mestachs.wordpress.com/tag/puppet/

##### Tools
Tools that make your puppeteer life better!
- https://github.com/mschuchard/puppet-check
- https://github.com/binford2k/hiera_explain
- http://puppet-lint.com/

##### Masterless
- https://www.digitalocean.com/community/tutorials/how-to-install-puppet-in-standalone-mode-on-centos-7
- https://inside.mygov.scot/2015/11/24/masterless-puppet/
- https://www.braintreepayments.com/blog/decentralize-your-devops-with-masterless-puppet-and-supply-drop/
- https://www.youtube.com/watch?v=k7kyyx6q0oe
- http://terrarum.net/blog/masterless-puppet-with-capistrano.html
- https://www.unixmen.com/setting-masterless-puppet-environment-ubuntu/
- https://puppet.com/presentations/de-centralise-and-conquer-masterless-puppet-dynamic-environment
- https://www.digitalocean.com/community/tutorials/how-to-set-up-a-masterless-puppet-environment-on-ubuntu-14-04
- http://www.slideshare.net/puppetlabs/puppetconf-2014-1


