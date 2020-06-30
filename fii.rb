class Fii
  attr_accessor :id, :cod, :name,:category, 
    :category_anbima, :category_fii, :registro_cvm, 
    :num_cotas, :num_cotistas, :cnpj, :taxas, :parsed_data, 
    :dys_list, :preco_cota, :dividend_yeild_aux, :ultimo_rendimento, :patrimonio_liquido,
    :patrimonio_liquido_base, :valor_patrimonial, :num_negociacoes
  
  def initialize(cod='', id=nil, name='', category='', category_fii='', category_anbima='', registro_cvm=nil, num_cotas=0.0, num_cotistas=0, cnpj='', taxas='', preco_cota='', dividend_yeild_aux=nil, ultimo_rendimento=nil, patrimonio_liquido=nil, patrimonio_liquido_base=nil, valor_patrimonial=nil, num_negociacoes=0)
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
    @preco_cota = preco_cota
    @dividend_yeild_aux = dividend_yeild_aux
    @ultimo_rendimento = ultimo_rendimento
    @patrimonio_liquido = patrimonio_liquido
    @patrimonio_liquido_base = patrimonio_liquido_base
    @valor_patrimonial = valor_patrimonial
    @num_negociacoes = num_negociacoes
    @threads = []
  end

  def read_fii()
    if @parsed_data.nil?
      begin
        @parsed_data = Nokogiri::HTML.parse((open("https://fiis.com.br/#{@cod}/").read))
      rescue
        p "Problema para ler o fundo #{@cod} no fiis.com.br"
        return false
      end
    end
    return true
  end

  def informations_basics
    value = @parsed_data.css('div.row .value')
    @name = value[0].text
    @category = 'Fundo imobiliario'
    @category_fii = value[1].text
    @category_anbima = value[2].text
    @registro_cvm = value[3].text
    @num_cotas = value[4].text
    @num_cotistas = value[5].text
    @cnpj = value[6].text
    begin
      @num_negociacoes = Nokogiri::HTML.parse((open("https://www.fundsexplorer.com.br/funds/#{@cod}").read)).css('span.indicator-value').first.text.strip.to_i
    rescue
      @num_negociacoes = nil
      p "Fundo #{@cod} nao encontrado no found explorer" 
    end

    [@name, @category, @category_fii, @category_anbima, @registro_cvm, @num_cotas, @num_cotistas, @cnpj, @num_negociacoes]
  end

  def informations_precos
    @preco_cota = @parsed_data.css('div.item.quotation span.value').text.gsub!(",",".")
    indexes = @parsed_data.css('div#informations--indexes div.item span.value')
    
    @dividend_yeild_aux = indexes[0].text.gsub!(',', '.')[0..-2]
    @ultimo_rendimento = indexes[1].text.gsub!(',', '.')[2..-1]
    @patrimonio_liquido = indexes[2].text.gsub!(',', '.')[2..-3]
    @patrimonio_liquido_base = indexes[2].text[-1]
    @valor_patrimonial = indexes[3].text.tr('.', '').gsub(',', '.')[2..-1]

    p [@dividend_yeild_aux, @ultimo_rendimento, @patrimonio_liquido, @patrimonio_liquido_base, @valor_patrimonial]
  end

  def informations_taxas
    @taxas = @parsed_data.css('.taxas').text
  end

  def get_dys_db
    Database.find_all_dys_from_fii_id @id
  end


  def dys
    if read_fii()
      aux = -2
      table = @parsed_data.css('table#last-revenues--table tbody')[0]
      html = table.css('td')
      init = 0
      final = 4
      threads = []
      while final < html.size do
        row = html.map{ |td| td.text }[init..final]
        init += 5
        final += 5
        @threads << Thread.new { 
          dy = Database.find_dy_from_data_base(row[0], @id) || Database.insert_dy(row, @id)
          @dys_list.append(dy)
        }
      end
      
      @threads.each(&:join)
    end
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
    dividend_yeild_aux = row[11]
    ultimo_rendimento = row[12]
    patrimonio_liquido = row[13]
    patrimonio_liquido_base = row[14]
    valor_patrimonial = row[15]
    num_negociacoes = row[16]
    return Fii.new(cod, id, name, category, category_fii, category_anbima, registro_cvm, num_cotas, num_cotistas, cnpj, taxas, dividend_yeild_aux, ultimo_rendimento, patrimonio_liquido, patrimonio_liquido_base, valor_patrimonial, num_negociacoes)
  end
end