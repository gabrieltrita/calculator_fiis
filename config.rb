$semaphore = Mutex.new
Money.default_currency='BRL'
Money.rounding_mode=BigDecimal::SIGN_POSITIVE_FINITE

configure { set :server, :puma } 