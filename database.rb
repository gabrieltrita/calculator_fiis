class Database
  def self.get(create=true)
    unless @db
      p "ininciando db de fiis..."
      begin
        @db = SQLite3::Database.open 'fiis.db'
        p @db.get_first_value 'SELECT SQLITE_VERSION()'
        create_tables() if create
      rescue SQLite3::Exception => e 
        p "Exception occurred"
        p e
      end
    end
    @db
  end

  def self.insertFii(data)
    begin
      query = '''INSERT INTO Fii(
                  codigo, 
                  name, 
                  category, 
                  category_fii, 
                  category_anbima, 
                  registro_cvm, 
                  num_cotas, 
                  num_cotistas, 
                  cnpj, 
                  taxas) 
                  VALUES(?,?,?,?,?,?,?,?,?,?)'''
      
      stm = get.prepare query
      stm.bind_param 1, data.cod
      stm.bind_param 2, data.name
      stm.bind_param 3, data.category
      stm.bind_param 4, data.category_fii
      stm.bind_param 5, data.category_anbima
      stm.bind_param 6, data.registro_cvm
      stm.bind_param 7, data.num_cotas
      stm.bind_param 8, data.num_cotistas
      stm.bind_param 9, data.cnpj
      stm.bind_param 10, data.taxas
      stm.execute
      stm.close
      p "inserido #{data} na tabela fii"
      (get.execute "SELECT ID FROM Fii WHERE codigo LIKE '#{data.cod}'").first.first
    rescue SQLite3::Exception => e 
      p e
    end
  end

  def self.insertDy(data)
    begin
      query = '''INSERT INTO Dys(
                  dy,
                  fii_id, 
                  data_base, 
                  data_pagamento, 
                  cotacao_base, 
                  rendimento) VALUES(?,?,?,?,?,?)'''
      stm = get.prepare query
      stm.bind_param 1, data.value
      stm.bind_param 2, data.fii_id
      stm.bind_param 3, data.data_base.to_s
      stm.bind_param 4, data.data_pagamento.to_s
      stm.bind_param 5, data.cotacao_base
      stm.bind_param 6, data.rendimento
      id = -1
      $semaphore.synchronize {
        test = stm.execute
        stm.close
        id = get.last_insert_row_id
        p "inserido dy de id #{id}"
      }
      id
    rescue SQLite3::Exception => e 
      p e 
    end
  end

  def self.fiis()
    fiis = []
    begin
      query_search = "SELECT * FROM Fii"
      stm = get.execute query_search
      stm.each { |fii|
        _fii = Fii.serializable(fii)
        fiis.append(_fii)
      }
    rescue SQLite3::Exception => e 
      p e
    end
    fiis
  end

  def self.get_dy(dy)
    query = "SELECT * FROM dys WHERE data_base = ? and fii_id = ?"
    stm = get.prepare query
    stm.bind_param 1, dy.data_base.to_s
    stm.bind_param 2, dy.fii_id
    return !stm.execute.next.nil?
  end

  private

  def self.create_tables
    query_table_fii = '''CREATE TABLE IF NOT EXISTS Fii(
                          id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                          codigo VARCHAR(10) NOT NULL,
                          name VARCHAR(255) NOT NULL,
                          category VARCHAR(255) NOT NULL,
                          category_fii VARCHAR(255) NOT NULL,
                          category_anbima VARCHAR(255),
                          registro_cvm DATE,
                          num_cotas DOUBLE,
                          num_cotistas INTEGER,
                          cnpj VARCHAR(25),
                          taxas TEXT);'''

    query_table_dys = '''CREATE TABLE IF NOT EXISTS Dys(
                          id INTEGER PRIMARY KEY AUTOINCREMENT,
                          dy DOUBLE NOT NULL,
                          fii_id INTERGER NOT NULL,
                          data_base DATE NOT NULL,
                          data_pagamento DATE,
                          cotacao_base DOUBLE NOT NULL,
                          rendimento DOUBLE,
                          FOREIGN KEY(fii_id) REFERENCES fii(id));'''

    get.execute query_table_fii
    get.execute query_table_dys
  end
end