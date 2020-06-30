require 'nokogiri'
require 'open-uri'
require 'sqlite3'
require 'byebug'
require 'monetize'
require 'sinatra'
require 'json'
require './config.rb'
require './fii.rb'
require './wallet.rb'
require './database.rb'
require './dy.rb'

threads = []

get '/' do
  #p Nokogiri::HTML.parse((open("https://www.fundsexplorer.com.br/funds/bbfi11b").read)).css('span.indicator-value').first.text.strip.to_i
  #indexes = parse.css('div#informations--indexes div.item span.value')
end

get '/gerar_carteira' do 

end

get '/carregamento' do
  wallet = Wallet.new("https://fiis.com.br/lista-de-fundos-imobiliarios/")
  fiis = wallet.get_fiis()
  wallet.get_dys()
end

get '/fundos' do
  wallet = Wallet.new("https://fiis.com.br/lista-de-fundos-imobiliarios/")
  fiis = wallet.get_fiis_db

  json = {}
  json[:size] = fiis.size
  json[:data] = []
  fiis.each { |fii| 
    dys = {}
    dys[:data] = []
    fii.get_dys_db.each { |dy|
      dys[:data].append({
        id: dy.id,
        value: dy.value,
        data_base: dy.data_base,
        data_pagamento: dy.data_pagamento,
        cotacao_base: dy.cotacao_base,
        rendimento: dy.rendimento
      })
    }

    json[:data].append({
      id: fii.id,
      cod: fii.cod,
      name: fii.name,
      category: fii.category,
      category_fii: fii.category_fii,
      category_anbima: fii.category_anbima,
      registro_cvm: fii.registro_cvm,
      num_cotas: fii.num_cotas,
      num_cotistas: fii.num_cotistas,
      cnpj: fii.cnpj,
      taxas: fii.taxas,
      preco_cota: fii.preco_cota,
      dividend_yeild_aux: fii.dividend_yeild_aux,
      ultimo_rendimento: fii.ultimo_rendimento,
      patrimonio_liquido: fii.patrimonio_liquido,
      patrimonio_liquido_base: fii.patrimonio_liquido_base,
      valor_patrimonial: fii.valor_patrimonial,
      dys: dys
    })
  }

  json.to_json
end

#wallet.get_dys()