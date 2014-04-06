# encoding: UTF-8

require "digest"
require "fog"
require "logger"

class TravisS3Cache
  def initialize(args)
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::DEBUG
    @storage = Fog::Storage.new({
      :provider => "AWS",
      :aws_access_key_id => args['aws_s3_key'],
      :aws_secret_access_key => args['aws_s3_secret'],
      :region => args['aws_s3_region']
    })
    @extras = args['aws_s3_extras']
    @bucket = args['aws_s3_bucket']
    @archive = args['bundle_archive']
    @lock_file = '/home/cyberswat/nmdpacker/Gemfile.lock'
    @previous_sha2 = '/home/cyberswat/nmdpacker/remote_nmdpacker-x86_64.tgz.sha2'
    @filename = "#{args['bundle_archive']}-#{`uname -m`.strip}.tgz"
    @changed = nil
  end

  def digest
    contents = File.open(@lock_file, "rb").read
    @extras.each do |extra|
      contents << extra
    end
    Digest::SHA2.hexdigest("#{contents}")
  end

  def changed?
    if @changed.nil?
      file = @storage.directories.get(@bucket).files.get("#{@filename}.sha2")
      previous_hash = file.nil? ? '' : file.body
      @logger.debug("previous_hash = #{previous_hash}")
      @logger.debug("current_hash = #{digest}")
      @changed = previous_hash == digest ? false : true
    end
    @changed
  end

  def download
    @logger.info("Downloading the cache from s3.")
    @logger.debug("Write /home/cyberswat/nmdpacker/s3_#{@filename} from s3.")
    local_file = File.open("/home/cyberswat/nmdpacker/s3_#{@filename}", "w")
    file = @storage.directories.get(@bucket).files.get(@filename)
    local_file.write(file.body)
    local_file.close
  end

  def upload
    parts = Dir.glob("/home/cyberswat/nmdpacker/#{@filename}.*").sort
    @logger.info("Performing a #{parts.length} piece multipart journey to s3.")

    part_ids = []
    response = @storage.initiate_multipart_upload @bucket, @filename, { "x-amz-acl" => "public-read" }
    upload_id = response.body['UploadId']

    parts.each_with_index do |part, index|
      part_number = (index + 1).to_s
      @logger.debug("#{part_number} #{part}")
      File.open part do |part_file|
        response = @storage.upload_part @bucket, @filename, upload_id, part_number, part_file
        part_ids << response.headers['ETag']
      end
      `rm -f #{part}`
    end
    @logger.info("Completing the multipart journey.")
    @storage.complete_multipart_upload @bucket, @filename, upload_id, part_ids

  end

  def digest_save
    @logger.info("Store digest in #{@filename}.sha2 on s3: #{digest}")
    bucket = @storage.directories.new(key: @bucket)
    bucket.files.create({
      :body         => digest,
      :key          => "#{@filename}.sha2",
      :public       => true,
      :content_type => "text/plain"
    })
  end

  def install
    @logger.info("Installing the cache.")
    @logger.debug("tar -xf s3_#{@filename}")
    `tar -xf s3_#{@filename}`
    @logger.debug("rm -f s3_#{@filename}")
    `rm -f s3_#{@filename}`
  end

  def package
    @logger.info("Creating the cache and preparing it for a multipart journey to s3.")
    @logger.debug("tar -cjf #{@filename} .bundle && split -b 5m -a 3 #{@filename} #{@filename}.")
    `tar -cjf #{@filename} .bundle && split -b 5m -a 3 #{@filename} #{@filename}.`
  end

end

state = ARGV[0].nil? ? 'before' : 'after'
cache = TravisS3Cache.new({
  'aws_s3_key' => 'AKIAIOUXGDMFHNZ6GHUQ',
  'aws_s3_secret' => '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',
  'aws_s3_bucket' => 'nmd-cache',
  'aws_s3_region' => 'us-east-1',
  'aws_s3_extras' => ['https://dl.bintray.com/mitchellh/packer/0.5.1_linux_amd64.zip'],
  'bundle_archive' => 'nmdpacker'
})

if state == 'before'
  cache.download
  cache.install
else
  cache.package if cache.changed?
  cache.upload if cache.changed?
  cache.digest_save if cache.changed?
end
exit 0
