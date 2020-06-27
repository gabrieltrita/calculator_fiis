class Dy
  attr_accessor :id, :value, :fii_id, :data_base, :data_pagamento, :cotacao_base, :rendimento 

  def initialize(id=nil, value=0.0, fii_id=nil, data_base=nil, data_pagamento=nil, cotacao_base=0.0, rendimento=0.0)
    @id = id
    @value = value.gsub(/\s+/, "")
    @fii_id = fii_id
    @data_base = Date.strptime(data_base, '%d/%m/%y')
    @data_pagamento = Date.strptime(data_pagamento, '%d/%m/%y')
    @cotacao_base = Monetize.parse(cotacao_base).to_f
    @rendimento = Monetize.parse(rendimento).to_f
  end

  def self.serializable(row)
    id = row[0]
    value = row[1]
    fii_id = row[2]
    data_base = row[3]
    data_pagamento = row[4]
    cotacao_base = row[5]
    rendimento = row[6]

    return Dy.new(id, value, fii_id, data_base, data_pagamento, cotacao_base, rendimento)
  end

  def self.serializableSite(row)
    data_base = row[0]
    data_pagamento = row[1]
    cotacao_base = row[2]
    value = row[3]
    rendimento = row[4]

    return Dy.new(nil, value, nil, data_base, data_pagamento, cotacao_base, rendimento)
  end
end