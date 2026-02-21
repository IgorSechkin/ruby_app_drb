require 'drb'
require 'erb'
require 'open3'
require 'sqlite3'
require 'find'
require 'digest'
require 'json'
require './codir'

# p parol = Digest::SHA256.hexdigest('hello world') #необратим
# для чата



class MyService
  attr_accessor :login
  def initialize
    @mutex = Thread::Mutex.new
    @login = false
    @members = {}
  end

  def home
    "<h1>Home page</h1>"
    File.read("./public/page")
    # system("kill #{Process.pid}")
  end

  def books
    File.read("./public/books.html")
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
  # здесь ищется файл начиная с корневой директории
  def read_file(file, type)
    # используем модуль find
    # Путь к папке
    start_directory = '.'
    # Ищем файл во всех подпапках
    pattern = "#{start_directory}/**/#{file}"
    path_file = Dir.glob(pattern).join
    # Dir.glob(pattern).each do |file_path|
    #   puts "Найден файл: #{file_path}"
    # end
    # Dir.glob(pattern)


    # # поиск файла в текущуй директории системные вызовы
    # find_comm = "find . -type f -name #{file}"
    # fstdout, fstderr, fstatus = Open3.capture3(find_comm)
    # str = File.binread(fstdout.chomp)
    body = File.binread(path_file)
    "#{path_file} = #{get_content_type(type)} "
    "HTTP/1.1 200 OK\r\nContent-Type: #{get_content_type(type)}\r\nContent-Length: #{body.size}\r\n\r\n#{body}"
  end

  def new_user(env)

    # require 'base64'
    # получить str
    user = env["rack.input"].read
    # перекодировать строку
    # p code = user.unpack('U*').pack('U*')
    p code = Encode.encoding(user)
    # распарсить str в хэш
    p pars = parse(code)
    # открыть базу даных
    db = SQLite3::Database.new("dev.sqlite3")
    # # занести даные
    # db.execute "INSERT INTO users(name, email, created_at, password, phone) VALUES ('#{pars["name"]}', '#{pars["email"]}', '#{Time.now}', '#{ Base64.encode64(pars["password"])}', '#{pars["phone"]}' );"
    # дайджест
    db.execute "INSERT INTO users(name, email, created_at, password, phone) VALUES ('#{pars["name"]}', '#{pars["email"]}', '#{Time.now}', '#{ Digest::SHA256.hexdigest(pars["password"])}', '#{pars["phone"]}' );"
    # # закрыть базу данных
    db.close
    # перенаправить на другой ресурс
    return "<p style=\"color: green;\"> #{pars["name"]} ви благополучно прошли регистрацию</p>"
    # File.read("./public/page.html") 
  end

  def session(env)
    #  если есть куки получить их
    @hash_coockie = env["HTTP_COOKIE"]
    # получить str
    us = env["rack.input"].read
    # перекодировать строку
    code = us.unpack('U*').pack('U*')
    # распарсить str в хэш
    pars = parse(code)
    # открыть базу даных
    db = SQLite3::Database.new("dev.sqlite3")
    # занести даные
    @user = db.execute "SELECT * FROM users WHERE email='#{pars["email"]}';"
    @us = @user.flatten
    @user_post = db.execute "SELECT * FROM posts WHERE user_id='#{us[0]}';"
    @tovar = db.execute "SELECT * FROM tovar"

    # admin

    if @us[7] == "true"
      # переход на страницу администратора %>
      return ERB.new(IO.read("./public/admin.html.erb")).result(binding)
    else
      Digest::SHA256.hexdigest(pars["password"])

      if @us[6] == Digest::SHA256.hexdigest(pars["password"])
        @login = true
        str = ""
        # кукки email и password для profile 
        # str = "<link rel=\"stylesheet\" href=\"email=#{@us[2]}\"> <link rel=\"stylesheet\" href=\"password=#{@us[6]}\"> <meta http-equiv=\"Refresh\" content=\"0; URL=show_tovar\"/>"
        # return str
        @email = "/email=#{@us[2]}"
        @password = "/password=#{@us[6]}"
        return ERB.new(IO.read("./public/set_cookie_session.html.erb")).result(binding)
      else
        return "<p style=\"color: red;\">Ви не зареєстровані, або не вірний пароль</p>"
      end
    end

    # закрыть базу данных
    db.close


    # ERB.new(IO.read("./public/user.html.erb")).result(binding)
    
  end
  def users
    db = SQLite3::Database.new("dev.sqlite3")
    # занести даные
    @users = db.execute "SELECT * FROM users"
    # закрыть базу данных
    db.close
    ERB.new(IO.read("./public/users.html.erb")).result(binding)
  end
  def delete_user(env)
    params = env["rack.input"].read
    arr = params.split("=")
    # Подключение к базе данных
    db = SQLite3::Database.new("dev.sqlite3")
    
    # SQL-запрос
    user = db.execute "SELECT * FROM users WHERE #{arr[0]}='#{arr[1]}';"
    # p user.flatten
    sql_query = "DELETE FROM users WHERE #{arr[0]}='#{arr[1]}';"
    # Выполнение запроса
    db.execute(sql_query)

    # Закрытие соединения
    db.close()
    return "<p style=\"color: green;\">Ви благополучно удалили пользователя </p>"
  end

  def new_post(str)

    # # получить str
    post = str.read
    # перекодировать строку
    code = post.unpack('U*').pack('U*')
    # распарсить str в хэш
    pars = parse(code)
    # открыть базу даных
    db = SQLite3::Database.new("dev.sqlite3")
    # занести даные
    db.execute "INSERT INTO posts(user_id, title, content, photo, created_at) VALUES ('#{pars["title"]}', '#{pars["content"]}', '#{pars["photo"]}', '#{Time.now}');"
    # закрыть базу данных
    db.close
    # перенаправить на другой ресурс
    # File.read("./public/new_post.html") 
    "<!DOCTYPE html><html><head><meta http-equiv=\"Refresh\" content=\"0; URL=home\"/><head><body></body></html>"   

  end

  def show_post
    
    db = SQLite3::Database.new("dev.sqlite3")
    # занести даные
    @posts = db.execute "SELECT * FROM posts"
    # закрыть базу данных
    db.close
    ERB.new(IO.read("./public/content.html.erb")).result(binding)
    
  end

  def show_tovar
    
    db = SQLite3::Database.new("dev.sqlite3")
    # занести даные
    @tovar = db.execute "SELECT * FROM tovar"
    # p @tovar
    # закрыть базу данных
    db.close
    ERB.new(IO.read("./public/catalog.html.erb")).result(binding)
    
  end
  def corzina(env)
    # получить и распарсить куки
    @hash_cookie = parse_cookie(env["HTTP_COOKIE"])
    
    # получить хэш одинаковых значений массива
    if @hash_cookie["/id_tovar"]
      @hash_id = @hash_cookie["/id_tovar"].split('/').tally #типа {1=>2, 2=>6} где ключ это значение элемента массива, а значение - количество вхождений
      # получить телефон для дальнейшего использования
      db = SQLite3::Database.new("dev.sqlite3")
      @user = db.execute "SELECT * FROM users WHERE email='#{@hash_cookie ["/email"]}';"
      @us = @user.flatten
      @tovars = db.execute "SELECT * FROM tovar;"
      # p @tovar

      db.close
      ERB.new(IO.read("./public/corzina.html.erb")).result(binding)
    else
      return "<h1> Корзина</h1><p style=\"color: red;\">Ваша корзина пока пуста</p>"
    end
  end
  def ochistit_corziny(env)
    # получить параметры
    par = env["rack.input"].read.chomp
    @str = "<link rel=\"stylesheet\" href=\"#{par};max-age=0;\">"
    return @str + ERB.new(IO.read("./public/catalog.html.erb")).result(binding)
    # "<meta http-equiv=\"Refresh\" content=\"0; URL=corzina\"/" 
    
  end

  def delete_coockie(env)
    # удалить все куки
    @str = ""
    @hash_coockie = parse_cookie(env["HTTP_COOKIE"])
    @hash_coockie.each(){|k, v| @str += "<link rel=\"stylesheet\" href=\"#{k}=#{v};max-age=0;\">"}
    return @str + ERB.new(IO.read("./public/catalog.html.erb")).result(binding)
    
  end

  def zakaz(env)
    params = env["rack.input"].read 
    zakaz = params.unpack('U*').pack('U*') # можно сохранять в html файл
    File.open("./public/zakaz.txt", "a"){|file|
        file.write("\n" + Time.now.to_s + "\n" +zakaz)
    }
    # удалить куки очистить крзину
    @str = "<link rel=\"stylesheet\" href=\"/id_tovar;max-age=0;\">"
    return @str + ERB.new(IO.read("./public/catalog.html.erb")).result(binding)
  end

  def ochistit_file_zakaza
    
    # Очистить файл, открыв его в режиме записи ('w')
    # File.open("./public/zakaz.txt", "w") {}

    # Или более простой способ, если файл существует
    File.truncate("./public/zakaz.txt", 0) 
    
  end

  # для чата
# ========================================================

# ========================================================
  private

  def parse(str)
    a = []
    str.gsub!("%40", "@")
    arr_str = str.split("&")
    for line in arr_str
      h = line.split("=")
      a << h
    end
    return a.to_h
  end

  def parse_cookie(str)
    a = []
    arr_str = str.split("; ")
    for line in arr_str
      h = line.split("=")
      a << h
    end
    return a.to_h
  end

  def get_content_type(arg)
    if arg == "document"
      return "text/html"
    elsif arg == "style"
      return "text/css"
    elsif arg == "image"
      return "image/gif"
    elsif arg == "audio"
      return "audio/mpeg"
    elsif arg == "video"
      return "video/mp4"
    elsif arg == "manifest"
      return "application/json"
    elsif arg == "script"
      return "text/javascript"
    elsif arg == "empty"
      return "application/xml; charset=utf-8"
    else
      return "application/octet-stream"
    end

  end

  def authenticate(str)
    return str
  end

end

server = MyService.new
DRb.start_service('druby://:9000', server)
puts "Сервер запущен на druby://:9000"
DRb.thread.join

# system("kill #{Process.pid}")







