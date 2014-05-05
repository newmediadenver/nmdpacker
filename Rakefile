# encoding: utf-8
#require 'foodcritic'
require 'fileutils'
require 'berkshelf/cli'
# require 'rspec/core/rake_task'
#require 'rubocop/rake_task'
require 'erb'
require 'ostruct'
# require 'chef/cookbook/metadata'
require 'aws-sdk'

def rake_tasks
  documentation = ''
  s = `rake -T`.split("\n")
  s.each do |l|
    documentation << "    #{l}\n" if l =~ /^rake/
  end
  documentation
end

desc 'Validate all the packer templates in servers directory.'
task :validate do
  templates = Dir.glob('servers/*.json')
  templates.each do |template|
    if !system "packer validate #{template}"
      puts "#{template} is invalid."
    else
      puts "#{template} is valid."
    end
  end
end

desc '"clean[iso|box|all]" - downloaded iso files, built virtual boxes, all.'
task :clean, :action do |t, args|
  action = args[:action]
  puts action ? "Starting action #{t} #{action}" : 'No action specified'
  case action
  when 'iso'
    FileUtils.rm_rf(Dir.glob('./packer_cache/*'))
  when 'build'
    FileUtils.rm_rf(Dir.glob('./builds/virtualbox/*.box'))
  when 'all'
    FileUtils.rm_rf(Dir.glob('./packer_cache/*'))
    FileUtils.rm_rf(Dir.glob('./builds/virtualbox/*.box'))
  end
end

desc '"upload[vmware|virtualbox]" Upload boxes to the designated s3 bucket.'

desc '"build[os|ver|bits|var|only|box|upload]" Build a base vagrant box
 from chef cookbooks. If no options are specified it will try and build all
 defined servers.
 "os: default: * ex: centos"
 "ver: default: * ex: 5.10"
 "bits: ex: x86_64"
 "var: default: base ex: base,lamp, etc"
 "only: Typically virtualbox-iso or vmware-iso"
 "box: Adds the new box to your local vagrant"
 "upload: Uploads the box to s3."'
task :build, :os, :ver, :bits, :var, :only, :box, :upload do |t, args|

  Dir.chdir '.' do
    FileUtils.rm './Berkshelf.lock', :force => true
    #invoke('berkshelf:install', [], path: './.berkshelf/cookbooks', berksfile: './Berksfile')
    FileUtils.rm_rf(Dir.glob('./packer-*'))

    if args[:bits]
      processor = options[:bits] == '64' ? "{amd64,x86_64}" : "i386"
    else
      processor = '*'
    end
    if args[:only]
      templates.each do |template|
        system "packer build -only=#{args[:only]} #{template}"
      end
    else
      templates.each do |template|
        system "packer build #{template}"
      end
    end
    if args[:box]
      Dir.glob('./builds/virtualbox/nmd*').each do |template|
        box_name = template.match(/(nmd.*).box/).captures[0]
        system "vagrant box remove #{box_name}"
        system "vagrant box add #{box_name} #{template}"
      end
    end
    if args[:upload] || upload
    end
  end
end
task :default, [:action] => :clean
