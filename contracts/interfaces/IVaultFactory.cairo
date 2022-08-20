%lang starknet

from starkware.cairo.common.uint256 import Uint256

struct Integration:
    member contract : felt
    member selector : felt
    member integration: felt
end
#
@contract_interface
namespace IVaultFactory:

    func getOwner() -> (res : felt):
    end

    func getOracle() -> (res : felt):
    end

    func getFeeManager() -> (res : felt):
    end

    func getPolicyManager() -> (res : felt):
    end

    func getIntegrationManager() -> (res : felt):
    end

    func getPrimitivePriceFeed() -> (res : felt):
    end

    func getValueInterpretor() -> (res : felt):
    end

    func getDaoTreasury() -> (res : felt):
    end

    func getStackingVault() -> (res : felt):
    end

    func getDaoTreasuryFee() -> (res : felt):
    end

    func getStackingVaultFee() -> (res : felt):
    end

    func getMaxFundLevel() -> (res : felt):
    end

    func getStackingDispute() -> (res : felt):
    end

    func getGuaranteeRatio() -> (res : felt):
    end

    func getExitTimestamp() -> (res : felt):
    end

    func getCloseFundRequest(fund: felt) -> (res : felt):
    end

    func getManagerGuaanteeRatio(account: felt) -> (res : felt):
    end

    

    ##Business


    func initializeFund(
    _fund: felt,
    _fundLevel: felt,
    _fundName:felt,
    _fundSymbol:felt,
    _denominationAsset:felt,
    _amount: Uint256,
    _shareAmount: Uint256,
    _feeConfig_len: felt,
    _feeConfig: felt*,
    _isPublic:felt,
    ):
    end

    func addAllowedDepositors(_fund:felt, _depositors_len:felt, _depositors:felt*):
    end

    func addGlobalAllowedIntegration(_integrationList_len:felt, _integrationList:Integration*):
    end

    func addGlobalAllowedExternalPosition(_externalPositionList_len:felt, _externalPositionList:felt*):
    end

    func addGlobalAllowedAsset(_assetList_len:felt, _assetList:felt*):
    end

    func setFeeManager(_feeManager:felt):
    end

    func setPolicyManager(_policyManager:felt):
    end

    func setIntegrationManager(_integrationManager:felt):
    end

    func setValueInterpretor(_valueInterpretor:felt):
    end

    func setOracle(_oracle:felt):
    end

    func setPrimitivePriceFeed(_primitivePriceFeed:felt):
    end

    func setApprovePreLogic(_approvePreLogic:felt):
    end

    func setSharePriceFeed(_sharePriceFeed:felt):
    end

    func setStackingVault(_stackingVault:felt):
    end

    func setDaoTreasury(_daoTreasury:felt):
    end

    func setStackingVaultFee(_stackingVault:felt):
    end

    func setDaoTreasuryFee(_daoTreasury:felt):
    end

    func setMaxFundLevel(_maxFundLevel:felt):
    end

    func setStackingDispute(_stackingDispute:felt):
    end

    func setGuaranteeRatio(_guaranteeRatio:felt):
    end

    func setExitTimestamp(_exitTimestamp:felt):
    end

end
