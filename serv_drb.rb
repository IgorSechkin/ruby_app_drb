require 'drb'
require 'erb'
require 'open3'
require 'sqlite3'
require 'json'
require 'cgi'
require 'digest'
require 'fileutils'
require 'rack/multipart'
require 'stringio'
require 'rack'
# require 'action_view'
# require 'action_view/helpers'
# require 'active_support/all'

# require 'find'
# # пагинация
# require 'kaminari'
# require 'kaminari/helpers/helper_methods'
# require 'pagy'

# require 'nokogiri'
# require "net/http"
# require 'open-uri'
# require 'pry'
# require "httparty"
# require 'selenium-webdriver'
# require 'down'

# require 'rss'



class Tag
    
    def self.type_tag(tag, attr={})
        tag_str = ""
        attr.map(){|k, v| tag_str += "#{k}=\"#{v}\""}
        return "<#{tag} #{tag_str}><div>#{yield}</div></#{tag}>" if block_given?
    end
    def self.button(value, attr={})
       
        return "<form action=\"#{attr[:action]}\" method=\"#{attr[:method]}\">
                  <input type=\"text\" name=\"#{attr[:name]}\" value=\"#{attr[:context]}\" hidden>
                  <input type=\"submit\" value=\"#{value}\">
                </form>"
    end
end

class MyService < Tag

  # include ActionView::Helpers::NumberHelper
  # include ActionView::Helpers::DateHelper
  # include ActionView::Helpers::TagHelper
  # include ActionView::Helpers::FormHelper
  # include ActionView::Helpers::AssetTagHelper
  # include ActionView::Helpers::FormTagHelper
  # include ActionView::Helpers::FormOptionsHelper
  # include Kaminari::Helpers::HelperMethods
  # include Pagy::HelperLoader
  # include Nokogiri
  

  attr_accessor :cookie, :params, :multipart_params
  def initialize()
    @cookie = nil
    @params = nil
    @cook = nil
  end

  # ==============block cookie=================================
  def set_cookie(cook)
    @cookie = cook
  end
  # ==============block params=================================
  def set_params(params)
    @params = params
  end

  def read_file(file)
    # поиск файла в текущуй директории
    find_comm = "find . -type f -name #{file}"
    stdout, stderr, status = Open3.capture3(find_comm)
    if status.success?
      STDOUT.flush #для опустошения буфера вывода.
      STDOUT.sync = true
      File.umask(0200) #определяет начальные разрешения для всех созданных им файлов.

      path = File.expand_path(stdout.chomp) #expand_path преобразует относительное путевое имя в абсолютный путь.

      str = File.binread(path)
      # str = Rack::Files.new(path)
      # input = File.new(path)
      # str = input.sysread(input.size)
      # input.close
    else
      puts "Error: #{stderr}"
    end
    return str
  end

    # ==========================================================
   def home
    "<h1>Home page</h1>"
    File.read("./public/page")
    # system("kill #{Process.pid}")
  end

  def contacts
    "<h1>Oure contacts!</h1>"
  end

  def aboutus
    "<h1>About us!</h1>"
  end
  def info
    File.read("./public/home.html")
  end
  
  def new_user
    # открыть базу даных
    db = SQLite3::Database.new("dev.sqlite3")
    # # занести даные
    db.execute "INSERT INTO users(name, email, created_at, password, phone) VALUES ('#{params["name"]}', '#{params["email"]}', '#{Time.now}', '#{ Digest::SHA256.hexdigest(params["password"])}', '#{params["phone"]}' );"
    # # закрыть базу данных
    db.close
    # перенаправить на другой ресурс
    return "<p style=\"color: green;\"> #{params["name"]} ви благополучно прошли регистрацию</p>"
  end

  
  def session
    # p str
    # code = CGI.unescape(str)
    # распарсить str в хэш
    # params = parse(code)
    # открыть базу даных
    db = SQLite3::Database.new("dev.sqlite3")
    # преобразование в хэш
    db.results_as_hash = true
    # выбрать юзера из таблицы
    begin
       @user_array = db.execute "SELECT * FROM users WHERE email='#{params["email"]}';" #получаем массив в нём хэш юзера
    
    
      # получаем хэш юзера
      @user = @user_array[0]

      # нужно сравнить парль с формы  Base64.encode64(pars["password"]) и пароль из таблица @user["password"]
      if Digest::SHA256.hexdigest(params["password"]).chomp == @user["password"].chomp
        # если пароли совпали
        if @user["admin"] == "true"
          # переход на страницу администратора 
          ERB.new(IO.read("./public/admin.html.erb")).result(binding)
        else
          @tovar = db.execute "SELECT * FROM tovar"
          @cookie = "<link rel=\"stylesheet\" href=\"email=#{@user["email"]}\"> <link rel=\"stylesheet\" href=\"password=#{@user["password"]}\">"
          ERB.new(IO.read("./public/catalog.html.erb")).result(binding)
        end
      end
    rescue NoMethodError
        "<br><div class='container' ><p text-color=\"red\">Вы не правильно ввели email или password попробуйте ещё</p></div>"
        # "<meta http-equiv=\"Refresh\" content=\"0; URL= /form_login\"/>"
        # "<alert>гражданин с таким логином в базе отсуствует</alert>"
    end
    
  end
  def users
    db = SQLite3::Database.new("dev.sqlite3")
    # занести даные
    @users = db.execute "SELECT * FROM users"
    # закрыть базу данных
    db.close
    ERB.new(IO.read("./public/users.html.erb")).result(binding)
  end

  def user_delete
    # p str.to_h
    # id = str.read.delete("Delete+")
    # pars = JSON.parse(str)
    db = SQLite3::Database.new("dev.sqlite3")
    # db.execute("PRAGMA key = 'seka';")
    # занести даные
    @users = db.execute "DELETE FROM users WHERE id=#{params["id"]};"
    # закрыть базу данных
    @users = db.execute "SELECT * FROM users"
    db.close
    ERB.new(IO.read("./public/users.html.erb")).result(binding)
  end

  def user_update
    @cookie
    # code = CGI.unescape(str)
    # распарсить str в хэш
    # pars = parse(code)
    
    
    # занести даные
    # UPDATE Users SET Age = 31, City = 'London' WHERE Name = 'Alice';
    @user = db.execute "UPDATE users SET name = '#{params["name"]}', email = '#{params["email"]}', password = '#{Digest::SHA256.hexdigest(params["password"])}' WHERE email='#{@cookie["/email"]}';"
    # закрыть базу данных
    @users = db.execute "SELECT * FROM users"
    db.close
    ERB.new(IO.read("./public/users.html.erb")).result(binding)
  end

  def create_tovar
  
    uploaded_file = params['fileToUpload']

    if uploaded_file
      # Имя файла: uploaded_file[:filename]
      # Тип файла: uploaded_file[:type]
      # Путь к временному файлу: uploaded_file[:tempfile].path
      
      File.open("./assets/img/#{uploaded_file[:filename]}", "wb") do |f|
        f.write(uploaded_file[:tempfile].read)
      end
      puts "Файл сохранен: #{uploaded_file[:filename]}"
    end

    # открыть базу
    db = SQLite3::Database.new("dev.sqlite3")
    db.results_as_hash = true
    # db.execute("PRAGMA key = 'seka';")
    # занести даные
    db.execute "INSERT INTO tovar(code, name, ed, col, price, vid, opis, photo) VALUES ('#{params['code']}', '#{params['name']}', 
    '#{params['ed']}', '#{params['col']}', '#{params['price']}', '#{params['vid']}', '#{params['opis']}', '#{params['fileToUpload'][:filename]}');"
    # закрыть базу данных
    db.close
    # вернуться на страницу
    "<meta http-equiv=\"Refresh\" content=\"0; URL= /admin\"/>"
    # IO.read("./public/create_post.html")

  end

  def show_tovar
    @cookie = nil
    db = SQLite3::Database.new("dev.sqlite3")
    db.results_as_hash = true
    # занести даные
    @tovar = db.execute "SELECT * FROM tovar"
    # p @tovar
    # закрыть базу данных
    db.close
    ERB.new(IO.read("./public/catalog.html.erb")).result(binding)
    
  end
  def corzina

    # получить хэш одинаковых значений массива
    if @cookie["/id_tovar"]
      @hash_id = @cookie["/id_tovar"].split('/').tally #типа {1=>2, 2=>6} где ключ это значение элемента массива, а значение - количество вхождений
      # получить телефон для дальнейшего использования
      db = SQLite3::Database.new("dev.sqlite3")
      db.results_as_hash = true
      @user = db.execute "SELECT * FROM users WHERE email='#{@cookie ["/email"]}';"
      @tovars = db.execute "SELECT * FROM tovar;"
      # p @tovar

      db.close
      ERB.new(IO.read("./public/corzina.html.erb")).result(binding)
    else
      return "<h1> Корзина</h1><p style=\"color: red;\">Ваша корзина пока пуста</p>"
    end
  end
  def ochistit_corziny
    # получить параметры
    p params
    @str = "<link rel=\"stylesheet\" href=\"#{params};max-age=0;\">"
    return @str + ERB.new(IO.read("./public/catalog.html.erb")).result(binding)
    # "<meta http-equiv=\"Refresh\" content=\"0; URL=corzina\"/" 
    
  end

  def delete_coockie
    # удалить все куки
    @str = ""
    @cookie.each(){|k, v| @str += "<link rel=\"stylesheet\" href=\"#{k}=#{v};max-age=0;\">"}
    return @str + ERB.new(IO.read("./public/catalog.html.erb")).result(binding)
    
  end

  def zakaz

    File.open("./public/zakaz.txt", "a"){|file|
        file.write("\n" + Time.now.to_s + "\n" + params)
    }
    # удалить куки очистить крзину
    @cookie_tovar = "<link rel=\"stylesheet\" href=\"/id_tovar;max-age=0;\">"
    return @cookie_tovar + ERB.new(IO.read("./public/catalog.html.erb")).result(binding)
  end

  def ochistit_file_zakaza
    
    # Очистить файл, открыв его в режиме записи ('w')
    # File.open("./public/zakaz.txt", "w") {}

    # Или более простой способ, если файл существует
    File.truncate("./public/zakaz.txt", 0) 
    
  end
  
  
  private

  def parse(str)
    
    a = []
    # перекодировать данные
    code = CGI.unescape(str)
    str.gsub!("%40", "@")
    arr_str = str.split("&")
    for line in arr_str
      h = line.split("=")
      a << h
    end
    return a.to_h
  end


  def findfiles(dir, name)
    list = []
    Find.find(dir) do |path|
      Find.prune if [".",".."].include? path
      case name
      when String
        list << path if File.basename(path) == name
      when Regexp
        list << path if File.basename(path) =~ name
      else
      raise ArgumentError
      end
    end
    list
  end

  def get_path_to_file(file)
    path = ""
    if file != "" && file != nil
      # поиск файла в текущуй директории
      find_comm = "find . -type f -name #{file}"
      # find_comm = "find . -name #{file}"
      path, stderr, status = Open3.capture3(find_comm)
    end
    if status.success?
      return path
    else
      puts "Error: #{stderr}"
    end
  end

  def run_process_with_params_system(script_path, params)
    command = "ruby #{script_path} #{params.join(' ')}"
    success = system(command)

    if success
      puts "Process finished successfully."
    else
      puts "Process failed."
    end

  end


end

server = MyService.new

DRb.start_service('druby://:9000', server)
puts "Сервер запущен на druby://:9000"
DRb.thread.join
