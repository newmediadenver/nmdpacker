# vi: ft=ruby

require 'thor'
require 'fileutils'
require 'timeout'
require 'berkshelf/thor'
require 'berkshelf/cli'
require 'rubygems'
require 'bundler/setup'
require 'aws-sdk'

class Nmd < Thor

  desc "beep", "beep"
  def beep
    Dir.chdir '.' do
        # If the latest commit doesn't match the commit at the the tag then call it latest.
        tag = `git describe --abbrev=0 --tags`.gsub("\n","")
        tag_hash = `git show-ref --tags -d | grep #{tag}\^\{\} | awk '{print $1}'`.gsub("\n","")
        latest_hash = `git rev-parse HEAD`.gsub("\n","")
        if latest_hash != tag_hash 
          say("Stuff", :green)
        end

        say("#{latest_hash} #{tag} at #{tag_hash}", :white)
    end
  end

  desc 'validate', "Validate all the packer templates in servers directory."
  def validate
    templates = Dir.glob("servers/*.json")
    templates.each do |template|
      unless system "packer validate #{template}"
        say("#{template} is invalid.", :red)
        fail "#{template} is invalid."
      else
        say("#{template} is valid.", :green)
      end
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

  desc 'upload', "s3: Upload built boxes to the designated bucket."
  option :vmware, :type => :boolean, :desc => "Upload the vmware images instead of the virtualbox ones."

  def upload
    s3 = gets3
    bucket_name = "nmd-virtualbox"
    bucket_name = "nmd-vmware" if options[:vmware]
    begin
      bucket = s3.buckets.create(bucket_name)
    rescue Exception=>e
      bucket = s3.buckets[bucket_name]
    end
    bucket.acl = :public_read

    Dir.chdir '.' do
      boxes = Dir.glob('./builds/virtualbox/*.box')
      boxes = Dir.glob('./builds/vmware/*.box') if options[:vmware]
      say("Nothing to upload.", :green) if boxes.empty?

      boxes.each do |box|
        # @TODO: What if there are no tags
        tag = `git describe --abbrev=0 --tags`.gsub("\n","")
        tag_hash = `git show-ref --tags -d | grep #{tag}\^\{\} | awk '{print $1}'`.gsub("\n","")
        latest_hash = `git rev-parse HEAD`.gsub("\n","")

        # If the latest hash doesn't match the tag hash then call it latest.
        tag = "latest" if latest_hash != tag_hash

        # Add the tag to the target name.
        target_name = box.split("/").last
        target_name = target_name.gsub(/(.*).box/, "\\1-#{tag}.box")

        say("Setting tag to #{tag}.", :white)
        say("Uploading #{box} to the #{bucket_name} #{target_name} (this could take some time) ...", :white)

        object = bucket.objects.create(target_name, Pathname.new(box))
        object.acl = :public_read
        say(object.public_url, :green)
      end
    end

  end

  desc "delete [BUCKET_NAME, OBJECT_NAME]", "s3: Delete an object or a bucket (and it's objects)."
  def delete(bucket_name, object_name=nil)
    s3 = gets3
    bucket = s3.buckets[bucket_name]
    if bucket.exists?
      if object_name.nil?
        bucket.delete!
        verify_delete = ask("Are you sure you want to delete #{bucket_name} and it's contents (Y/N): ")
        say("Removed the #{bucket_name} bucket and it's contents.", :green)
      else
        obj = bucket.objects[object_name]
        if obj.exists?
          obj.delete
          say("Removed #{object_name} from #{bucket_name}.", :green)
        else
          say("#{object_name} does not exist in #{bucket_name}.", :red)
        end
      end
    else
      say("Could not find a bucket named #{bucket_name}.", :red)
    end
  end

  desc 'build', "Build a base vagrant box from chef cookbooks."
  option :os, :banner => "<os>", :default => "*", :desc => "ex: centos"
  option :ver, :banner => "<version>", :default => "*", :desc => "ex: 5.10"
  option :bits, :banner => "<bits>", :desc => "ex: x86_64"
  option :variant, :banner => "<variant>", :default => "base", :desc => "example: base, lamp, etc."
  option :only, :banner => "<only>", :desc => "Typically virtualbox-iso or vmware-iso"
  option :box, :type => :boolean, :desc => "Adds the new box to your local vagrant."
  option :upload, :type => :boolean, :desc => "Uploads the box to s3."

  def build
    Dir.chdir '.' do
      system "rm -f ./Berkshelf.lock"
      invoke("berkshelf:install", [], path: "./.berkshelf/cookbooks", berksfile: "./Berksfile")
      FileUtils.rm_rf(Dir.glob('./packer-*'))

      if options[:bits]
        processor = options[:bits] == "64" ? "{amd64,x86_64}" : "i386"
      else
        processor = "*"
      end

      templates = Dir.glob("servers/#{options[:os]}-#{options[:ver]}-#{processor}-#{options[:variant]}.json")


      if options[:only]
        templates.each do |template|
          system "packer build -only=#{options[:only]} #{template}"
        end
      else
        templates.each do |template|
          system "packer build #{template}"
        end
      end

      if options[:box]
        Dir.glob('./builds/virtualbox/nmd*').each do |template|
          box_name = template.match(/(nmd.*).box/).captures[0]
          system "vagrant box remove #{box_name}"
          system "vagrant box add #{box_name} #{template}"
        end
      end

      if options[:upload]
        upload
      end

    end
  end
  no_commands do
    def gets3
      %w{ AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_REGION }.each do |key|
        raise "Set an environment variable for #{key}" if ENV[key].nil?
      end
      AWS::S3.new
    end
  end

end
