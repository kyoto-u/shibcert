Shibcert: 学認連携に基づく個人証明書申請管理システム
=============================================
使い方
-----

NIIの発行する個人証明書(クライアント証明書・S/MIME証明書)の発行申請・PIN番号確認・無効化などを行うシステムです。大学や研究機関で使うことを想定し、アカウント認証は学認連携によって行います。

環境
---
- Ruby on Rails 6.1
- Ruby 2.7.3

学認との SAML 認証連携は、omniauth-saml モジュールを利用する方式を利用するため、shibd は不要です。
SAML に関する設定は config/initializers/omniauth.rb に記述します。

開発環境の構築手順
-----------------

```sh
git clone https://github.com/kyoto-u/shibcert.git
cd shibcert
ruby --version
 ruby 2.7.3

bundle config set path 'vendor/bundle'
bundle config set without 'production'
bundle config build.zipruby --with-cflags="-Wno-error=implicit-function-declaration" # only for MacOS
bundle install

export RAILS_ENV=development
bundle exec rails s
```
