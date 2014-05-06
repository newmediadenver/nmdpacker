# encoding: utf-8
require 'fileutils'
require 'erb'
require 'ostruct'
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

def check_build_vars
  %w{ NMDPACKER_OS NMDPACKER_VER NMDPACKER_BITS NMDPACKER_VAR }.each do |key|
    fail "Set an environment variable for #{key} run bundle exec rake -D for
     extended detail" if ENV[key].nil?
  end
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
  puts action ? "Starting action #{t} #{action}" : 'No action specified.
  Try "rake -D" to see a list of available actions. '
  case action
  when 'iso'
    FileUtils.rm_rf(Dir.glob('./packer_cache/*'))
  when 'box'
    puts 'Deleting boxes'
    FileUtils.rm_rf(Dir.glob('./builds/virtualbox/*.box'))
    FileUtils.rm_rf(Dir.glob('./builds/vmware/*.box'))
  when 'all'
    FileUtils.rm_rf(Dir.glob('./packer_cache/*'))
    FileUtils.rm_rf(Dir.glob('./builds/virtualbox/*.box'))
  end
end

desc '"upload[vmware]" Upload boxes to the designated s3 bucket. Defaults to
virtualbox if vmware is not specified. Requires AWS_SECRET_ACCESS_KEY,
AWS_ACCESS_KEY_ID, & AWS_REGION environment variables be set.'

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

desc '"delete[BUCKET_NAME, OBJECT_NAME]" s3: Delete an object or a bucket (and
      its contents). Requires AWS_SECRET_ACCESS_KEY,AWS_ACCESS_KEY_ID, &
AWS_REGION environment variables be set.'
task :delete, :bucket_name, :object_name do |t, args|
  s3 = gets3
  bucket_name = args[:bucket_name]
  object_name = args[:object_name]
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
        puts "#{object_name} does not exist in #{bucket_name}."
      end
    end
  else
    puts "Could not find a bucket named #{bucket_name}."
  end
end

desc 'Build a base vagrant box from chef cookbooks - Requires environment variables be set -
Settings are read from the following shell environment variables.
All required variables can be set to * to build all defined servers.

 "NMDPACKER_OS: ex: OS=centos" - Required
 "NMDPACKER_VER: VER=5.10" - Required
 "NMDPACKER_BITS: ex: BITS=64" - Required
 "NMDPACKER_VAR: default: base ex: base,lamp, etc" - Required
 "NMDPACKER_ONLY: Typically virtualbox-iso or vmware-iso" - optional
 "NMDPACKER_BOX: Adds the new box to your local vagrant" - optional
 "NMDPACKER_UPLOAD: Uploads the box to s3." - optional'

task :build do
  check_build_vars

  nmdpacker_os = ENV['NMDPACKER_OS']
  nmdpacker_ver = ENV['NMDPACKER_VER']
  nmdpacker_bits = ENV['NMDPACKER_BITS']
  nmdpacker_var = ENV['NMDPACKER_VAR']
  nmdpacker_only = ENV['NMDPACKER_ONLY']
  nmdpacker_box = ENV['NMDPACKER_BOX']
  nmdpacker_upload = ENV['NMDPACKER_UPLOAD']

  Dir.chdir '.' do
    FileUtils.rm './Berkshelf.lock', force: true
    `bundle exec berks install --path vendor/cookbooks `
    FileUtils.rm_rf(Dir.glob('./packer-*'))
    if nmdpacker_bits
      processor = nmdpacker_bits == '64' ? "{amd64,x86_64}" : "i386"
    else
      processor = '*'
    end

    templates = Dir.glob("./servers/#{nmdpacker_os}-#{nmdpacker_ver}-#{processor}-#{nmdpacker_var}.json")

    if nmdpacker_only
      templates.each do |template|
        exec "packer build -only=#{nmdpacker_only} #{template}"
      end
    else
      templates.each do |template|
        puts "#{templates}"
        exec "packer build #{template}"
      end
    end

    if nmdpacker_box
      Dir.glob('./builds/virtualbox/nmd*').each do |template|
        box_name = template.match(/(nmd.*).box/).captures[0]
        exec "vagrant box remove #{box_name}"
        exec "vagrant box add #{box_name} #{template}"
      end
      Dir.glob('./builds/vmware/nmd*').each do |template|
        box_name = template.match(/(nmd.*).box/).captures[0]
        exec "vagrant box remove #{box_name}"
        exec "vagrant box add #{box_name} #{template}"
      end
    end

    if nmdpacker_upload.nil? || Rake::Task['upload'].invoke
    end
  end
end
task :default, [:action] => :clean
