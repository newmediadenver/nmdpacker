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

def gets3
  %w{ AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_REGION }.each do |key|
    fail "Set an environment variable for #{key}" if ENV[key].nil?
  end
  AWS::S3.new
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

desc '"upload[vmware]" Upload boxes to the designated s3 bucket. Defaults to
virtualbox if vmware is not specified.'

task :upload, :vmware do |t, args|
  s3 = gets3
  bucket_name = 'nmd-virtualbox'
  bucket_name = 'nmd-vmware' if args[:vmware]
  begin
    bucket = s3.buckets.create(bucket_name)
  rescue Exception => e
    bucket = s3.buckets[bucket_name]
  end
  bucket.acl = :public_read
  Dir.chdir '.' do
    boxes = Dir.glob('./builds/virtualbox/*.box')
    boxes = Dir.glob('./builds/vmware/*.box') if args[:vmware]
    puts 'Nothing to upload.' if boxes.empty?
    boxes.each do |box|
      # @TODO: What if there are no tags
      tag = `git describe --abbrev=0 --tags`.gsub("\n","")
      tag_hash = `git show-ref --tags -d | grep #{tag}\^\{\} | awk '{print $1}'`.gsub("\n","")
      latest_hash = `git rev-parse HEAD`.gsub("\n","")
      # If the latest hash doesn't match the tag hash then call it latest.
      tag = 'latest' if latest_hash != tag_hash
      # Add the tag to the target name.
      target_name = box.split('/').last
      target_name = target_name.gsub(/(.*).box/, "\\1-#{tag}.box")
      puts "Setting tag to #{tag}."
      puts "Action #{t}: Uploading #{box} to the #{bucket_name} #{target_name} (this could take some time) ..."
      object = bucket.objects.create(target_name, Pathname.new(box))
      object.acl = :public_read
      puts "object.public_url"
    end
  end
end

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
    if args[:upload] || Rake::Task["upload"].invoke
    end
  end
end
task :default, [:action] => :clean
