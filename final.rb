require 'curb'
require 'nokogiri'
require 'csv'
require 'curl'

def main
  puts "Введите ссылку: "
  url = gets.chomp

  puts "Введите название файла:"
  file_name = gets.chomp

  #page = "https://www.petsonic.com/farmacia-para-gatos/"
  page_num = 11

  all_links = each_url(page_num, url)
  write_to_csv(all_links, file_name)
  puts "Файлы успешно записаны"
end


def each_url( page_num, page )
  all_links = []
  i = 1
  while i <= page_num do
    if i == 1
      each_page = Curl.get(page)
    else
      each_page = Curl.get(page + "?p=" + "#{i}")
    end
    puts "Number of page parsing - " + i.to_s
    i+=1
    current_page = Nokogiri::HTML(each_page.body_str)

    current_page.xpath('//*[@class="product_img_link pro_img_hover_scale product-list-category-img"]/@href').each do |products|
      all_links << products
    end
  end
  all_links
end

def write_to_csv( links, file_name )
  CSV.open(file_name, "w+") do |column|
    column << ["Name", "Weight", "Price", "Image"]

    links.each do |link|

      puts "Чтение страницы - " + link
      get_link = Curl.get(link)
      prod_page = Nokogiri::HTML(get_link.body_str)

      name= prod_page.xpath('//div/h1').text
      img=prod_page.xpath('//*[@id="bigpic"]/@src')

      weight_price = prod_page.xpath('//fieldset//ul/li')

      pw=0
      weight_price.each do |i|
        weight = i.xpath('//*[@class="radio_label"]')[pw].text
        price = i.xpath('//*[@class="price_comb"]')[pw].text
        pw+=1
        puts "Идет запись данных в файл"
        ready_table = ["#{name}", "#{weight}", price, img ]
        column << ready_table
      end
    end
  end
end

main