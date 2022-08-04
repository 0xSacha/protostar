# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.IntegrationManager import integration


@contract_interface
namespace IIntegrationManager:


    func setAvailableAsset(_asset: felt):
    end
    func setAvailableExternalPosition(_asset: felt):
    end

    func setAvailableIntegration(_contract: felt, _selector: felt, _integration:felt):
    end

 
    func checkIsContractIntegrated(_contract: felt) -> (res: felt):
    end

    func checkIsAssetAvailable(_asset: felt) -> (res: felt):
    end

    func checkIsIntegrationAvailable(_contract: felt, _selector: felt) -> (res: felt):
    end

    func checkIsExternalPositionAvailable(_externalPosition:felt) -> (res: felt): 
    end

    func getIntegration(_contract: felt, _selector: felt) -> (res: felt):
    end

    func getAvailableExternalPositions () -> (availableAssets_len : felt,  availableAssets:felt*):
    end

    func getAvailableAssets() -> (availableAssets_len :felt,  availableAssets:felt*):
    end

    func getAvailableIntegrations() -> (availableIntegrations_len:felt, availableIntegrations: integration*): 
    end
end
