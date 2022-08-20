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
    fund: felt,
    fundLevel: felt,
    fundName:felt,
    fundSymbol:felt,
    denominationAsset:felt,
    amount: Uint256,
    shareAmount: Uint256,
    feeConfig_len: felt,
    feeConfig: felt*,
    isPublic:felt,
    ):
    end

    func add_allowed_depositors(_fund:felt, _depositors_len:felt, _depositors:felt*):
    end

    func add_global_allowed_integration(allowed_integrations_len:felt, allowed_integrations:Integration*):
    end

    func add_global_allowed_external_position(externalPositionList_len:felt, externalPositionList:felt*):
    end

    func add_global_allowed_asset(assetList_len:felt, assetList:felt*):
    end


    func set_fee_manager(fee_manager:felt):
    end

    func set_policy_manager(policy_manager:felt):
    end

    func set_integration_manager(integration_manager:felt):
    end

    func set_value_interpretor(value_interpretor:felt):
    end

    func set_orcale(oracle:felt):
    end

    func set_primitive_price_feed(primitive_price_feed:felt):
    end

    func set_approve_prelogic(approve_prelogic:felt):
    end

    func set_share_price_feed(share_price_feed:felt):
    end

    func set_stacking_vault(stacking_vault:felt):
    end

    func set_dao_treasury(dao_treasury:felt):
    end

    func set_stacking_vault_fee(stacking_vault_fee:felt):
    end

    func set_dao_treasury_fee(dao_treasury_fee:felt):
    end

    func set_max_fund_level(max_fund_level:felt):
    end

    func set_stacking_dispute(stacking_dispute:felt):
    end

    func set_guarantee_ratio(guarantee_ratio:felt):
    end

    func set_exit_timestamp(exit_timestamp:felt):
    end

end
