[![Stories in Ready](https://badge.waffle.io/newmediadenver/nmdpacker.png?label=ready&title=Ready)](https://waffle.io/newmediadenver/nmdpacker)
[![Build Status](https://travis-ci.org/newmediadenver/nmdpacker.svg?branch=master)](https://travis-ci.org/newmediadenver/nmdpacker)

#Newmedia Denver Base Boxes -

[Packer](http://www.packer.io/intro) is used to build the virtual machines used at newmediadenver. You can interact with this repository when you need to modify the underlying stack (eg: httpd, php, mysql) for a base box.

Platforms are defined in JSON formatted files located in the [servers/](servers/) directory.  The ```{ "provisioner": {} }``` section of the file is used to customize the installation by defining scripts to run and cookbooks to be applied. The scripts provisioner executes shell scripts stored in [scripts](scripts). The chef-solo provisioner executes a run_list of cookbooks that are managed by the [Berksfile](Berksfile).

##Initial Setup
1. Download and install the latest [VirtualBox](https://www.virtualbox.org/wiki/Downloads) or [VMware Workstation](http://www.vmware.com/products/workstation)

1. Make sure that you have the ImageMagick package installed on your system (Ubuntu: apt-get install imagemagick CentOS: yum install imagemagick) or install from [here](http://www.imagemagick.org/script/binary-releases.php).

1. Download and install [Vagrant](http://www.vagrantup.com/downloads.html).

1. Install [Bundler](http://bundler.io/)

1. Clone the nmd-packer repository.

   ```bash
   $ git clone git@github.com:newmediadenver/nmdpacker.git ~/nmd-packer
   ```

1. Change directory into the repository and perform the install.

   ```bash
   $ cd ~/nmd-packer
   $ bundle install
   ```

##Creating Boxes
1. [Rake](http://rake.rubyforge.org/) is the primary tool used execute commands and tasks within nmdpacker.  To see a list of available tasks execute bundle exec rake -D.

   ```bash
   $  bundle exec rake -D                                                                                  
    rake build
        Build a base vagrant box from chef cookbooks - Requires environment variables be set -
        Settings are read from the following shell environment variables.
        All required variables can be set to * to build all defined servers.
        
         "NMDPACKER_OS: ex: OS=centos" - Required
         "NMDPACKER_VER: VER=5.10" - Required
         "NMDPACKER_BITS: ex: BITS=64" - Required
         "NMDPACKER_VAR: default: base ex: base,lamp, etc" - Required
         "NMDPACKER_ONLY: Typically virtualbox-iso or vmware-iso" - optional
         "NMDPACKER_BOX: Adds the new box to your local vagrant" - optional
         "NMDPACKER_UPLOAD: Uploads the box to s3." - optional

    rake clean[action]
        "clean[iso|box|all]" - downloaded iso files, built virtual boxes, all.

    rake delete[bucket_name,object_name]
        "delete[BUCKET_NAME, OBJECT_NAME]" s3: Delete an object or a bucket (and
              its contents). Requires AWS_SECRET_ACCESS_KEY,AWS_ACCESS_KEY_ID, &
        AWS_REGION environment variables be set.

    rake upload[vmware]
        "upload[vmware]" Upload boxes to the designated s3 bucket. Defaults to
        virtualbox if vmware is not specified. Requires AWS_SECRET_ACCESS_KEY,
        AWS_ACCESS_KEY_ID, & AWS_REGION environment variables be set.

    rake validate
        Validate all the packer templates in servers directory.
   ```

1. Validate the JSON templates by executing the following command:

    ```bash
    $ bundle exec rake validate
    ```

1. Set the required build environment variables.  In this case nmdpacker_os,  nmdpacker_ver, & nmdpacker_bits.
    ```bash
    $ export NMDPACKER_OS="centos" NMDPACKER_VER="6.5" NMDPACKER_BITS="64"
    ```

1.Execute the build command:
```bash
    $ bundle exec rake build
```

Now, it is time to wait. The first time that this command is run, it will download the .iso file for the machine and then run through the scripts to set up the machine automatically. During this time, we recommend, relaxation, coffee, or other tasks be completed. This can take additional time depending on the internet connection.

1. When the build is complete you will have a box that can be distributed for import into Vagrant. The path to the box is visible in the output of ```bundle exec rake build```
    ```bash
    Build 'virtualbox-iso' finished.

    ==> Builds finished. The artifacts of successful builds are:
    --> virtualbox-iso: 'virtualbox' provider box: builds/virtualbox/opscode_centos-5.10_chef-latest.box
    ```

##Using Boxes
In a typical setup, the base box is distributed from a url. In this example, we will target the box generated in the previous step.

1. You will need to Add a built box to vagrant. The box location can be local or remote.
    ```bash
    $ cd ~/nmd-packer
    $ vagrant box add centos510 builds/virtualbox/opscode_centos-5.10_chef-latest.box
    ```

1. Perform a one time installation of plugins for vagrant.

   ```bash
   $ vagrant plugin install vagrant-berkshelf
   $ vagrant plugin install vagrant-omnibus
   $ vagrant plugin install vagrant-vbguest
   ```

1. Use a Vagrantfile that references the box you added. An example one [exists in the newmediadenver chef repository](https://github.com/newmediadenver/chef/blob/master/Vagrantfile).

   Bring up a vagrant instance built from our base box.
   ```bash
   $ git clone git@github.com:newmediadenver/chef.git ~/nmd-chef
   $ cd ~/nmd-chef
   $ vagrant up
   ```
   You should be able to ssh into the new instance after it comes up.
   ```bash
   $ cd ~/nmd-chef
   $ vagrant ssh
   Last login: Mon Jan 01 00:00:00 2014 from 10.0.2.2
   [vagrant@localhost ~]$
   ```
   You can provision the sites you've defined for drupal.
   ```bash
   $ cd ~/nmd-chef
   $ vagrant provision
   ```

License and Author
------------------

Copyright:: 2014, NewMedia Denver

Portions of nmdpacker were adapted from [opscode's bento project](https://github.com/opscode/bento).

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Contributing
------------

We welcome contributed improvements and bug fixes via the usual workflow:

1. Fork this repository
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new pull request
