class Wallet
  def initialize(url)
    @url = url
    @fiis_list = []
  end

  def thread_test(cod)
    fii = Fii.new(cod)
    if fii.read_fii()
      fii.informations_basics
      fii.informations_taxas
      fii.informations_precos
      fii.id = Database.insert_fii(fii)
      @fiis_list.append(fii)
      p fii.ultimo_rendimento
    end
  end
  

  def get_fiis(db=false)
    threads = []
    body = open(@url).read
    fiis = (Nokogiri::HTML.parse(body)).css(".ticker")
    p "Foi encontrado #{fiis.length} FIIs"
    
    len = fiis.length
    site_fiis = fiis
    @fiis_list = Database.find_all_fiis
    site_fiis.each_with_index { |fii, index|
      cod = fii.text.gsub(/\s+/, "")
      if @fiis_list.find { |fii2|  fii2.cod == cod }.nil?
        cod = fii.text.gsub(/\s+/, "")
        threads << Thread.new { thread_test(cod) }
      end
    }

    threads.each(&:join)
    @fiis_list
  end

  def get_fiis_db
    @fiis_list = Database.find_all_fiis
  end

  def get_dys()
    @fiis_list.each(&:dys)
  end

  def fii_top_high_yield
    list_fundos_desenvolvimento = [
      'Desenvolvimento para Renda Gestão Ativa',
      'Desenvolvimento para Renda Gestão Passiva',
      'Desenvolvimento para Venda Gestão Ativa',
      'Desenvolvimento para Venda Gestão Passiva',
    ]

    
  end
end