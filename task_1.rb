require 'curb'
require 'nokogiri'
require 'csv'
require 'yaml'
require 'curl'

def main
  puts "Введите ссылку: "
  url = gets.chomp
  puts "Введите название файла:"
  file_name = gets.chomp
  #page = "https://www.petsonic.com/farmacia-para-gatos/"
  page_qty = get_qty_of_pages(url)
  all_links = get_pages_url(page_qty, url)
  write_to_csv(all_links,file_name)
end

def url_to_string(url)
  page = Curl.get(url)
  doc = Nokogiri::HTML(page.body_str)
  doc
end

class Product
  attr_accessor :name, :price, :weight, :img_link
  def initialize(name, price, weight, img_link)
    @name = name
    @weight = weight
    @price = price
    @img_link = img_link
  end
end

def get_qty_of_pages(url)
  doc = url_to_string(url)
  params = YAML.load_file('params.yml')
  products_qty = doc.xpath(params['number_of_products']).text.to_i
  page_qty = (products_qty / 25.0).ceil if products_qty % 25 != 0
  page_qty
end

def get_pages_url(page_number, page )
  params = YAML.load_file('params.yml')
  all_products_links = []
  i = 1
  (i..page_number).each do |i|
    if i == 1
      each_page = Curl.get(page)
    else
      each_page = Curl.get(page + "?p=" + "#{i}")
    end
    puts "Number of page parsing - " + i.to_s
    i += 1
    current_page = Nokogiri::HTML(each_page.body_str)
    current_page.xpath(params['all_products_route']).each do |products|
      all_products_links << products
    end
  end
  all_products_links
end

def write_to_csv( links, file_name )
  params = YAML.load_file('params.yml')
  CSV.open(file_name, "w+") do |column|
    column << ["Name", "Weight", "Price", "Image"]
    threads = []
    puts Time.now
    threads << Thread.new do
      links.each do |link|

        puts "Чтение страницы - " + link
        prod_page = url_to_string(link)

        name = prod_page.xpath(params['product_name_route']).text
        img_link=prod_page.xpath(params['product_image_link_route'])

        weight_price = prod_page.xpath(params['product_weight_price_for_loop'])
        threads << Thread.new do
          pw=0
          weight_price.each do |i|
            weight = i.xpath(params['product_price_route'])[pw].text
            price = i.xpath(params['product_weight_route'])[pw].text
            pw+=1
            puts "Идет запись данных в файл"
            product = Product.new(name,price,weight,img_link)
            ready_table = [product.name, product.weight, product.price, product.img_link ]
            column << ready_table
          end
        end
      end
    end
    threads.each { |thr| thr.join }
  end
  puts Time.now
end

main