require 'erb'
require 'drb'
require 'open3'
require 'json'
require 'rack'
require 'rack/multipart'
require 'stringio'
require 'cgi'
require 'mime/types'

require 'httparty'

require 'openssl'



# запускаем сервер drb
Thread.new {
  
      system("ruby serv_drb.rb")
}




class App
  
  attr_accessor :body, :env_type, :sock, :path_info, :type, :content, :headers

  def initialize()
    
    @mutex = Thread::Mutex.new
    # @type = Type_struct.new("text/html", "text/css", "image/gif", "text/css", "text/css", "application/json", "text/javascript", "application/octet-stream", "application/wasm")
    
  end

  def call(env)

    # Dir.chdir("./")
    
    # client drb
    DRb.start_service
    @ro = DRbObject.new_with_uri("druby://localhost:9000")

    # env.each{|en| p en}

    @multipart_params = Rack::Multipart.parse_multipart(env)

    @request = Rack::Request.new(env)
    
    @path_info = env["REQUEST_PATH"]
    @env_type = env["HTTP_SEC_FETCH_DEST"]
    @env_meth = env["REQUEST_METHOD"]
    @sock = env["puma.socket"]

    @env_params = env["rack.input"].read
    code = CGI.unescape(@env_params)
    
    # отправляем на сервер drb параметры
    if @env_meth == 'POST'
      if @multipart_params != nil
        # для загрузки картинок
        @ro.set_params(@multipart_params) 
      else
        if @path_info == "/zakaz" || @path_info == "/ochistit_corziny"# идет через javascript в формате string и json
          # @ro.set_params(code)
          # if code.class == "String"
          #   @ro.set_params(code)
          # else
          #   # если параметры приходят в виде json
          #   params = JSON.parse(code)
          #   @ro.set_params(params) 
          # end
          begin
            params = JSON.parse(code)
            @ro.set_params(params)
          rescue StandardError => e
            @ro.set_params(code)
          end
        else
          @ro.set_params(parse(code)) # в формате string
        end
      end
    elsif @env_meth == 'GET'
      # это для пагинации идет запрос через <a> но с параметром ( <li class="page-item" ><a class="page-link" href="?page=<%= num %>"><%= num %></a></li> )
      # @request.params может отправлять все за исключением javascript (но это не точно)
      @ro.set_params(@request.params) if !@request.params.empty?
    end
    
    # отправляем на сервер drb куки
    if env["HTTP_COOKIE"] != nil
      @ro.send(:set_cookie, parse_cookie(env["HTTP_COOKIE"]))
    end

    
    [200, {"content-type" => "#{get_content_type(@env_type)}"}, [get_template{get_block_template(@path_info)}] ]
    
    
  end

  private

  def get_template
    return ERB.new(IO.read('template.html.erb')).result(binding) if block_given?
  end

  def get_block_template(arg)

    file = arg.delete("/").chomp if arg != nil

    if file =~ /\w+\.(?:png|jpeg|jpg|avi|mp4|xml|mp3|ico|css|xml|js|json|txt|csv|wasm|jquery|html.erb|html)/
      # content_file = File.binread(fstdout.chomp)
      content_file = @ro.send(:read_file, file)
      str = "HTTP/1.1 200 OK\r\nContent-Type: #{get_content_type(@env_type)}\r\nContent-Length: #{content_file.size}\r\n\r\n#{content_file}"
      @sock.write str
      @sock.close
    elsif file == "home" ||  file == "aboutus" ||  file == "info"|| file == "new_user" || file == "create_tovar" ||
            file == "contacts" || file == "users" || file == "session" || file == "show_tovar" || file == "delete_user" ||
            file == "corzina" || file == "delete_coockie" || file == "ochistit_corziny" ||
            file == "zakaz" || file == "ochistit_file_zakaza"
      @ro.send(file.to_sym)
    elsif file =~ /([^=]+)=([^;]+)/
      # для javascript не принимает с параметром HttpOnly;
      @sock.write "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nSet-Cookie: #{arg}; Path=/; secure; SameSite=none;"
      # @sock.write"HTTP/1.1 200 OK\r\nContent-Type: text/css\r\nSet-Cookie: #{arg}; Path=/; HttpOnly; secure; SameSite=Lax;"
    else

    end

  end

  def get_content_type(arg)
    if arg == "document"
      return "text/html"
    elsif arg == "style"
      return "text/css"
    elsif arg == "image"
      return "image/jpeg"
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
      return "application/wasm"
    end

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

  def parse(str)
    a = []
    # перекодировать данные
    # code = CGI.unescape(str)
    str.gsub!("%40", "@")
    arr_str = str.split("&")

    for line in arr_str
      h = line.split("=")
      if h.size == 2
        a << h
      end
    end
    return a.to_h
  end

end
