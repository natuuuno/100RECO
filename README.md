100RECO  
========
プログラミング講座の卒業制作です。  
画像とコメントの投稿・編集・削除ができます。  

環境
---
・Ruby2.5.0p0  
・sinatra(2.4.0)  
・MySQL２（0.5.2）  

DBの用意  
--------
CREATE DATEBASE 100reco;  

USE 100reco;  

CREATE TABLE users(id int(11) auto_increment primary key, user_name varchar(255), user_pass varchar(255), user_title varchar(255), user_sub_title varchar(255));  

CREATE TABLE posts(id int(11) auto_increment primary key, created_user_id int(11), post_date varchar(255), post_image varchar(255), post_description varchar(255));  

起動
----
$ cd 100reco  
$ mysql.server start  
$ ruby app.rb  

localhost:4567

今後の方針
--------
・全体の投稿一覧ページをつくる  
・１００枚の制限をつける  
・完成したらアニメーションで見られるようにする  
・タグ付け、検索機能をつくる  

