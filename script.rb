require 'nokogiri'
require 'redcarpet'
require 'colorize'
require 'open-uri'
require 'uri'
require 'dotenv'
require 'aws-sdk'

Dotenv.load

POSTS_PATH = "/vagrant_data/diacode-website/source/blog"
bucket = Aws::S3::Resource.new.bucket(ENV['S3_BUCKET'])

Dir.glob("#{POSTS_PATH}/*.markdown") do |md_file_path|
  md_file_content = File.read(md_file_path)

  # matches = md_file_content.scan(/(https?:\/\/blog\.diacode\.com\/wp-content\/uploads\/.*\.(jpg|jpeg|png|gif))/i)
  matches = md_file_content.scan(/(https?:\/\/([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?)/i)
  
  matches.select! do |e|
    e[0].include?("blog.diacode.com/wp-content/uploads/") &&
    e[0].match(/\.(jpg|jpeg|png|gif)$/)
  end

  matches = matches.map { |e| e[0] }

  if matches.size > 0
    puts "Se han encontrado #{matches.size} imagenes en #{File.basename(md_file_path)}"
    
    matches.each do |match|
      image_url = match
      puts "Ocurrencia: #{image_url}".colorize(:green)
      puts "Descargando imagen #{image_url}..."

      uri = URI.parse(image_url)
      image_name = File.basename(uri.path)
      tmp_image_path = "/tmp/#{image_name}"
      
      open(tmp_image_path, 'wb') do |file|
        file << open(image_url).read
      end

      # Using same year/month structure as wordpress
      date_matches = image_url.scan(/blog\.diacode\.com\/wp\-content\/uploads\/([0-9]{4})\/([0-9]{2})\/.*/i)
      year = date_matches[0][0]
      month = date_matches[0][1]

      puts "Subiendo imagen #{image_name} a AWS S3..."
      object = bucket.object("#{year}/#{month}/#{image_name}")
      object.upload_file(tmp_image_path, acl: 'public-read')

      puts "Reemplazando ocurrencias..."
      md_file_content = md_file_content.sub(image_url, object.public_url)
    end

    File.open(md_file_path, 'w') do |file|
      file.puts md_file_content
    end
  end
end
