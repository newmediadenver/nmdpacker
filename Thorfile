# vi: ft=ruby

require 'thor'
require 'fileutils'
require 'timeout'
require 'berkshelf/thor'
require 'berkshelf/cli'

class Nmd < Thor

  desc 'validate', "Validate all the packer templates eg: centos-5.10-x86_64.json"
  def validate
    templates = Dir.glob("servers/*.json")
    templates.each do |template|
      puts "#{template}"
      unless system "packer validate #{template}"
        fail "Validation failed!"
      end
      puts "\n"
    end
  end

  desc 'clean [WHAT]', "iso|box|all - downloaded iso files, built virtual boxes, everything"
  def clean(what)
    case what
      when "iso"
        FileUtils.rm_rf(Dir.glob('./packer_cache/*'))
      when "build"
        FileUtils.rm_rf(Dir.glob('./builds/virtualbox/*.box'))
      when "all"
        FileUtils.rm_rf(Dir.glob('./packer_cache/*'))
        FileUtils.rm_rf(Dir.glob('./builds/virtualbox/*.box'))
    end
  end

  desc 'build', "Build a base vagrant box from chef cookbooks."
  option :os, :banner => "<os>", :default => "*", :desc => "ex: centos"
  option :ver, :banner => "<version>", :default => "*", :desc => "ex: 5.10"
  option :bits, :banner => "<bits>", :desc => "ex: x86_64"
  option :only, :banner => "<only>", :default => "virtualbox-iso", :desc => "Remove this default when/if vmware works."


  def build
    Dir.chdir '.' do
      system "rm -f Berkshelf.lock"
      invoke("berkshelf:install", [], path: "./.berkshelf/cookbooks", berksfile: "./Berksfile")
      FileUtils.rm_rf(Dir.glob('./packer-centos-5.10-x86_64-virtualbox'))

      if options[:bits]
        processor = options[:bits] == "64" ? "{amd64,x86_64}" : "i386"
      else
        processor = "*"
      end

      templates = Dir.glob("#{options[:os]}-#{options[:ver]}-#{processor}.json")

      if options[:only]
        templates.each do |template|
          system "packer build -only=#{options[:only]} #{template}"
        end
      else
        templates.each do |template|
          system "packer build #{template}"
        end
      end
    end
  end

end
