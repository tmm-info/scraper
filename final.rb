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
  all_urls = get_pages_url(page_qty, url)
  write_to_csv(all_urls,file_name)
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
  page = Curl.get(url)
  doc = Nokogiri::HTML(page.body_str)
  params = YAML.load_file('params.yml')
  products_qty = doc.xpath(params['number_of_products']).text.to_i
  if products_qty % 25 == 0
    page_qty = (products_qty / 25)
  else
    page_qty = (products_qty / 25).next
  end
  page_qty
end

def get_pages_url(page_qty, page )
  params = YAML.load_file('params.yml')
  all_products_urls = []
  i = 1
  (i..page_qty).each do |page_number|
    if page_number == 1
      each_page = Curl.get(page)
    else
      each_page = Curl.get(page + "?p=" + "#{page_number}")
    end
    puts "Number of page parsing - " + page_number.to_s
    page_number += 1
    current_page = Nokogiri::HTML(each_page.body_str)
    current_page.xpath(params['all_products_route']).each do |products|
      all_products_urls << products
    end
  end
  all_products_urls
end

def write_to_csv( all_products_urls, file_name )
  params = YAML.load_file('params.yml')
  CSV.open(file_name, "w+") do |column|
    column << ["Name", "Weight", "Price", "Image"]
    threads = []
    puts Time.now
    threads << Thread.new do
      all_products_urls.each do |url|

        puts "Чтение страницы - " + url
        get_link = Curl.get(url)
        prod_page = Nokogiri::HTML(get_link.body_str)

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