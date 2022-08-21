# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IPolicyManager:

    #setters
    func setIsPublic(_fund: felt, _isPublic: felt):
    end
    func setAllowedDepositor(_fund: felt, _depositor: felt):
    end
    func setAllowedAssetToReedem(_fund: felt, _asset: felt):
    end

    #getters
    func isPublic(_fund:felt)-> (res : felt):
    end

    func isAllowedDepositor(_fund:felt, _depositor:felt)-> (res : felt):
    end

    func allowedDepositors(_fund:felt) -> (allowedDepositor_len: felt, allowedDepositor:felt*):
    end

    func isAllowedAssetToReedem(fund : felt, asset : felt) -> (is_allowed_asset_to_reedem : felt): 
    end

    func allowedAssetsToReedem(fund:felt) -> (allowed_assets_to_reedem_len: felt, allowed_assets_to_reedem:felt*): 
    end


end