class Fii
  attr_accessor :id, :cod, :name,:category, :category_anbima, :category_fii, :registro_cvm, :num_cotas, :num_cotistas, :cnpj, :taxas, :parsed_data
  
  def initialize(cod='', id=nil, name='', category='', category_fii='', category_anbima='', registro_cvm=nil, num_cotas=0.0, num_cotistas=0, cnpj='', taxas='')
    @id = id
    @dys_list = []
    @cod = cod

    @category = category
    @category_fii = category_fii
    @category_anbima = category_anbima
    @registro_cvm = registro_cvm
    @num_cotas = num_cotas
    @num_cotistas = num_cotistas
    @cnpj = cnpj
    @taxas = taxas
    @threads = []
  end

  def read_fii()
    if @parsed_data.nil?
      @parsed_data = Nokogiri::HTML.parse((open("https://fiis.com.br/#{@cod}/").read))
    end

    @parsed_data
  end

  def informations_basics
    value = read_fii().css('div.row .value')
    @name = value[0].text
    @category = 'Fundo imobiliario'
    @category_fii = value[1].text
    @category_anbima = value[2].text
    @registro_cvm = value[3].text
    @num_cotas = value[4].text
    @num_cotistas = value[5].text
    @cnpj = value[6].text

    [@name, @category, @category_fii, @category_anbima, @registro_cvm, @num_cotas, @num_cotistas, @cnpj]
  end

  def informations_taxas
    @notes = @parsed_data.css('.taxas').text
  end

  def test_thread(dy)
    @threads << Thread.new { 
      p "inserindo : #{dy.value}|#{dy.data_base}|#{dy.data_pagamento}|#{dy.cotacao_base}|"
      dy.id = Database.insertDy(dy)
    }
  end


  def dys
    aux = -2
    table = read_fii().css('table#last-revenues--table tbody')[0]
    html = table.css('td')
    init = 0
    final = 4
    threads = []
    while final < html.size do
      row = html.map{ |td| td.text }[init..final]
      init += 5
      final += 5
      dy = Dy.serializableSite(row)
      dy.fii_id = @id
      test_thread(dy) unless Database.get_dy(dy)
    end
    
    @threads.each(&:join)
  end

  def median
    len = @dys_list.length
    (@dys_list[(len - 1) / 2] + @dys_list[len / 2]) / 2.0 if len > 0
  end

  def avarage
    (@dys_list.inject{ |sum, el| sum + el } / @dys_list.size).round(3) if @dys_list.length > 0
  end

  def self.serializable(row)
    id = row[0]
    cod = row[1]
    name = row[2]
    category = row[3]
    category_fii = row[4]
    category_anbima = row[5]
    registro_cvm = row[6]
    num_cotas = row[7]
    num_cotistas = row[8]
    cnpj = row[9]
    taxas = row[10]

    return Fii.new(cod, id, name, category, category_fii, category_anbima, registro_cvm, num_cotas, num_cotistas, cnpj, taxas)
  end
end