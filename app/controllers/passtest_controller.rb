# coding: utf-8

require 'base64'

# ========================================================================
# PasstestController: 試験用UPKI-PASSダミーサーバのクラス.
class PasstestController < ApplicationController

  # 試験の為に事前認証トークン検証をオフにする.
  skip_before_action :verify_authenticity_token

  # ----------------------------------------------------------------------
  # 動作確認用
  def index
#    mesg = RaReq.upkiPassCert2("abc", "xyz")
#    render text: mesg
    render text: 'ok: UPKI-PASS Dummy Server.'
  end

  # ----------------------------------------------------------------------
  # ダミー発行受付API
  def recvcert

    filename = "log/upki-pass-recvcert.log"

    open(filename, "w") do |fp|
      if !params[:key].blank?
        fp.puts("key:" + params[:key])
      end
      if !params[:certfile].blank?
        fp.puts("certfile:" + params[:certfile])
      end
      if !params[:passwdfile].blank?
        fp.puts("passwdfile:" + params[:passwdfile])
      end
    end

    render text: 'ok: UPKI-PASS recvcert.'

  end

  # ----------------------------------------------------------------------
  # ダミー失効受付API
  def recvrevocation

    filename = "log/upki-pass-recvrevocation.log"

    open(filename, "w") do |fp|
      if !params[:key].blank?
        fp.puts("key:" + params[:key])
      end
      if !params[:id].blank?
        fp.puts("id:" + params[:id])
      end
    end

    render text: 'ok: UPKI-PASS recvrevocation.'

  end

end
# ========================================================================
