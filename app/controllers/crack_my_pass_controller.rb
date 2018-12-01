class CrackMyPassController < ApplicationController

  def create
    require 'cipher_tools'

    encrypted_text = permitted_params
                         .require(:encrypted_text)
    all_guesses = []
    if text_ok = (encrypted_text !~ /[^\d ,]+/)
      parsed_text = encrypted_text
                        .strip
                        .split(',')
                        .map(&:to_i)
      key_size = permitted_params.require(:key_size).to_i


      CipherTools.guess_key parsed_text, key_size do |guesses|
        all_guesses += guesses
      end
    end

    render json: {guesses: all_guesses, error: !text_ok}
  end

  def new

  end

  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def permitted_params
    params.permit :utf8, :_method, :authenticity_token, :commit, :id,
                  :encrypted_text, :key_size
  end
end
