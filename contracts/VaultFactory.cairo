%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    get_block_timestamp,
    get_block_number
)

from contracts.utils.utils import felt_to_uint256, uint256_div, uint256_percent, uint256_pow


from starkware.cairo.common.math import (
    assert_not_zero,
    assert_not_equal,
    assert_le,
)

from starkware.cairo.common.find_element import (
    find_element,
)


from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_sub,
    uint256_check,
    uint256_le,
    uint256_eq,
    uint256_add,
    uint256_mul,
    uint256_unsigned_div_rem,
)


from contracts.interfaces.IFuccount import IFuccount

from contracts.interfaces.IFeeManager import IFeeManager, FeeConfig

from contracts.interfaces.IPolicyManager import IPolicyManager

from contracts.interfaces.IIntegrationManager import IIntegrationManager

from contracts.PreLogic.interfaces.IOraclePriceFeedMixin import IOraclePriceFeedMixin

from contracts.PreLogic.interfaces.IValueInterpretor import IValueInterpretor

from contracts.interfaces.IERC20 import IERC20

from openzeppelin.access.ownable.library import Ownable

from openzeppelin.security.safemath.library import SafeUint256

#
# Events
#

@event
func fee_manager_set(fee_managerAddress: felt):
end

@event
func oracle_set(fee_managerAddress: felt):
end

@event
func fuccount_activated(fuccountAddress: felt):
end

const APPROVE_SELECTOR = 949021990203918389843157787496164629863144228991510976554585288817234167820
const DEPOSIT_SELECTOR = 352040181584456735608515580760888541466059565068553383579463728554843487745
const REEDEM_SELECTOR = 481719463807444873104482035153189208627524278231225222947146558976722465517

const POW18 = 1000000000000000000
const POW20 = 100000000000000000000

struct Integration:
    member contract : felt
    member selector : felt
    member integration: felt
    member level: felt
end
#
# Storage
#
@storage_var
func owner() -> (res: felt):
end

@storage_var
func nominated_owner() -> (res: felt):
end


@storage_var
func oracle() -> (res: felt):
end

@storage_var
func fee_manager() -> (res: felt):
end

@storage_var
func policy_manager() -> (res: felt):
end

@storage_var
func integration_manager() -> (res: felt):
end

@storage_var
func value_interpretor() -> (res: felt):
end

@storage_var
func primitive_price_feed() -> (res: felt):
end

@storage_var
func approve_prelogic() -> (res: felt):
end

@storage_var
func share_price_feed() -> (res : felt):
end

@storage_var
func asset_manager_vault_amount(assetManager: felt) -> (res: felt):
end

@storage_var
func asset_manager_vault(assetManager: felt, vaultId: felt) -> (res: felt):
end

@storage_var
func vault_amount() -> (res: felt):
end

@storage_var
func id_to_vault(id: felt) -> (res: felt):
end

@storage_var
func stacking_vault() -> (res : felt):
end

@storage_var
func dao_treasury() -> (res : felt):
end

@storage_var
func dao_treaury_fee() -> (res : felt):
end

@storage_var
func stacking_vault_fee() -> (res : felt):
end

@storage_var
func max_fund_level() -> (res : felt):
end

@storage_var
func stacking_dispute() -> (res : felt):
end

@storage_var
func guarantee_ratio() -> (res : felt):
end

@storage_var
func exit_timestamp() -> (res : felt):
end

@storage_var
func close_fund_request(fund: felt) -> (res : felt):
end

@storage_var
func isGuarenteeWithdrawable(fund: felt) -> (res : felt):
end


#
# Constructor 
#


@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner: felt):
   Ownable.initializer(owner)
    return ()
end


#
# Modifier 
#

func only_dependencies_set{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}():
    let (are_dependencies_set_:felt) = are_dependencies_set()
    with_attr error_message("only_dependencies_set:Dependencies not set"):
        assert are_dependencies_set_ = 1
    end
    return ()
end

func only_asset_manager{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(_fund:felt):
    let (caller_:felt) = get_caller_address()
    let (assetManager_:felt) = IFuccount.getManagerAccount(_fund)
    with_attr error_message("add_allowed_depositors: caller is not asset manager"):
        assert caller_ = assetManager_
    end
    return ()
end

#
# Getters 
#

@view
func are_dependencies_set{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    alloc_locals
    let (oracle_:felt) = get_oracle()
    let (fee_manager_:felt) = get_fee_manager()
    let (policy_manager_:felt) = get_policy_manager()
    let (integration_manager_:felt) = get_integration_manager()
    let (value_interpretor_:felt) = get_value_interpretor()
    let (primitive_price_feed_:felt) = get_primitive_price_feed()
    let (approve_prelogic_:felt) = get_approve_prelogic()
    let (max_fund_level_:felt) = get_max_fund_level()
    let (stacking_dispute_: felt) = get_stacking_dispute()
    let (guarantee_ratio_: felt) = get_guarantee_ratio()
    let (exit_timestamp_: felt) = get_exit_timestamp()
    let  mul_:felt = approve_prelogic_  * oracle_ * fee_manager_ * policy_manager_ * integration_manager_ * value_interpretor_ * primitive_price_feed_ * max_fund_level_ * stacking_dispute_ * exit_timestamp_
    let (isZero_:felt) = __is_zero(mul_)
    if isZero_ == 1:
        return (res = 0)
    else:
        return (res = 1)
    end
end

@view
func get_owner{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = Ownable.owner()
    return(res)
end



@view
func get_oracle{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = oracle.read()
    return(res)
end


@view
func get_fee_manager{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = fee_manager.read()
    return(res)
end

@view
func get_policy_manager{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = policy_manager.read()
    return(res)
end

@view
func get_integration_manager{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = integration_manager.read()
    return(res)
end

@view
func get_value_interpretor{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = value_interpretor.read()
    return(res)
end

@view
func get_primitive_price_feed{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = primitive_price_feed.read()
    return(res)
end

@view
func get_approve_prelogic{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = approve_prelogic.read()
    return(res)
end

@view
func get_share_price_feed{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = share_price_feed.read()
    return(res)
end

@view
func get_dao_treasury{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = dao_treasury.read()
    return(res)
end

@view
func get_stacking_vault{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = stacking_vault.read()
    return(res)
end

@view
func get_stacking_vault_fee{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = stacking_vault_fee.read()
    return(res)
end

@view
func get_dao_treasury_fee{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = dao_treaury_fee.read()
    return(res)
end

@view
func get_max_fund_level{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = max_fund_level.read()
    return(res)
end

@view
func get_stacking_dispute{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (res: felt):
    let(res:felt) = stacking_dispute.read()
    return (res=res)
end

@view
func get_guarantee_ratio{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (res: felt):
    let(res:felt) = guarantee_ratio.read()
    return (res=res)
end

@view
func get_exit_timestamp{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (res: felt):
    let(res:felt) = exit_timestamp.read()
    return (res=res)
end



#get Vault info helper to fetch info for the frontend, to be removed once tracker is implemented

@view
func get_user_vault_amount{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_user:felt) -> (res: felt):
    let(res:felt) = asset_manager_vault_amount.read(_user)
    return (res=res)
end

@view
func get_user_vault{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_user:felt, _vaultId: felt) -> (res: felt):
    let(res:felt) = asset_manager_vault.read(_user, _vaultId)
    with_attr error_message("getVaultAddressFromCallerAndId: Vault not found"):
        assert_not_zero(res)
    end
    return (res=res)
end

@view
func get_vault_amount{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (res: felt):
    let(res:felt) = vault_amount.read()
    return (res=res)
end

@view
func get_vault_from_id{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_vaultId: felt) -> (res: felt):
    let(res:felt) = id_to_vault.read(_vaultId)
    with_attr error_message("getVaultAddressFromId: Vault not found"):
        assert_not_zero(res)
    end
    return (res=res)
end

@view
func getCloseFundRequest{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_fund: felt) -> (res: felt):
    let(closeFundRequest_:felt) = close_fund_request.read(_fund)
    return (res=closeFundRequest_)
end

@view
func getManagerGuaanteeRatio{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_fund: felt) -> (res: felt):
    let (baseGuaranteeRatio_) = guarantee_ratio.read()
    ##TODO KYC + soulbound consideration
    return (res=baseGuaranteeRatio_)
end


#
# Setters
#

@external
func transfer_ownership{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }(new_owner: felt):
    Ownable.transfer_ownership(new_owner)
    return ()
end



@external
func set_orcale{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _oracle: felt,
    ):
    Ownable.assert_only_owner()
    oracle.write(_oracle)
    return ()
end

@external
func set_fee_manager{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _fee_manager: felt,
    ):
    Ownable.assert_only_owner()
    fee_manager.write(_fee_manager)
    return ()
end


@external
func set_policy_manager{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _policy_manager: felt,
    ):
    Ownable.assert_only_owner()
    policy_manager.write(_policy_manager)
    return ()
end

@external
func set_integration_manager{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _integration_manager: felt,
    ):
    Ownable.assert_only_owner()
    integration_manager.write(_integration_manager)
    return ()
end

@external
func set_value_interpretor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _value_interpretor : felt):
    Ownable.assert_only_owner()
    value_interpretor.write(_value_interpretor)
    return ()
end

@external
func set_primitive_price_feed{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _primitive_price_feed : felt):
    Ownable.assert_only_owner()
    primitive_price_feed.write(_primitive_price_feed)
    return ()
end

@external
func set_approve_prelogic{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _approve_prelogic : felt):
    Ownable.assert_only_owner()
    approve_prelogic.write(_approve_prelogic)
    return ()
end

@external
func set_share_price_feed{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _share_price_feed : felt):
    Ownable.assert_only_owner()
    share_price_feed.write(_share_price_feed)
    return ()
end


@external
func set_stacking_vault{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _stackingVault : felt):
    Ownable.assert_only_owner()
    stacking_vault.write(_stackingVault)
    return ()
end

@external
func set_dao_treasury{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _dao_treasury : felt):
    Ownable.assert_only_owner()
    dao_treasury.write(_dao_treasury)
    return ()
end

@external
func set_stacking_vault_fee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _stackingVaultFee : felt):
    Ownable.assert_only_owner()
    stacking_vault_fee.write(_stackingVaultFee)
    return ()
end

@external
func set_dao_treasury_fee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _dao_treasuryFee : felt):
    Ownable.assert_only_owner()
    dao_treaury_fee.write(_dao_treasuryFee)
    return ()
end

@external
func set_max_fund_level{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _max_fund_level : felt):
    Ownable.assert_only_owner()
    max_fund_level.write(_max_fund_level)
    return ()
end

@external
func set_stacking_dispute{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _stacking_dispute : felt):
    Ownable.assert_only_owner()
    stacking_dispute.write(_stacking_dispute)
    return ()
end

@external
func set_guarantee_ratio{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _guarantee_ratio : felt):
    Ownable.assert_only_owner()
    guarantee_ratio.write(_guarantee_ratio)
    return ()
end

@external
func set_exit_timestamp{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _exit_timestamp : felt):
    Ownable.assert_only_owner()
    exit_timestamp.write(_exit_timestamp)
    return ()
end



@external
func add_global_allowed_asset{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_assetList_len:felt, _assetList:felt*) -> ():
    alloc_locals
    Ownable.assert_only_owner()
    only_dependencies_set()
    let (integration_manager_:felt) = integration_manager.read()
    __add_global_allowed_asset(_assetList_len, _assetList, integration_manager_)
    return ()
end

@external
func add_global_allowed_external_position{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_externalPositionList_len:felt, _externalPositionList:felt*) -> ():
    alloc_locals
    Ownable.assert_only_owner()
    only_dependencies_set()
    let (integration_manager_:felt) = integration_manager.read()
    __add_global_allowed_external_position(_externalPositionList_len, _externalPositionList, integration_manager_)
    return ()
end

@external
func add_global_allowed_integration{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(allowed_integrations_len:felt, allowed_integrations:Integration*) -> ():
    alloc_locals
    Ownable.assert_only_owner()
    only_dependencies_set()
    let (integration_manager_:felt) = integration_manager.read()
    add_global_allowed_integration(allowed_integrations_len, allowed_integrations, integration_manager_)
    return()
end



#asset manager

@external
func add_allowed_depositors{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(fund:felt, depositors_len:felt, depositors:felt*) -> ():
    alloc_locals
    only_asset_manager(fund)
    let (policy_manager_:felt) = policy_manager.read()
    let (is_public_:felt) = IPolicyManager.isPublic(policy_manager_, fund)
    with_attr error_message("add_allowed_depositors: the fund is already public"):
        assert is_public_ = 0
    end
   add_allowed_depositors(fund, depositors_len, depositors)
    return ()
end


@external
func initialize_fund{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
    #vault initializer
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
    alloc_locals
    only_dependencies_set()
    let (fee_manager_:felt) = fee_manager.read()
    let (policy_manager_:felt) = policy_manager.read()
    let (integration_manager_:felt) = integration_manager.read()
    let (value_interpretor_:felt) = value_interpretor.read()
    let (primitive_price_feed_:felt) = primitive_price_feed.read()
    let (name_:felt) = IFuccount.getName(_fund)

    with_attr error_message("initialize_fund: vault already initialized"):
        assert name_ = 0
    end
    with_attr error_message("initialize_fund: can not set value to 0"):
        assert_not_zero(_fund * _fundName * _fundSymbol * _denominationAsset)
    end

    let (isAllowedDenominationAsset:felt) = IIntegrationManager.checkIsAssetAvailable(integration_manager_, _denominationAsset)
    with_attr error_message("initialize_fund: can not set value to 0"):
        assert isAllowedDenominationAsset = 1
    end

    let (assetManager_: felt) = get_caller_address()

    #check allowed amount, min amount > decimal/1000 & share amount in [1, 100]
    let (decimals_:felt) = IERC20.decimals(_denominationAsset)
    let (minInitialAmount_:Uint256) = uint256_pow(Uint256(10,0), decimals_ - 3)
    let (allowedAmount_:felt) = uint256_le(minInitialAmount_, _amount) 
    let (allowedShareAmount1_:felt) = uint256_le(_shareAmount, Uint256(POW20,0))
    let (allowedShareAmount2_:felt) = uint256_le(Uint256(POW18,0), _shareAmount)
    with_attr error_message("initialize_fund: not allowed Amount"):
        assert allowedAmount_ *  allowedShareAmount1_ * allowedShareAmount2_= 1
    end

    #save fund and add it to the global allowed integrations
    let (currentasset_manager_vault_amount_: felt) = asset_manager_vault_amount.read(assetManager_)
    asset_manager_vault.write(assetManager_, currentasset_manager_vault_amount_, _fund)
    asset_manager_vault_amount.write(assetManager_, currentasset_manager_vault_amount_ + 1)
    let (currentvault_amount:felt) = vault_amount.read()
    vault_amount.write(currentvault_amount + 1)
    id_to_vault.write(currentvault_amount, _fund)

    
    # ##add integration so other funds can buy/sell shares from it
    let _integrationList_len:felt = 2
    let (_integrationList:Integration*) = alloc()
    assert _integrationList[0] = Integration(_fund, DEPOSIT_SELECTOR, 0, _fundLevel)
    assert _integrationList[1] = Integration(_fund, REEDEM_SELECTOR, 0, _fundLevel)

     add_global_allowed_integration(_integrationList_len, _integrationList, integration_manager_)
     
    ##register the position
    let (share_price_feed_:felt) = get_share_price_feed()
    IValueInterpretor.addDerivative(value_interpretor_, _fund, share_price_feed_)


    # shares have 18 decimals
    let (amountPow18_:Uint256) = SafeUint256.mul(_amount, Uint256(POW18,0))
    let (sharePricePurchased_:Uint256,_) = SafeUint256.div_rem(amountPow18_ , _shareAmount)

    #Fuccount activater
    IFuccount.activater(_fund, _fundName, _fundSymbol, _fundLevel, _denominationAsset, assetManager_, _shareAmount, sharePricePurchased_)
    IERC20.transferFrom(_denominationAsset, assetManager_, _fund, _amount)

    #Set feeconfig for vault
    let entrance_fee = _feeConfig[0]
    let (is_entrance_fee_not_enabled) = __is_zero(entrance_fee)
    if is_entrance_fee_not_enabled == 1 :
        IFeeManager.setFeeConfig(fee_manager_, _fund, FeeConfig.ENTRANCE_FEE_ENABLED, 0)
    else:
        with_attr error_message("initialize_fund: entrance fee must be between 0 and 10"):
            assert_le(entrance_fee, 10)
        end
        IFeeManager.setFeeConfig(fee_manager_, _fund, FeeConfig.ENTRANCE_FEE_ENABLED, 1)
        IFeeManager.setFeeConfig(fee_manager_, _fund, FeeConfig.ENTRANCE_FEE, entrance_fee)
    end

    let exit_fee = _feeConfig[1]
    let (is_exit_fee_not_enabled) = __is_zero(exit_fee)
    if is_exit_fee_not_enabled == 1 :
        IFeeManager.setFeeConfig(fee_manager_, _fund, FeeConfig.EXIT_FEE_ENABLED, 0)
    else:
        with_attr error_message("initialize_fund: exit fee must be between 0 and 10"):
            assert_le(exit_fee, 10)
        end
        IFeeManager.setFeeConfig(fee_manager_, _fund, FeeConfig.EXIT_FEE_ENABLED, 1)
        IFeeManager.setFeeConfig(fee_manager_, _fund, FeeConfig.EXIT_FEE, exit_fee)
    end

    let performance_fee = _feeConfig[2]
    let (is_performance_fee_not_enabled) = __is_zero(performance_fee)
    if is_performance_fee_not_enabled == 1 :
        IFeeManager.setFeeConfig(fee_manager_, _fund, FeeConfig.PERFORMANCE_FEE_ENABLED, 0)
    else:
        with_attr error_message("initialize_fund: performance fee must be between 0 and 20"):
            assert_le(performance_fee, 20)
        end
        IFeeManager.setFeeConfig(fee_manager_, _fund, FeeConfig.PERFORMANCE_FEE_ENABLED, 1)
        IFeeManager.setFeeConfig(fee_manager_, _fund, FeeConfig.PERFORMANCE_FEE, performance_fee)
    end

    let management_fee = _feeConfig[3]
    let (is_management_fee_not_enabled) = __is_zero(management_fee)
    if is_management_fee_not_enabled == 1 :
        IFeeManager.setFeeConfig(fee_manager_, _fund, FeeConfig.MANAGEMENT_FEE, 0)
    else:
        with_attr error_message("initialize_fund: management fee must be between 0 and 20"):
            assert_le(management_fee, 60)
        end
        IFeeManager.setFeeConfig(fee_manager_, _fund, FeeConfig.MANAGEMENT_FEE_ENABLED, 1)
        IFeeManager.setFeeConfig(fee_manager_, _fund, FeeConfig.MANAGEMENT_FEE, management_fee)
    end

    # Policy config for fund
    IPolicyManager.setIsPublic(policy_manager_, _fund, _isPublic)
    return ()
end

@external
func request_close_fund{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _fund: felt)-> ():
        only_asset_manager(_fund)
        let (notLiquidGav_:Uint256) = IFuccount.calculNotLiquidGav(_fund)
        with_attr error_message("request_close_fund: remove your positions first"):
            assert_not_zero(notLiquidGav_.low)
        end
        let (currentTimesTamp_) = get_block_timestamp()
        close_fund_request.write(_fund, currentTimesTamp_)
        IFuccount.close(_fund)
    return ()
end

# @external
# func execute_close_fund{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
#         _fund: felt)-> ():
#         only_asset_manager(_fund)
#         let (timestampRequest:felt) = close_fund_request.read(_fund)
#         with_attr error_message("execute_close_fund: no request registered"):
#             assert_not_zero(timestampRequest)
#         end
#         let (currentTimesTamp_) = get_block_timestamp()
#         let (timestampRequest:felt) = close_fund_request.read(_fund)
#         let (exitTimestamp_:felt) = exitTimestamp
#         with_attr error_message("execute_close_fund: execute request time not reached"):
#             assert_le(timestampRequest + exitTimestamp_, currentTimesTamp_)
#         end
#         IFuccount.closeFund(_fund)
#         close_fund_request.write(_fund, 0)
#     return ()
# end

func __is_zero{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        x: felt)-> (res:felt):
    if x == 0:
        return (res=1)
    end
    return (res=0)
end

func __add_global_allowed_asset{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_assetList_len:felt, _assetList:felt*, _integration_manager:felt) -> ():
    alloc_locals
    Ownable.assert_only_owner()
    if _assetList_len == 0:
        return ()
    end

    let asset_:felt = [_assetList]
    let (VI_:felt) = value_interpretor.read()
    let (PPF_:felt) = primitive_price_feed.read()
    let (isSupportedPrimitiveAsset_) = IOraclePriceFeedMixin.checkIsSupportedPrimitiveAsset(PPF_,asset_)
    let (isSupportedDerivativeAsset_) = IValueInterpretor.checkIsSupportedDerivativeAsset(VI_,asset_)
    let (notAllowed_) = __is_zero(isSupportedPrimitiveAsset_ + isSupportedDerivativeAsset_)
    with_attr error_message("only_dependencies_set:Dependencies not set"):
        assert notAllowed_ = 0
    end
    
    let (approve_prelogic_:felt) = get_approve_prelogic()
    IIntegrationManager.setAvailableAsset(_integration_manager, asset_)
    IIntegrationManager.setAvailableIntegration(_integration_manager, asset_, APPROVE_SELECTOR, approve_prelogic_, 1)

    let newAssetList_len:felt = _assetList_len -1
    let newAssetList:felt* = _assetList + 1

    return __add_global_allowed_asset(
        _assetList_len= newAssetList_len,
        _assetList= newAssetList,
        _integration_manager= _integration_manager
        )
end

func __add_global_allowed_external_position{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_externalPositionList_len:felt, _externalPositionList:felt*, _integration_manager:felt) -> ():
    alloc_locals
    Ownable.assert_only_owner()
    if _externalPositionList_len == 0:
        return ()
    end
    let externalPosition_:felt = [_externalPositionList]
    let (VI_:felt) = value_interpretor.read()
    let (isSupportedExternalPosition_) = IValueInterpretor.checkIsSupportedExternalPosition(VI_,externalPosition_)
    with_attr error_message("__add_global_allowed_external_position: PriceFeed not set"):
        assert isSupportedExternalPosition_ = 1
    end

    IIntegrationManager.setAvailableExternalPosition(_integration_manager, externalPosition_)
    
    let newExternalPositionList_len:felt = _externalPositionList_len -1
    let newExternalPositionList:felt* = _externalPositionList + 1

    return __add_global_allowed_external_position(
        _externalPositionList_len= newExternalPositionList_len,
        _externalPositionList= newExternalPositionList,
        _integration_manager= _integration_manager
        )
end

func add_global_allowed_integration{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_integrationList_len:felt, _integrationList:Integration*, _integration_manager:felt) -> ():
    alloc_locals
    if _integrationList_len == 0:
        return ()
    end

    let integration_:Integration = [_integrationList]
    IIntegrationManager.setAvailableIntegration(_integration_manager, integration_.contract, integration_.selector, integration_.integration, integration_.level)

    return add_global_allowed_integration(
        _integrationList_len= _integrationList_len - 1,
        _integrationList= _integrationList + Integration.SIZE,
        _integration_manager=_integration_manager
        )
end

func add_allowed_depositors{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_fund:felt, _depositors_len:felt, _depositors:felt*) -> ():
    alloc_locals
    if _depositors_len == 0:
        return ()
    end
    let (policy_manager_:felt) = policy_manager.read()
    let depositor_:felt = [_depositors]
    IPolicyManager.setAllowedDepositor(policy_manager_, _fund, depositor_)

    let newDepositors_len:felt = _depositors_len -1
    let newDepositors:felt* = _depositors + 1

    return add_allowed_depositors(
        _fund = _fund,
        _depositors_len= newDepositors_len,
        _depositors= newDepositors,
        )
end
