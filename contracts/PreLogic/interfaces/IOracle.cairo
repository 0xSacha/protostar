# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

@contract_interface
namespace IOracle:
    
    func get_decimals(key : felt) -> (decimals : felt):
    end


    func get_value(key : felt, aggregation_mode : felt) -> (
            value : felt, last_updated_timestamp : felt):
    end

    
end
