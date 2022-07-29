# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IPolicyManager:

    func setMaxminAmount(vault: felt, max : Uint256, min:Uint256):
    end
    func setAllowedIntegration(_vault: felt, _contract: felt, _selector: felt):
    end
    func setAllowedTrackedAsset(_vault: felt, _asset: felt):
    end
    func setAllowedTrackedExternalPosition(_vault: felt, _externalPosition: felt):
    end
    func setTimelock(_vault: felt, _blocAmount: felt):
    end
    func setIsPublic(_vault: felt, _isPublic: felt):
    end
    func setAllowedDepositor(_vault: felt, _depositor: felt):
    end
    
    
    #getters
    func getMaxminAmount(_vault: felt) -> (max : Uint256, min: Uint256):
    end
    func checkIsAllowedTrackedAsset(_vault: felt, _asset: felt) -> (res : felt):
    end
    func checkIsAllowedTrackedExternalPosition(_vault: felt, _externalPosition: felt)-> (res : felt):
    end
    func checkIsAllowedIntegration(_vault: felt, _contract: felt, _selector: felt)-> (res : felt):
    end
    func getTimelock(_vault:felt)-> (res : felt):
    end
    func checkIsPublic(_vault:felt)-> (res : felt):
    end
    func checkIsAllowedDepositor(_vault:felt, _depositor:felt)-> (res : felt):
    end
end