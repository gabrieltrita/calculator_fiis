class Wallet
  def initialize(url)
    @url = url
    @fiis_list = []
  end

  def thread_test(cod)
    p "inserindo o fundo #{cod}"
    fii = Fii.new(cod)
    fii.informations_basics
    fii.informations_taxas
    fii.id = Database.insertFii(fii)
    @fiis_list.append(fii)
  end
  

  def get_fiis(db=false)
    threads = []
    body = open(@url).read
    fiis = (Nokogiri::HTML.parse(body)).css(".ticker")
    p "Foi encontrado #{fiis.length} FIIs"
    
    len = fiis.length
    site_fiis = fiis
    @fiis_list = Database.fiis
    
    site_fiis.each_with_index { |fii, index|
      cod = fii.text.gsub(/\s+/, "")
      if @fiis_list.find { |fii2|  fii2.cod == cod }.nil?
        cod = fii.text.gsub(/\s+/, "")
        threads << Thread.new { thread_test(cod) }
      else
        threads << Thread.new { @fiis_list[index].read_fii() }
      end
    }

    threads.each(&:join)
    Database.get.close if db
  end

  def get_dys()
    @fiis_list.each(&:dys)
  end
end