class RejectionReasonReport < ActiveRecord::Base
  self.table_name = 'report_rejection_reasons'  
  
  def each_column(&block)                             
    %i(jan feb mar apr may jun jul aug sep oct nov dec
 ytd).map do |col|                                    
      block.call public_send(col)                     
    end                                               
  end 
end
