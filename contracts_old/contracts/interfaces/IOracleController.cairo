%lang starknet

@contract_interface
namespace IOracleController:

    #
    # Oracle Implementation Controller Functions
    #

    func get_decimals(key : felt) -> (decimals : felt):
    end


    func get_value(key : felt, aggregation_mode : felt) -> (
            value : felt, last_updated_timestamp : felt):
    end

end