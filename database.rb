class Database
  def self.get(create=true)
    unless @db
      begin
        @db = SQLite3::Database.open 'fiis.db'
        create_tables() if create
      rescue SQLite3::Exception => e 
        p e
      end
    end
    @db
  end

  def self.insert_fii(data)
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
                  taxas,
                  preco_cota,
                  dividend_yeild_aux,
                  ultimo_rendimento,
                  patrimonio_liquido,
                  patrimonio_liquido_base,
                  valor_patrimonial,
                  num_negociacoes)
                  VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)'''
      
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
      stm.bind_param 11, data.preco_cota
      stm.bind_param 12, data.dividend_yeild_aux
      stm.bind_param 13, data.ultimo_rendimento
      stm.bind_param 14, data.patrimonio_liquido
      stm.bind_param 15, data.patrimonio_liquido_base
      stm.bind_param 16, data.valor_patrimonial
      stm.bind_param 17, data.num_negociacoes
      stm.execute
      stm.close
      (get.execute "SELECT ID FROM Fii WHERE codigo LIKE '#{data.cod}'").first.first
    rescue SQLite3::Exception => e 
      p e
    end
  end

  def self.insert_dy(row, fii_id)
    begin
      data = Dy.serializableSite(row)
      data.fii_id = fii_id
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
      $semaphore.synchronize {
        stm.execute
        data.id = get.last_insert_row_id
      }
    rescue Exception => e 
      p "ERROR #{e}"
      return nil
    end

    return data
  end

  def self.find_dy_from_data_base(data_base, fii_id)
    query = "SELECT * FROM dys WHERE data_base = ? AND fii_id = ?"
    dy = nil
    begin
      stm = get.prepare query
      stm.bind_param 1, data_base
      stm.bind_param 2, fii_id
      rs = stm.execute
      result = rs.next
      while result
        dy = Dy.serializable(result)
        result = rs.next
      end
      stm.close
    rescue Exception => e
      p "ERROR: #{e}"
      return nil
    end

    return dy
  end

  def self.find_all_fiis
    fiis = all("fii")
    return fiis.map { |fii| Fii.serializable(fii) }
  end

  def self.find_all_dys
    dys = all("dys")
    return dys.map { |dy| Dy.serializable(dy) }
  end

  def self.find_all_dys_from_fii_id(fii_id)
    query = "SELECT * FROM dys WHERE fii_id = ?"
    dys = []
    begin
      stm = get.prepare query
      stm.bind_param 1, fii_id
      rs = stm.execute
      result = rs.next
      while rs.next
        dys.append(Dy.serializable(result))
        result = rs.next
      end

      stm.close
    rescue Exception => e
      p "ERROR: #{e}"
      return []
    end

    return dys
  end

  private

  def self.all(table_name)
    query = "SELECT * FROM #{table_name} "
    objects = []
    threads = []
    
    begin
      stm = get.execute query
      stm.each { |row| threads << Thread.new { objects.append(row) } }
      threads.each(&:join)
    rescue SQLite3::Exception => e 
      p "Erro ao fazer a busca de todos os elementos da tabela #{table_name}"
      return []
    end

    return objects
  end

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
                          taxas TEXT,
                          dividend_yeild_aux DOUBLE,
                          ultimo_rendimento DOUBLE,
                          patrimonio_liquido DOUBLE,
                          patrimonio_liquido_base VARCHAR(1),
                          valor_patrimonial DOUBLE,
                          preco_cota DOUBLE,
                          num_negociacoes INTEGER);'''

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