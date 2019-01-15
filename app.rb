require 'sinatra'
require 'sinatra/reloader'
require 'mysql2'
require 'mysql2-cs-bind'
require 'pry'

enable :sessions
enable :method_override

set :public_folder, 'public'

# Mysqlドライバの設定
client = Mysql2::Client.new(
    host: 'localhost',
    port: 3306,
    username: 'root',
    password: '',
    database: '100reco',
    reconnect: true,
)

# ログイン状態を確かめるメソッド
def is_signin
  if session[:user_id].nil?
    redirect '/signin'
  end
end


# サインイン
get '/signin' do
  @title = "signin"
  @sign_message = session[:sign_message]
  session[:sign_message] = nil

  erb :signin, :layout => nil
end


post '/signin' do

  res = client.xquery("SELECT * FROM users WHERE user_name = ? AND user_pass = ?;", params[:user_name], params[:user_pass]).first

  if res
    session[:user_id] = res["id"]
    session[:user_name] = res["user_name"]
    redirect '/'
  else
    session[:sign_message] = "※ please again !"
    redirect '/signin'
  end

end


# サインアップ
get '/signup' do
  @title = "signup"
  @sign_message = session[:sign_message]
  session[:sign_message] = nil

  erb :signup, :layout => nil
end


post '/signup' do

  res = client.xquery("SELECT * FROM users WHERE user_name = ? && user_pass = ?;", params[:user_name], params[:user_pass]).first

  if res.nil?
    client.query("INSERT INTO users (user_name, user_pass, user_title, user_sub_title, created_at, updated_at) VALUES ('#{params[:user_name]}', '#{params[:user_pass]}', 'このアルバムのタイトルを入力してください', '簡単な説明を入力してください', CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP())")
    redirect '/signin'
  else
    session[:sign_message] = "※ please again !"
    redirect '/signup'
  end
end


# トップページ
get '/' do
  is_signin()
  @title = "top"
  @name = session[:user_name]

  @posts = client.xquery("SELECT * FROM posts WHERE created_user_id = ? ORDER BY post_date #{session[:user_sort_option]};", session[:user_id])
  @about = client.xquery("SELECT * FROM users WHERE id = ?;", session[:user_id]).first

  erb :top
end


post '/sort' do
  if params[:order] == "asc"
    session[:user_sort_option] = "ASC"
  elsif params[:order] == "desc"
    session[:user_sort_option] = "DESC"
  end

  redirect '/'
end


# 投稿
get '/post' do
  is_signin()
  @title = "post"

  erb :post
end


post '/post' do

  if !params[:image].nil?
    @filename = params[:image][:filename]
    file = params[:image][:tempfile]

    File.open("./public/image/#{@filename}", 'wb') do |f|
      f.write(file.read)
    end
  else
    @filename = nil
  end

  query = "INSERT INTO posts (created_user_id, post_date, post_image, post_description, created_at, updated_at) VALUES ('#{session[:user_id]}', '#{params[:date]}', '#{@filename}', '#{params[:description]}', CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP())"
  client.query(query)

  redirect '/'
end


# 詳細ページ & 削除
get '/post/:id' do
  is_signin()
  @title = "details"

  @detail = client.xquery("SELECT * FROM posts WHERE id = ?;", params[:id]).first

  erb :details
end


delete '/post/:id/delete' do
  # ファイル削除
  # FileUtils.rm_rf("./public/image/#{@filename}")
  # DBから削除
  client.xquery("DELETE FROM posts WHERE id = ?;", params[:id])

  redirect '/'
end


# 編集ページ
get '/post/:id/edit' do
  is_signin()
  @title = "edit"

  @edit = client.xquery("SELECT * FROM posts WHERE id = ?;", params[:id]).first

  erb :edit
end


post '/post/:id/edit' do
  @filename = params[:image][:filename]
  file = params[:image][:tempfile]

  File.open("./public/image/#{@filename}", 'wb') do |f|
    f.write(file.read)
  end

  client.xquery("UPDATE posts SET post_date = '#{params[:date]}', post_image = '#{@filename}', post_description = '#{params[:description]}' WHERE id = ?;", params[:id])
  session[:edit_message] = "編集が保存されました！"

  redirect '/edit_message'
end


get '/edit_message' do
  is_signin()
  @title = "edit_message"

  erb :edit_message
end


# プロフィール設定
get '/setting' do
  is_signin()
  @title = "setting"

  @setting = client.xquery("SELECT * FROM users WHERE id = ?;", session[:user_id]).first
  @setting_message = session[:setting_message]
  session[:setting_message] = nil

  erb :setting
end


post '/setting' do

  client.xquery("UPDATE users SET user_name = '#{params[:user_name]}', user_title = '#{params[:user_title]}', user_sub_title = '#{params[:user_sub_title]}' WHERE id = ?;", session[:user_id])

  res = client.xquery("SELECT * FROM users WHERE id = ?;", session[:user_id]).first
  session[:user_name] = res["user_name"]
  session[:user_title] = res["user_title"]
  session[:user_sub_title] = res["user_sub_title"]

  session[:setting_message] = "変更しました！"

  redirect '/setting'
end


# サインアウト
get '/signout' do
  session[:user_id] = nil
  session[:user_name] = nil
  session[:user_pass] = nil

  redirect '/'
end
