require 'curb'
require 'nokogiri'
require 'csv'
require 'yaml'
require 'curl'

threads = []
@params = YAML.load_file('params.yml')
#page = "https://www.petsonic.com/farmacia-para-gatos/"
def main
  puts "Введите ссылку: "
  url = gets.chomp
  puts "Введите название файла:"
  file_name = gets.chomp
  page_qty = get_qty_of_pages(url)
  all_links = get_product_links(page_qty, url)
  ready_table = parse_products(all_links)
  write_to_csv(file_name, ready_table)
end

def url_to_string(url)
  page = Curl.get(url)
  @doc = Nokogiri::HTML(page.body_str)
  @doc
end

class Product
  attr_accessor :name_weight, :price, :img_link
  def initialize(name, weight, price, img_link)
    @name = name
    @weight = weight
    @price = price
    @img_link = img_link
  end
end

def get_qty_of_pages(url)
  doc = url_to_string(url)
  products_qty = doc.xpath(@params['number_of_products']).text.to_i
  page_qty = (products_qty / 25.0).ceil
  page_qty
end

threads << Thread.new{
def get_product_links(page_number, page)
  all_products_links = []
  (1..page_number).each do |pagination_index|
    (pagination_index == 1) ? each_page = Curl.get(page) : each_page = Curl.get(page + "?p=" + "#{pagination_index}")
    puts "Number of page parsing - " + pagination_index.to_s
    current_page = Nokogiri::HTML(each_page.body_str)
    current_page.xpath(@params['all_products_route']).each do |products|
      all_products_links << products
    end
  end
  all_products_links
end}

threads << Thread.new {
  def parse_products(all_products_links)
    all_products_links.each do |url|
      puts "Чтение страницы - " + url
      name = @doc.xpath(@params['product_name_route']).text
      img_link = @doc.xpath(@params['product_image_link_route']).text
      weight_block = @doc.xpath(@params['product_weight_price_for_loop'])
      weight_block.each_with_index do | block, index |
        weight = block.xpath(@params['product_weight_route'])[index].text
        price = block.xpath(@params['product_price_route'])[index].text
        product = Product.new(name, weight, price, img_link)
        ready_table = [ "#{product.name} - #{product.weight}", product.price, product.img_link ]
        ready_table
      end
    end
  end}

threads << Thread.new{
  def write_to_csv( file_name, ready_table )
    CSV.open(file_name, "w+") do |csv|
      csv << ready_table
      # names_weights.zip(prices,links) { |row| csv << row }
    end
  end
}
threads.each { |thr| thr.join }

main