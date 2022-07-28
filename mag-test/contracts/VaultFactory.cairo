%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import (
    get_caller_address, get_contract_address, get_block_timestamp
)
from contracts.utils.utils import felt_to_uint256, uint256_div, uint256_percent, uint256_pow


from starkware.cairo.common.math import (
    assert_not_zero,
    assert_not_equal,
    assert_le,
)


from starkware.cairo.common.alloc import (
    alloc,
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

from openzeppelin.access.ownable import Ownable


from contracts.interfaces.IFuccount import IFuccount

from contracts.interfaces.IFeeManager import IFeeManager, FeeConfig

from contracts.interfaces.IPolicyManager import IPolicyManager

from contracts.interfaces.IIntegrationManager import IIntegrationManager

from contracts.interfaces.IPontisPriceFeedMixin import IPontisPriceFeedMixin

from contracts.interfaces.IERC20 import IERC20


#
# Events
#

@event
func FeeManagerSet(feeManagerAddress: felt):
end

@event
func OracleSet(feeManagerAddress: felt):
end

@event
func FuccountActivated(fuccountAddress: felt):
end

const APPROVE_SELECTOR = 949021990203918389843157787496164629863144228991510976554585288817234167820
const BUYSHARE_SELECTOR = 1739160585925371971880668508720131927045855609588612196644536989289532392537
const SELLSHARE_SELECTOR = 481719463807444873104482035153189208627524278231225222947146558976722465517
# const addAllowedDepositors_SELECTOR = 876865433

const POW18 = 1000000000000000000
const POW20 = 100000000000000000000

struct Integration:
    member contract : felt
    member selector : felt
    member integration: felt
end
#
# Storage
#
@storage_var
func owner() -> (res: felt):
end

@storage_var
func nominatedOwner() -> (res: felt):
end


@storage_var
func oracle() -> (res: felt):
end

@storage_var
func feeManager() -> (res: felt):
end

@storage_var
func policyManager() -> (res: felt):
end

@storage_var
func integrationManager() -> (res: felt):
end

@storage_var
func valueInterpretor() -> (res: felt):
end

@storage_var
func primitivePriceFeed() -> (res: felt):
end

@storage_var
func approvePreLogic() -> (res: felt):
end

@storage_var
func sharePriceFeed() -> (res : felt):
end

@storage_var
func assetManagerVaultAmount(assetManager: felt) -> (res: felt):
end

@storage_var
func assetManagerVault(assetManager: felt, vaultId: felt) -> (res: felt):
end

@storage_var
func vaultAmount() -> (res: felt):
end

@storage_var
func idToVault(id: felt) -> (res: felt):
end

@storage_var
func stackingVault() -> (res : felt):
end

@storage_var
func daoTreasury() -> (res : felt):
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

func onlyDependenciesSet{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}():
    let (areDependenciesSet_:felt) = areDependenciesSet()
    with_attr error_message("onlyDependenciesSet:Dependencies not set"):
        assert areDependenciesSet_ = 1
    end
    return ()
end

func onlyAssetManager{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(_fund:felt):
    let (caller_:felt) = get_caller_address()
    let (assetManager_:felt) = IFuccount.getManagerAccount(_fund)
    with_attr error_message("addAllowedDepositors: caller is not asset manager"):
        assert caller_ = assetManager_
    end
    return ()
end

#
# Getters 
#

@view
func areDependenciesSet{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    alloc_locals
    let (oracle_:felt) = getOracle()
    let (feeManager_:felt) = getFeeManager()
    let (policyManager_:felt) = getPolicyManager()
    let (integrationManager_:felt) = getIntegrationManager()
    let (valueInterpretor_:felt) = getValueInterpretor()
    let (primitivePriceFeed_:felt) = getPrimitivePriceFeed()
    let (approvePreLogic_:felt) = getApprovePreLogic()
    let  mul_:felt = approvePreLogic_  * oracle_ * feeManager_ * policyManager_ * integrationManager_ * valueInterpretor_ * primitivePriceFeed_
    let (isZero_:felt) = __is_zero(mul_)
    if isZero_ == 1:
        return (res = 0)
    else:
        return (res = 1)
    end
end

@view
func getOwner{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = Ownable.owner()
    return(res)
end



@view
func getOracle{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = oracle.read()
    return(res)
end


@view
func getFeeManager{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = feeManager.read()
    return(res)
end

@view
func getPolicyManager{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = policyManager.read()
    return(res)
end

@view
func getIntegrationManager{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = integrationManager.read()
    return(res)
end

@view
func getValueInterpretor{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = valueInterpretor.read()
    return(res)
end

@view
func getPrimitivePriceFeed{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = primitivePriceFeed.read()
    return(res)
end

@view
func getApprovePreLogic{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = approvePreLogic.read()
    return(res)
end

@view
func getSharePriceFeed{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = sharePriceFeed.read()
    return(res)
end

@view
func getDaoTreasury{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = daoTreasury.read()
    return(res)
end

@view
func getStackingVault{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = stackingVault.read()
    return(res)
end

#get Vault info helper to fetch info for the frontend, to be removed once tracker is implemented

@view
func getUserVaultAmount{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_user:felt) -> (res: felt):
    let(res:felt) = assetManagerVaultAmount.read(_user)
    return (res=res)
end

@view
func getUserVault{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_user:felt, _vaultId: felt) -> (res: felt):
    let(res:felt) = assetManagerVault.read(_user, _vaultId)
    with_attr error_message("getVaultAddressFromCallerAndId: Vault not found"):
        assert_not_zero(res)
    end
    return (res=res)
end

@view
func getVaultAmount{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (res: felt):
    let(res:felt) = vaultAmount.read()
    return (res=res)
end


@view
func getVaultFromId{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_vaultId: felt) -> (res: felt):
    let(res:felt) = idToVault.read(_vaultId)
    with_attr error_message("getVaultAddressFromId: Vault not found"):
        assert_not_zero(res)
    end
    return (res=res)
end


#
# Setters
#

@external
func transferOwnership{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }(new_owner: felt):
    Ownable.transfer_ownership(new_owner)
    return ()
end



@external
func setOracle{
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
func setFeeManager{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _feeManager: felt,
    ):
    Ownable.assert_only_owner()
    feeManager.write(_feeManager)
    return ()
end


@external
func setPolicyManager{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _policyManager: felt,
    ):
    Ownable.assert_only_owner()
    policyManager.write(_policyManager)
    return ()
end

@external
func setIntegrationManager{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _integrationManager: felt,
    ):
    Ownable.assert_only_owner()
    integrationManager.write(_integrationManager)
    return ()
end

@external
func setValueInterpretor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _valueInterpretor : felt):
    Ownable.assert_only_owner()
    valueInterpretor.write(_valueInterpretor)
    return ()
end

@external
func setPrimitivePriceFeed{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _primitivePriceFeed : felt):
    Ownable.assert_only_owner()
    primitivePriceFeed.write(_primitivePriceFeed)
    return ()
end

@external
func setApprovePreLogic{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _approvePreLogic : felt):
    Ownable.assert_only_owner()
    approvePreLogic.write(_approvePreLogic)
    return ()
end

@external
func setSharePriceFeed{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _sharePriceFeed : felt):
    Ownable.assert_only_owner()
    sharePriceFeed.write(_sharePriceFeed)
    return ()
end




@external
func setStackingVault{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _stackingVault : felt):
    Ownable.assert_only_owner()
    stackingVault.write(_stackingVault)
    return ()
end

@external
func setDaoTreasury{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _daoTreasury : felt):
    Ownable.assert_only_owner()
    daoTreasury.write(_daoTreasury)
    return ()
end


@external
func addGlobalAllowedAsset{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_assetList_len:felt, _assetList:felt*) -> ():
    alloc_locals
    Ownable.assert_only_owner()
    onlyDependenciesSet()
    let (integrationManager_:felt) = integrationManager.read()
    __addGlobalAllowedAsset(_assetList_len, _assetList, integrationManager_)
    return ()
end

@external
func addGlobalAllowedExternalPosition{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_externalPositionList_len:felt, _externalPositionList:felt*) -> ():
    alloc_locals
    Ownable.assert_only_owner()
    onlyDependenciesSet()
    let (integrationManager_:felt) = integrationManager.read()
    __addGlobalAllowedExternalPosition(_externalPositionList_len, _externalPositionList, integrationManager_)
    return ()
end

@external
func addGlobalAllowedIntegration{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_integrationList_len:felt, _integrationList:Integration*) -> ():
    alloc_locals
    Ownable.assert_only_owner()
    onlyDependenciesSet()
    let (integrationManager_:felt) = integrationManager.read()
    __addGlobalAllowedIntegration(_integrationList_len, _integrationList, integrationManager_)
    return()
end



#asset manager

@external
func addAllowedDepositors{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_fund:felt, _depositors_len:felt, _depositors:felt*) -> ():
    alloc_locals
    onlyAssetManager(_fund)
    let (policyManager_:felt) = policyManager.read()
    let (isPublic_:felt) = IPolicyManager.checkIsPublic(policyManager_, _fund)
    with_attr error_message("addAllowedDepositors: the fund is already public"):
        assert isPublic_ = 0
    end
   __addAllowedDepositors(_fund, _depositors_len, _depositors)
    return ()
end


@external
func initializeFund{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(
    #vault initializer
    _fund: felt,
    _fundName:felt,
    _fundSymbol:felt,
    _denominationAsset:felt,
    _amount: Uint256,
    _shareAmount: Uint256,
    
    #fee config Initializer
    _feeConfig_len: felt,
    _feeConfig: felt*,

    _maxAmount: Uint256,
    _minAmount: Uint256,

    #Timelock before selling shares
    _timelock:felt,
    #allowed depositors 
    _isPublic:felt,
    ):
    alloc_locals
    onlyDependenciesSet()
    let (feeManager_:felt) = feeManager.read()
    let (policyManager_:felt) = policyManager.read()
    let (integrationManager_:felt) = integrationManager.read()
    let (primitivePriceFeed_:felt) = primitivePriceFeed.read()
    let (name_:felt) = IFuccount.getName(_fund)
    with_attr error_message("initializeFund: vault already initialized"):
        assert name_ = 0
    end
    with_attr error_message("initializeFund: can not set value to 0"):
        assert_not_zero(_fund * _fundName * _fundSymbol * _denominationAsset)
    end

    let (assetManager_: felt) = get_caller_address()

    #Fuccount activater
    IFuccount.activater(_fund, _fundName, _fundSymbol, assetManager_, _denominationAsset)

    #check allowed amount, min amount > decimal/1000 & share amount in [1, 100]
    let (decimals_:felt) = IERC20.decimals(_denominationAsset)
    let (minInitialAmount_:Uint256) = uint256_pow(Uint256(10,0), decimals_ - 3)
    let (allowedAmount_:felt) = uint256_le(minInitialAmount_, _amount) 
    let (allowedShareAmount1_:felt) = uint256_le(_shareAmount, Uint256(POW20,0))
    let (allowedShareAmount2_:felt) = uint256_le(Uint256(POW18,0), _shareAmount)
    with_attr error_message("initializeFund: not allowed Amount"):
        assert allowedAmount_ *  allowedShareAmount1_ * allowedShareAmount2_= 1
    end

    #save fund and add it to the global allowed integrations
    let (currentAssetManagerVaultAmount_: felt) = assetManagerVaultAmount.read(assetManager_)
    assetManagerVault.write(assetManager_, currentAssetManagerVaultAmount_, _fund)
    assetManagerVaultAmount.write(assetManager_, currentAssetManagerVaultAmount_ + 1)
    let (currentVaultAmount:felt) = vaultAmount.read()
    vaultAmount.write(currentVaultAmount + 1)
    idToVault.write(currentVaultAmount, _fund)

    # let _integrationList_len:felt = 2   
    # let (_integrationList:Integration*) = alloc()
    # assert _integrationList[0].contract = _fund
    # assert _integrationList[0].selector = BUYSHARE_SELECTOR
    # assert _integrationList[0].integration = 0
    # assert _integrationList[Integration.SIZE].contract = _fund
    # assert _integrationList[Integration.SIZE].selector = SELLSHARE_SELECTOR
    # assert _integrationList[Integration.SIZE].integration = 0
    #  __addGlobalAllowedIntegration(_integrationList_len, _integrationList, integrationManager_)
     

    # shares have 18 decimals
    let (amountPow18_:Uint256, _) = uint256_mul(_amount, Uint256(POW18,0))
    let (sharePricePurchased_:Uint256) = uint256_div(amountPow18_ , _shareAmount)
    IFuccount.mintFromVF(_fund, assetManager_, _shareAmount, sharePricePurchased_)
    IERC20.transferFrom(_denominationAsset, assetManager_, _fund, _amount)
    
    #Set feeconfig for vault
    let entrance_fee = _feeConfig[0]
    let (is_entrance_fee_not_enabled) = __is_zero(entrance_fee)
    if is_entrance_fee_not_enabled == 1 :
        IFeeManager.setFeeConfig(feeManager_, _fund, FeeConfig.ENTRANCE_FEE_ENABLED, 0)
    else:
        with_attr error_message("initializeFund: entrance fee must be between 0 and 10"):
            assert_le(entrance_fee, 10)
        end
        IFeeManager.setFeeConfig(feeManager_, _fund, FeeConfig.ENTRANCE_FEE_ENABLED, 1)
        IFeeManager.setFeeConfig(feeManager_, _fund, FeeConfig.ENTRANCE_FEE, entrance_fee)
    end

    let exit_fee = _feeConfig[1]
    let (is_exit_fee_not_enabled) = __is_zero(exit_fee)
    if is_exit_fee_not_enabled == 1 :
        IFeeManager.setFeeConfig(feeManager_, _fund, FeeConfig.EXIT_FEE_ENABLED, 0)
    else:
        with_attr error_message("initializeFund: exit fee must be between 0 and 10"):
            assert_le(exit_fee, 10)
        end
        IFeeManager.setFeeConfig(feeManager_, _fund, FeeConfig.EXIT_FEE_ENABLED, 1)
        IFeeManager.setFeeConfig(feeManager_, _fund, FeeConfig.EXIT_FEE, exit_fee)
    end

    let performance_fee = _feeConfig[2]
    let (is_performance_fee_not_enabled) = __is_zero(performance_fee)
    if is_performance_fee_not_enabled == 1 :
        IFeeManager.setFeeConfig(feeManager_, _fund, FeeConfig.PERFORMANCE_FEE_ENABLED, 0)
    else:
        with_attr error_message("initializeFund: performance fee must be between 0 and 20"):
            assert_le(performance_fee, 20)
        end
        IFeeManager.setFeeConfig(feeManager_, _fund, FeeConfig.PERFORMANCE_FEE_ENABLED, 1)
        IFeeManager.setFeeConfig(feeManager_, _fund, FeeConfig.PERFORMANCE_FEE, performance_fee)
    end

    let management_fee = _feeConfig[3]
    let (is_management_fee_not_enabled) = __is_zero(management_fee)
    if is_management_fee_not_enabled == 1 :
        IFeeManager.setFeeConfig(feeManager_, _fund, FeeConfig.MANAGEMENT_FEE, 0)
    else:
        with_attr error_message("initializeFund: management fee must be between 0 and 20"):
            assert_le(management_fee, 20)
        end
        IFeeManager.setFeeConfig(feeManager_, _fund, FeeConfig.MANAGEMENT_FEE_ENABLED, 1)
        IFeeManager.setFeeConfig(feeManager_, _fund, FeeConfig.MANAGEMENT_FEE, management_fee)
        let (timestamp_:felt) = get_block_timestamp()
        IFeeManager.setClaimedTimestamp(feeManager_, _fund, timestamp_)
    end

    # Policy config for fund
    IPolicyManager.setMaxminAmount(policyManager_, _fund, _maxAmount, _minAmount)
    IPolicyManager.setTimelock(policyManager_, _fund, _timelock)
    IPolicyManager.setIsPublic(policyManager_, _fund, _isPublic)
    return ()
end

func __is_zero{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        x: felt)-> (res:felt):
    if x == 0:
        return (res=1)
    end
    return (res=0)
end

func __addGlobalAllowedAsset{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_assetList_len:felt, _assetList:felt*, _integrationManager:felt) -> ():
    alloc_locals
    Ownable.assert_only_owner()
    if _assetList_len == 0:
        return ()
    end
    let asset_:felt = [_assetList]
    let (approvePreLogic_:felt) = getApprovePreLogic()
    IIntegrationManager.setAvailableAsset(_integrationManager, asset_)
    IIntegrationManager.setAvailableIntegration(_integrationManager, asset_, APPROVE_SELECTOR, approvePreLogic_)

    let newAssetList_len:felt = _assetList_len -1
    let newAssetList:felt* = _assetList + 1

    return __addGlobalAllowedAsset(
        _assetList_len= newAssetList_len,
        _assetList= newAssetList,
        _integrationManager= _integrationManager
        )
end

func __addGlobalAllowedExternalPosition{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_externalPositionList_len:felt, _externalPositionList:felt*, _integrationManager:felt) -> ():
    alloc_locals
    Ownable.assert_only_owner()
    if _externalPositionList_len == 0:
        return ()
    end
    let externalPosition_:felt = [_externalPositionList]
    IIntegrationManager.setAvailableExternalPosition(_integrationManager, externalPosition_)

    let newExternalPositionList_len:felt = _externalPositionList_len -1
    let newExternalPositionList:felt* = _externalPositionList + 1

    return __addGlobalAllowedExternalPosition(
        _externalPositionList_len= newExternalPositionList_len,
        _externalPositionList= newExternalPositionList,
        _integrationManager= _integrationManager
        )
end

func __addGlobalAllowedIntegration{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_integrationList_len:felt, _integrationList:Integration*, _integrationManager:felt) -> ():
    alloc_locals
    if _integrationList_len == 0:
        return ()
    end

    let integration_:Integration = [_integrationList]
    IIntegrationManager.setAvailableIntegration(_integrationManager, integration_.contract, integration_.selector, integration_.integration)

    let newIntegrationList_len:felt = _integrationList_len -1
    let newIntegrationList:Integration* = _integrationList + 3

    return __addGlobalAllowedIntegration(
        _integrationList_len= newIntegrationList_len,
        _integrationList= newIntegrationList,
        _integrationManager=_integrationManager
        )
end

func __addAllowedDepositors{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_fund:felt, _depositors_len:felt, _depositors:felt*) -> ():
    alloc_locals
    if _depositors_len == 0:
        return ()
    end
    let (policyManager_:felt) = policyManager.read()
    let depositor_:felt = [_depositors]
    IPolicyManager.setAllowedDepositor(policyManager_, _fund, depositor_)

    let newDepositors_len:felt = _depositors_len -1
    let newDepositors:felt* = _depositors + 1

    return __addAllowedDepositors(
        _fund = _fund,
        _depositors_len= newDepositors_len,
        _depositors= newDepositors,
        )
end
