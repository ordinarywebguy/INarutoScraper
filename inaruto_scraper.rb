#####################################################################
#                                                                   #
# INarutoScraper                                                    #
#                                                                   # 
# Download your favorite manga from inaruto.net site instantly      # 
#                                                                   #
# Too busy at work to read your favorite manga? Or just too anxious #
# to get caught by your boss? Or perhaps too excited to read        # 
# and can't wait for every pages/images to load?                    #
#                                                                   #
# Now try this!                                                     # 
#                                                                   #
# @author Mitchelle Pascual <mitch.pascual@gmail.com>               # 
# $date June 19, 2011                                               #
#                                                                   #
#####################################################################

require 'rubygems'
require 'mechanize'
require 'uri'

class INarutoScraper
   attr_accessor :chapters, :mangas, :chapter_pages, :current_page_url, :chapter_images
   @@url = "http://inaruto.net"
   @@xpaths = {
      :mangas => '//select[@id="cat"]/option',
      :chapters => '//div/div/a',
      :episode_pages => '//select[@class="contentjumpddl"]/option',
      :episode_images => '//div[@class="entry-content"]/p/img'
   }

   def initialize
     @mech = Mechanize.new
   end 

   def mangas
      @mangas = Hash.new
      search(@@url, @@xpaths[:mangas]).each do |manga| 
	id = manga['value'].to_i
	if id != -1
	   @mangas[id] = manga.content
	end
      end
   end

   def show_manga_options
      @mangas.each do |id, manga|	
        puts "#{id} : #{manga}"
      end
   end

   def manga(id)
      @chapters = Array.new
      ctr = 1	
      search(@@url + '?cat=' + id, @@xpaths[:chapters]).each do |chapter|
	 url = chapter['href']

	 if "#{url}" =~ /\d/
	   @chapters.push(url)
           ctr = ctr + 1
         end
      end
   end

   def show_chapter_options
      ctr = 1	
      @chapters.each do |chapter|	
        puts "#{ctr} : #{chapter}"
	ctr = ctr + 1
      end
   end
   
   def episode(page_url_index) 
      page_url = @chapters[page_url_index.to_i-1]
      @current_page_url = page_url      
      episode_pages(page_url)
   end 

   def episode_pages(page_url)
      @chapter_pages = Array.new
      search(page_url, @@xpaths[:episode_pages]).each do |page|
	unless page.nil?
	   @chapter_pages.push(page.content)
	end
      end
   end 

   def episode_images(page_url)
      search(page_url, @@xpaths[:episode_images])
   end   

   def all_episode_images
      @chapter_images = Array.new	
      for i in (1..@chapter_pages.uniq.size)
	page_url = @current_page_url + i.to_s
   	dir = page_url.split('/').values_at(-2)
	episode_images(page_url).each do |image|	
	   @chapter_images.push(image['src']) 
        end
      end
   end

   def download_images
      puts 'Downloading images...'
      counter = 1;
      page_counter = 1;
      @chapter_images.each do |image|
         page_url = @current_page_url + page_counter.to_s
      	 dir = page_url.split('/').values_at(-2)
         ext = image.split('.').values_at(-1)

	 Dir.mkdir(dir.to_s) unless File.exists?(dir.to_s)

	 url = URI.parse(image)
	 Net::HTTP.start(url.host, url.port) { |http|
            image = http.get(image, {'Referer' => page_url})
            open("#{dir}/#{counter}.#{ext}", "wb") { |file|
               file.write(image.body)
	       counter = counter+1
	       
            }
         }	  	
         page_counter = page_counter + 1
      end
   end

   def search(url, xpath)
     begin
        page = @mech.get(url)
        page.search(xpath)
     rescue
        Hash.new
     end

   end

end

scrape = INarutoScraper.new
scrape.mangas()
scrape.show_manga_options()

puts 'enter the number of manga of choice:'
manga = gets
scrape.manga(manga)
scrape.show_chapter_options()

puts 'enter the number of chapter of choice:'
page_url_index = gets
scrape.episode(page_url_index)

puts 'do you now wish to download the whole chapter? (y/n):'
download_now = gets.chomp

if download_now == 'y'
   scrape.all_episode_images()
   scrape.download_images()
end
