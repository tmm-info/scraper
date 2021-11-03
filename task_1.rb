require 'curb'
require 'nokogiri'
require 'csv'
require 'yaml'
require_relative 'product'

@params = YAML.load_file('params.yml')
def main
  url = @params['url']
  puts "Сайт: #{url}"
  file_name = gets.chomp
  puts "Файл для сохранения данных #{file_name}:"
  url_body(url)
  products_qty = @doc.xpath(@params['number_of_products']).text.to_i
  page_qty = get_qty_of_pages(products_qty)
  all_links = get_product_links(page_qty, url)
  ready_table = parse_products(all_links)
  write_to_csv(file_name, ready_table)
end

def url_body(url)
  page = Curl.get(url)
  @doc = Nokogiri::HTML(page.body_str)
end


def self.get_qty_of_pages(products_qty)
  page_qty = (products_qty / 25.0).ceil
end

def get_product_links(page_number, page)
  all_products_links = []
  (1..page_number).each do |pagination_index|
    (pagination_index == 1) ?
      each_page = url_body(page) :
      each_page = url_body(page + "?p=" + "#{pagination_index}")
    puts "Number of page parsing - " + pagination_index.to_s
    each_page.xpath(@params['all_products_links']).each do |products|
      all_products_links << products
    end
  end
  all_products_links
end

def parse_products(all_products_links)
  ready_table = []
  all_products_links.each do |url|
    url_body(url)
    name = @doc.xpath(@params['product_name_route']).text
    img_link = @doc.xpath(@params['product_image_link_route']).text
    weight = @doc.xpath(@params['product_weight_route']).text
    price = @doc.xpath(@params['product_price_route']).text
    ready_table << ["#{name} - #{weight}", price, img_link]
  end
  ready_table
end

def write_to_csv( file_name, ready_table )
  CSV.open(file_name, "w+") do |csv|
    puts "idet zapis v fail"
    csv << ready_table
  end
end

main