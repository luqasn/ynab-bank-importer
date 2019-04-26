class Dumper
  # Implements logic to fetch transactions via the Fints protocol
  # and implements methods that convert the response to meaningful data.
  class QIF < Dumper
    require 'qif'
    require 'digest/md5'

    def initialize(params = {})
      @ynab_id  = params.fetch('ynab_id')
      @exec  = params.fetch('exec')
      @format  = params.fetch('format', nil)
    end

    def fetch_transactions
      output = `#{@exec}`
      if !$?.success?
        raise "Command '#{@exec}' failed"
      end

      qif = Qif::Reader.new(output, @format)

      qif.transactions.map { |t| to_ynab_transaction(t) }
    end

    private

    def account_id
      @ynab_id
    end

    def date(transaction)
      transaction.date
    end

    def payee_name(transaction)
      transaction.payee
    end

    def payee_iban(transaction)
      nil
    end

    def memo(transaction)
      transaction.memo
    end

    def amount(transaction)
      (transaction.amount.to_f * 1000).to_i
    end

    def withdrawal?(transaction)
      memo = memo(transaction)
      return nil unless memo

      memo.include?('Atm') || memo.include?('Bargeld')
    end

    def import_id(transaction)
      memo_hash = Digest::MD5.hexdigest(memo(transaction))
      "QIF:#{amount(transaction)}:#{date(transaction)}:#{memo_hash[0...8]}"
    end
  end
end