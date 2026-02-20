require 'drb'
require 'open3'
require 'erb'

Thread.new {
      system("ruby serv_drb.rb")
}
class App
  attr_accessor :str
  def initialize()
    @str = nil

  end

  def call(env)
    # загружаем drb сервер
    
    meth = env["REQUEST_PATH"].delete("/")
    sock = env["puma.socket"]
    cookie = env["HTTP_COOKIE"]
    DRb.start_service
    ro = DRbObject.new_with_uri("druby://localhost:9000")
    
=begin 
. (Точка): Любой один символ, кроме символа новой строки (newline, \n).
\w: Любой буквенно-цифровой символ и знак подчеркивания ([a-zA-Z0-9_]).
\S: Любой непробельный символ.
\s: Любой пробельный символ (пробел, табуляция, новая строка и т.д.). 

Для любой последовательности (включая новую строку)

.* (.*): Любая последовательность из нуля или более символов (кроме новой строки).
[\s\S]: Любой символ, включая новую строку (сочетание всех пробельных и непробельных символов).
(?s): Флаг, который включает модификатор . (точка) для соответствия новой строке (используется в некоторых движках регулярных выражений). 
=end
    if meth =~ /\w+\.(?:mp4|avi|js|css|jpg|jpeg|png|mp3|xml|json|ico|txt|map)/
      # получить html запрос 
      str = ro.read_file(meth, env["HTTP_SEC_FETCH_DEST"] )
      sock.write str
      sock.close
    
    elsif meth =~ /([^=]+)=([^;]+)/ 
      # p meth
      # "<meta http-equiv=\"Refresh\" content=\"0; URL=home.html\"/>"
      coockie = "HTTP/1.1 200 OK\r\nContent-Type: text/css\r\nSet-Cookie: /#{meth}; Path=/; secure; SameSite=Lax;"
      sock.write coockie 
      sock.close
    else
    end
      
    

@str = nil
    
@str = templ(){
      if meth == ""
        IO.read("./public/page.html")
      elsif meth == "home" || meth == "show_post" ||  meth == "aboutus" ||  meth == "info" || meth == "new_post" || meth == "new_user" ||
            meth == "contacts" || meth == "page" || meth == "users" || meth == "session" || meth == "show_tovar" || meth == "delete_user" ||
            meth == "books" || meth == "chat" || meth == "add_member" || meth == "corzina" || meth == "delete_coockie" || meth == "ochistit_corziny" ||
            meth == "zakaz" || meth == "ochistit_file_zakaza"
            p "-------------------------------------------------"
             # нужно что-то придумать что-бы пропускало только указатель на ресурс 

        if env["REQUEST_METHOD"] == "POST"
          # p meth
          # p env["rack.input"].read
          # ERB.new(ro.send(meth, env["rack.input"])).result(binding) 
          
          ERB.new(ro.send(meth, env)).result(binding) 
        else
          # p meth
          # p "Мы здесь"
          ERB.new(ro.send(meth)).result(binding) 
        end

      end
    }

    [200, {"content-type" => "text/html"}, [@str]] # это нужно куда-то перенести

  end

  private
  def templ
    ERB.new(IO.read("./public/template.html.erb")).result(binding) if block_given?
  end
    
   
end

# "HTTP_SEC_FETCH_DEST"=>"document"
# "REQUEST_METHOD"=>"GET"
# env["HTTP_COOKIE"]
# "CONTENT_LENGTH"=>"25"
# env["rack.input"]
