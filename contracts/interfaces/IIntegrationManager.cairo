# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

struct integration:
    member contract : felt
    member selector : felt
end



@contract_interface
namespace IIntegrationManager:


    func setAvailableAsset(_asset: felt):
    end
    func setAvailableExternalPosition(_asset: felt):
    end

    func setAvailableIntegration(_contract: felt, _selector: felt, _integration:felt, _level:felt):
    end

 
    func isContractIntegrated(_contract: felt) -> (res: felt):
    end

    func isAvailableAsset(asset: felt) -> (res: felt):
    end

    func isAvailableIntegration(contract: felt, selector:felt) -> (res: felt): 
    end

    func isAvailableExternalPosition(external_position: felt) -> (is_available_external_position: felt): 
    end

    func isAvailableShare(_share: felt) -> (res: felt): 
    end

    func isIntegratedContract(contract: felt) -> (res: felt): 
    end

    

    func getIntegration(_contract: felt, _selector: felt) -> (res: felt):
    end

    func getIntegrationRequiredLevel(_contract: felt, _selector: felt) -> (res: felt):
    end

    func getAvailableExternalPositions () -> (availableAssets_len : felt,  availableAssets:felt*):
    end

    func getAvailableAssets() -> (availableAssets_len :felt,  availableAssets:felt*):
    end

    func getAvailableShares() -> (availableShares_len: felt, availableShares:felt*):
    end

    func getAvailableIntegrations() -> (availableIntegrations_len:felt, availableIntegrations: integration*): 
    end
end
