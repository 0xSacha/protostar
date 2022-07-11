# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.interfaces.IVault import IVault
from starkware.cairo.common.math import assert_not_zero

    # func swapExactTokensForTokens(
    #     token_from_address: felt,
    #     token_to_address: felt,
    #     amount_token_from: Uint256,
    #     amount_token_to_min: Uint256) 
    #     -> (amount_out_received: Uint256):
    # end

@external
func runPreLogic{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr 
    }(_vault:felt, _callData_len:felt, _callData:felt*):
    let incomingAsset_:felt = [_callData + 1]
    let (isTrackedAsset_:felt) = IVault.isTrackedAsset(_vault, incomingAsset_)
    with_attr error_message("swapExactTokensForTokensFromAlphaRoad: incoming Asset not tracked"):
        assert_not_zero(isTrackedAsset_)
    end
    return()
end
