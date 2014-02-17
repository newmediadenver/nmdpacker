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

  desc 'validate', "Validate all the packer templates eg: ubuntu-12.04-i386.json"
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

  desc 'upload [BUCKET_NAME]', "s3: Upload built boxes to the designated bucket."
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
      puts "Nothing to upload." if boxes.empty?
      boxes.each do |box|
        puts "Uploading #{box} to the #{bucket_name} bucket (this could take some time) ..."
        object = bucket.objects.create(box.split("/").last, Pathname.new(box))
        object.acl = :public_read
        puts "#{object.public_url} (complete)"
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
        puts "Removed the #{bucket_name} bucket and it's contents."
      else
        obj = bucket.objects[object_name]
        if obj.exists?
          obj.delete
          puts "Removed #{object_name} from #{bucket_name}."
        else
          puts "Error: #{object_name} does not exist in #{bucket_name}."
        end
      end
    else
      puts "Error: Could not find a bucket named #{bucket_name}."
    end
  end

  desc 'build', "Build a base vagrant box from chef cookbooks."
  option :os, :banner => "<os>", :default => "*", :desc => "ex: centos"
  option :ver, :banner => "<version>", :default => "*", :desc => "ex: 5.10"
  option :bits, :banner => "<bits>", :desc => "ex: x86_64"
  option :only, :banner => "<only>", :default => "virtualbox-iso", :desc => "Remove this default when/if vmware works."
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

      templates = Dir.glob("servers/#{options[:os]}-#{options[:ver]}-#{processor}.json")

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
