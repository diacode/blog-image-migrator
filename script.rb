require 'nokogiri'
require 'redcarpet'
require 'colorize'
require 'open-uri'
require 'uri'

POSTS_PATH = "/vagrant_data/diacode-website/source/blog"

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
    folder_name = File.basename(md_file_path, ".html.markdown")
    folder_path = "#{POSTS_PATH}/#{folder_name}"
    
    puts "Creando carpeta #{folder_path}"
    Dir.mkdir(folder_path) unless Dir.exist?(folder_path)
    
    matches.each do |match|
      image_url = match
      puts "Ocurrencia: #{image_url}".colorize(:green)
      puts "Descargando imagen #{image_url}..."

      uri = URI.parse(image_url)
      image_name = File.basename(uri.path)

      open("#{folder_path}/#{image_name}", 'wb') do |file|
        file << open(image_url).read
      end

      puts "Reemplazando ocurrencias..."
      md_file_content = md_file_content.sub(image_url, "#{folder_name}/#{image_name}")
    end

    File.open(md_file_path, 'w') do |file|
      file.puts md_file_content
    end
  end
end
