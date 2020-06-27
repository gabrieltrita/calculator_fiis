require 'nokogiri'
require 'open-uri'
require 'sqlite3'
require 'byebug'
require 'monetize'
require './config.rb'
require './fii.rb'
require './wallet.rb'
require './database.rb'
require './dy.rb'

wallet = Wallet.new("https://fiis.com.br/lista-de-fundos-imobiliarios/")
wallet.get_fiis()
wallet.get_dys()

