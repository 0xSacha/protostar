%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import (
    get_caller_address, 
    get_contract_address,
    call_contract,
)
from contracts.interfaces.IVaultFactory import IVaultFactory

from starkware.cairo.common.math import (
    assert_not_zero,
    assert_not_equal,
    assert_le,
    unsigned_div_rem,
)


from contracts.utils.utils import felt_to_uint256, uint256_div, uint256_percent, uint256_pow

from starkware.cairo.common.bool import TRUE

from starkware.starknet.common.syscalls import get_block_timestamp

from starkware.cairo.common.memcpy import memcpy

from openzeppelin.token.erc20.interfaces.IERC20 import IERC20

from contracts.interfaces.IFeeManager import FeeConfig, IFeeManager
from contracts.interfaces.IPolicyManager import IPolicyManager


from starkware.cairo.common.alloc import (
    alloc,
)

from starkware.cairo.common.find_element import (
    find_element,
)

from contracts.interfaces.IIntegrationManager import IIntegrationManager
from contracts.interfaces.IValueInterpretor import IValueInterpretor

from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_sub,
    uint256_check,
    uint256_le,
    uint256_eq,
    uint256_add,
    uint256_mul,
)


from openzeppelin.security.safemath import SafeUint256


from contracts.interfaces.IVault import (
    VaultAction,
)


from contracts.ERC1155Shares import ERC1155Shares

const POW18 = 1000000000000000000
const PRECISION = 1000000
const SECOND_YEAR = 31536000



#
# Structs
#

struct AssetInfo:
    member address : felt
    member amount : Uint256
    member valueInDeno : Uint256
end

struct PositionInfo:
    member address : felt
    member valueInDeno : Uint256
end

#
# Storage
#

@storage_var
func vaultFactory() -> (res : felt):
end

@storage_var
func managerAccount() -> (res : felt):
end

@storage_var
func denominationAsset() -> (res : felt):
end


#
# Events
#

@event
func AssetWithdrawn(assetAddress: felt, targetAddress: felt, amount: Uint256):
end



namespace Fund:

    #
    # Initializer
    #

    func initializer{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        _vaultFactory: felt,
    ):
        with_attr error_message("constructor: cannot set the vaultFactory to the zero address"):
        assert_not_zero(_vaultFactory)
        end
        vaultFactory.write(_vaultFactory)
        return ()
    end

    #
    # Activater
    #

    func activater{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        _fundName: felt,
        _fundSymbol: felt,
        _uri: felt,
        _denominationAsset: felt,
        _managerAccount:felt,
    ):
    onlyVaultFactory()
    ERC1155Shares.initializeShares(_fundName, _fundSymbol, _uri)
    denominationAsset.write(_denominationAsset)
    managerAccount.write(_managerAccount)
    return ()
    end

    #
    # Guards
    #

    func assert_only_self{syscall_ptr : felt*}():
        let (self) = get_contract_address()
        let (caller) = get_caller_address()

        with_attr error_message("Fund: caller is not this account"):
            assert self = caller
        end
        return ()
    end

    func onlyVaultFactory{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}():
    let (vaultFactory_) = vaultFactory.read()
    let (caller_) = get_caller_address()
    with_attr error_message("Fund: only callable by the vaultFactory"):
        assert (vaultFactory_ - caller_) = 0
    end
    return ()
    end

    #
    # Getters
    #

func getVaultFactory{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = vaultFactory.read()
    return (res) 
end

func getManagerAccount{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = managerAccount.read()
    return (res) 
end

func getDenominationAsset{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = denominationAsset.read()
    return (res=res)
end


func getAssetBalance{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_asset: felt) -> (assetBalance_: Uint256):
    let (account_:felt) = get_contract_address()
    let (assetBalance_:Uint256) = IERC20.balanceOf(contract_address=_asset, account=account_)
    return (assetBalance_)
end


func getNotNulAssets{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (notNulAssets_len:felt, notNulAssets: AssetInfo*):
    alloc_locals
    let (IM_:felt) = __getIntegrationManager()
    let (availableAssets_len: felt, availableAssets:felt*) = IIntegrationManager.getAvailableAssets(IM_)
    let (local notNulAssets : AssetInfo*) = alloc()
    let (notNulAssets_len:felt) = completeNonNulAssetTab(availableAssets_len, availableAssets, 0, notNulAssets)    
    return(notNulAssets_len, notNulAssets)
end


func completeNonNulAssetTab{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(availableAssets_len:felt, availableAssets:felt*, notNulAssets_len:felt, notNulAssets:AssetInfo*) -> (notNulAssets_len:felt):
    alloc_locals
    if availableAssets_len == 0:
        return (notNulAssets_len)
    end
    let newAvailableAssets_len = availableAssets_len - 1
    let assetIndex_:felt = availableAssets[newAvailableAssets_len] 
    let (assetBalance_:Uint256) = getAssetBalance(assetIndex_)
    let (isZero_:felt) = __is_zero(assetBalance_.low)
    if isZero_ == 0:
        assert notNulAssets[notNulAssets_len*AssetInfo.SIZE].address = assetIndex_
        assert notNulAssets[notNulAssets_len*AssetInfo.SIZE].amount = assetBalance_
        let (denominationAsset_:felt) = denominationAsset.read()
        let (assetValue:Uint256) = getAssetValue(assetIndex_, assetBalance_, denominationAsset_)
        assert notNulAssets[notNulAssets_len*AssetInfo.SIZE].valueInDeno = assetValue
        let newNotNulAssets_len = notNulAssets_len + 1
         return completeNonNulAssetTab(
        availableAssets_len=newAvailableAssets_len,
        availableAssets= availableAssets,
        notNulAssets_len=newNotNulAssets_len,
        notNulAssets=notNulAssets,
        )
    end

    return completeNonNulAssetTab(
        availableAssets_len=newAvailableAssets_len,
        availableAssets= availableAssets,
        notNulAssets_len=notNulAssets_len,
        notNulAssets=notNulAssets,
        )
end


func getNotNulPositions{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (notNulPositions_len:felt, notNulPositition: felt*):
    alloc_locals
    let (IM_:felt) = __getIntegrationManager()
    let (availableExternalPositions_len: felt, availableExternalPositions:felt*) = IIntegrationManager.getAvailableExternalPositions(IM_)
    let (local notNulExternalPositions : PositionInfo*) = alloc()
    let (notNulExternalPositions_len:felt) = completeNonNulPositionTab(availableExternalPositions_len, availableExternalPositions, 0, notNulExternalPositions)    
    return(notNulExternalPositions_len, notNulExternalPositions)
end


func completeNonNulPositionTab{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(availableExternalPositions_len:felt, availableExternalPositions:felt*, notNulExternalPositions_len:felt, notNulExternalPositions:PositionInfo*) -> (notNulExternalPositions_len:felt):
    alloc_locals
    if availableExternalPositions_len == 0:
        return (notNulExternalPositions_len)
    end
    let newAvailableExternalPositions_len = availableExternalPositions_len - 1
    let externalPositionIndex_:felt = availableExternalPositions[availableExternalPositions_len] 
    let (denominationAsset_:felt) = denominationAsset.read()
    let (contractAddress_:felt) = get_contract_address()
    let (VI_:felt) = __getValueInterpretor()
    let (value_:Uint256) = IValueInterpretor.calculAssetValue(VI_, externalPositionIndex_, Uint256(contractAddress_, 0), denominationAsset_)
    let (isZero_:felt) = __is_zero(value_.low)
    if isZero_ == 0:
        assert notNulExternalPositions[notNulExternalPositions_len*PositionInfo.SIZE].address = externalPositionIndex_
        assert notNulExternalPositions[notNulExternalPositions_len*PositionInfo.SIZE].valueInDeno = value_
        let newNotNulExternalPositions_len = notNulExternalPositions_len +1
         return completeNonNulPositionTab(
        availableExternalPositions_len=newAvailableExternalPositions_len,
        availableExternalPositions= availableExternalPositions,
        notNulExternalPositions_len=newNotNulExternalPositions_len,
        notNulExternalPositions=notNulExternalPositions,
        )
    end
         return completeNonNulPositionTab(
        availableExternalPositions_len=newAvailableExternalPositions_len,
        availableExternalPositions= availableExternalPositions,
        notNulExternalPositions_len=notNulExternalPositions_len,
        notNulExternalPositions=notNulExternalPositions,
        )
end


#
# ERC1155 Getters 
#

func totalId{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }() -> (totalSupply_: Uint256):
    let (totalSupply_: Uint256) = ERC1155Shares.totalId()
    return (totalSupply_)
end

func sharesTotalSupply{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }() -> (sharesTotalSupply_: Uint256):
    let (sharesTotalSupply_: Uint256) =  ERC1155Shares.sharesTotalSupply()
    return (sharesTotalSupply_)
end

func name{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (name_: felt):
    let (name_) = ERC1155Shares.name()
    return (name_)
end

func symbol{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (symbol_: felt):
    let (symbol_) = ERC1155Shares.symbol()
    return (symbol_)
end


func balanceOf{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(account: felt, id: Uint256) -> (balance: Uint256):
    let (balance: Uint256) = ERC1155Shares.balanceOf(account, id)
    return (balance)
end

func ownerShares{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(account: felt) -> (assetId_len:felt, assetId:Uint256*, assetAmount_len:felt,assetAmount:Uint256*):
    let (assetId_len:felt, assetId:Uint256*, assetAmount_len:felt,assetAmount:Uint256*) = ERC1155Shares.ownerShares(account)
    return (assetId_len, assetId, assetAmount_len,assetAmount)
end

func balanceOfBatch{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        accounts_len: felt,
        accounts: felt*,
        ids_len: felt,
        ids: Uint256*
    ) -> (balances_len: felt, balances: Uint256*):
    let (balances_len, balances) =  ERC1155Shares.balanceOfBatch(accounts_len, accounts, ids_len, ids)
    return (balances_len, balances)
end

func isApprovedForAll{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(account: felt, operator: felt) -> (isApproved: felt):
    let (is_approved) = ERC1155Shares.isApprovedForAll(account, operator)
    return (is_approved)
end


@external
func setURI{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(uri: felt):
    ERC1155Shares.setURI(uri)
    return ()
end

@external
func setApprovalForAll{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(operator: felt, approved: felt):
    ERC1155Shares.setApprovalForAll(operator, approved)
    return ()
end

@external
func safeTransferFrom{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        from_: felt,
        to: felt,
        id: Uint256,
        amount: Uint256,
        data_len: felt,
        data: felt*
    ):
    ERC1155Shares.safeTransferFrom(from_, to, id, amount, data_len, data)
    return ()
end


@external
func safeBatchTransferFrom{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        from_: felt,
        to: felt,
        ids_len: felt,
        ids: Uint256*,
        amounts_len: felt,
        amounts: Uint256*,
        data_len: felt,
        data: felt*
    ):
    ERC1155Shares.safeBatchTransferFrom(
        from_, to, ids_len, ids, amounts_len, amounts, data_len, data)
    return ()
end

func sharePricePurchased{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(id: Uint256) -> (sharePricePurchased_: Uint256):
    let (sharePricePurchased_: Uint256) = ERC1155Shares.sharePricePurchased(id)
    return (sharePricePurchased_)
end

func getMintedTimesTamp{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(id: Uint256) -> (mintedTimesTamp_: felt):
    let (mintedTimesTamp_:felt) = ERC1155Shares.mintedBlockTimesTamp(id)
    return (mintedTimesTamp_)
end


func getSharePrice{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
     res : Uint256
):
    alloc_locals
    let (gav) = calculGav()
    #shares have 18 decimals
    let (gavPow18_:Uint256,_) = uint256_mul(gav, Uint256(POW18,0))
    let (total_supply) = sharesTotalSupply()
    let (price : Uint256) = uint256_div(gavPow18_, total_supply)
    return (res=price)
end


func getAssetValue{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _asset: felt, _amount: Uint256, _denominationAsset: felt
) -> (res: Uint256):
    let (valueInterpretor_:felt) = __getValueInterpretor()
    let (value_:Uint256) = IValueInterpretor.calculAssetValue(valueInterpretor_, _asset, _amount, _denominationAsset)
    return (res=value_)
end


func calculLiquidGav{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res : Uint256
):
    alloc_locals
    let (assets_len : felt, assets : AssetInfo*) = getNotNulAssets()
    let (gav) = __calculGav1(assets_len, assets)
    return (res=gav)
end

func calculNotLiquidGav{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res : Uint256
):
    alloc_locals
    let (externalPosition_len: felt, externalPosition: PositionInfo*) = getNotNulPositions()
    let (gav) = __calculGav2(externalPosition_len, externalPosition)
    return (res=gav)
end

func calculGav{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res : Uint256
):
    alloc_locals
    let (gav1_) = calculLiquidGav()
    let (gav2_) = calculNotLiquidGav()
    let (gav, _) = uint256_add(gav1_, gav2_)
    return (res=gav)
end



func getManagementFeeValue{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (res:Uint256):
    alloc_locals
    let (feeManager_:felt) = __getFeeManager()
    let (fund_:felt) = get_contract_address()
    let (current_timestamp) = get_block_timestamp()
    let (claimed_timestamp) = IFeeManager.getClaimedTimestamp(feeManager_, fund_)
    let (gav:Uint256) = calculGav()
    let interval_stamps = current_timestamp - claimed_timestamp
    let (interval_days:felt,_) = unsigned_div_rem(interval_stamps, 86400)
    let (APY, _, _, _) = __get_fee(fund_,FeeConfig.MANAGEMENT_FEE, gav)
    let (interval_days_uint256) = felt_to_uint256(interval_days)
    let (temp_total, _) = uint256_mul(APY, interval_days_uint256)
    let (claimAmount_) = uint256_div(temp_total, Uint256(360,0))
    return(res=claimAmount_)
end

func claimManagementFee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _assets_len : felt, _assets : felt*, _percents_len:felt, _percents: felt*,
):
    alloc_locals
    #To think, the fact the asset manager can claim management fees whenever he wants can be an issue, 
    # If an investor buy shares and the asset manager claim these fees just after, it will reduce significantly the share price
    assert_only_self()
    let (fund_:felt) = get_contract_address()
    with_attr error_message("claimManagementFee: tab size not equal"):
        assert _percents_len = _assets_len
    end
    let (totalpercent:felt) = __calculTab100(_percents_len, _percents)
    with_attr error_message("claimManagementFee: sum of percents tab not equal at 100%"):
        assert totalpercent = 100
    end
    let (claimAmount_:Uint256) = getManagementFeeValue()
    let (amounts_ : felt*) = alloc()
    calc_amount_of_each_asset(claimAmount_, _assets_len, _assets, _percents, amounts_)
    let (manager_:felt) = managerAccount.read()
    __transferEachAssetMF(manager_, _assets_len, _assets, amounts_)
    return ()
end


func mintFromVF{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_assetManager : felt, share_amount : Uint256, share_price : Uint256):
    onlyVaultFactory()
    mint(_assetManager, share_amount, share_price)
    return ()
end

func buyShare{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
     _amount: Uint256
):
    alloc_locals
    let (fund_:felt) = get_contract_address()
    let (denominationAsset_:felt) = denominationAsset.read()
    __assertMaxminRange(_amount)
    let (caller_ : felt) = get_caller_address()
    __assertAllowedDepositor(caller_)
    let (fee, fee_assset_manager, fee_treasury, fee_stacking_vault) = __get_fee(fund_, FeeConfig.ENTRANCE_FEE, _amount)

    # transfer fee to fee_treasury, stacking_vault
    let (_managerAccount:felt) = managerAccount.read()
    let (treasury:felt) = __getTreasury()
    let (stacking_vault:felt) = __getStackingVault()

    IERC20.transferFrom(denominationAsset_, caller_, _managerAccount, fee_assset_manager)
    IERC20.transferFrom(denominationAsset_, caller_, treasury, fee_treasury)
    IERC20.transferFrom(denominationAsset_, caller_, stacking_vault, fee_stacking_vault)
    let (amountWithoutFees_) = uint256_sub(_amount, fee)
    IERC20.transferFrom(denominationAsset_, caller_, fund_, amountWithoutFees_)

    let (decimals_:felt) = IERC20.decimals(denominationAsset_)
    let (decimalsPow_:Uint256) = uint256_pow(Uint256(10,0), decimals_)
    let (amountWithoutFeesPow_,_) = uint256_mul(amountWithoutFees_, decimalsPow_)
    let (sharePrice_) = getSharePrice()
    let (shareAmount_) = uint256_div(amountWithoutFeesPow_, sharePrice_)

    # mint share
    mint(caller_, shareAmount_, sharePrice_)

    ##event

    return ()
end



func previewReedem{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id : Uint256,
    amount : Uint256,
    assets_len : felt,
    assets : felt*,
    percents_len : felt,
    percents : felt*,
) -> (callerAmount : Uint256*, managerAmount : Uint256*, stackingVaultAmount : Uint256*, daoTreasuryAmount : Uint256*):
    alloc_locals
    with_attr error_message("sell_share: percents tab and asset tab not same length"):
        assert assets_len = percents_len
    end

    let (fund_:felt) = get_contract_address()
    let (denominationAsset_:felt) = denominationAsset.read()
    let (caller_) = get_caller_address()
    let (totalpercent:felt) = __calculTab100(percents_len, percents)
    with_attr error_message("sell_share: sum of percents tab not equal at 100%"):
        assert totalpercent = 100
    end

    #shareprice retrun price of 10^18 shares 
    let (share_price) = getSharePrice()
    let (sharesValuePow_:Uint256,_) = uint256_mul(share_price, amount)
    let (decimals_:felt) = IERC20.decimals(denominationAsset_)
    let (decimalsPow_:Uint256) = uint256_pow(Uint256(10,0), decimals_)
    let (sharesValue:Uint256,) = uint256_div(sharesValuePow_, decimalsPow_)

    #get amount tab according to share_value and the percents tab 
    let (local amounts : Uint256*) = alloc()
    calc_amount_of_each_asset(sharesValue, assets_len, assets, percents, amounts)

    #calculate the performance 
    let(previous_share_price_:Uint256) = getSharePricePurchased(token_id)
    let(current_share_price_:Uint256) = getSharePrice()
    let(has_performed_) = uint256_le(previous_share_price_, current_share_price_)
    if has_performed_ == 1 :
        let(diff_:Uint256) = SafeUint256.sub_le(current_share_price_, previous_share_price_)
        let(diffPermillion_:Uint256,diffperc_h_) = uint256_mul(diff_, Uint256(PRECISION,0))
        let(perfF_:Uint256)=uint256_div(diffPermillion_, current_share_price_)
        tempvar perf_ = perfF_
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar perf_ = Uint256(0,0)
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end
    let performancePermillion_ = perf_

    #calculate the duration

    let (mintedBlockTimesTamp_:felt) = ERC1155Shares.mintedBlockTimesTamp(id)
    let (currentTimesTamp_:felt) = get_block_timestamp()
    let diff = currentTimesTamp_ - mintedBlockTimesTamp_
    let diff_precision = diff * PRECISION
    let (durationPermillion_) = unsigned_div_rem(diff_precision, SECOND_YEAR)

    let (local callerAmount : Uint256*) = alloc()
    let (local managerAmount : Uint256*) = alloc()
    let (local stackingVaultAmount : Uint256*) = alloc()
    let (local daoTreasuryAmount : Uint256*) = alloc()

    __reedemTab(assets_len, assets, amounts, performancePermillion_, durationPermillion_, fund_, 0, callerAmount, managerAmount, stackingVaultAmount, daoTreasuryAmount)


    return(callerAmount, managerAmount, stackingVaultAmount, daoTreasuryAmount)
end


func __reedemTab{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    len : felt, asset : felt*, amount : Uint256*, performancePermillion : Uint256, durationPermillion : felt, fund : felt,
    tabLen : felt, callerAmount : Uint256*, managerAmount : Uint256*, stackingVaultAmount : Uint256*, daoTreasuryAmount : Uint256*
) -> ():
    alloc_locals
    if len == 0:
        return ()
    end

    let (amount_ : Uint256) = amounts[0]
    let (asset : felt) = assets[0]

    #PERFORMANCE FEES
    let (millionTimePerf:Uint256) = uint256_mul_low(amount_, performancePermillion)
    let (performanceAmount_ : Uint256) = uint256_div(millionTimePerf, PRECISION)
    let (fee0, feeAssetManager0, feeDaoTreasury0, feeStackingVault0) = __get_fee(fund_, FeeConfig.PERFORMANCE_FEE, performanceAmount_)

    let (remainingAmount0_ : Uint256) = uint256_sub(amount_, fee0)

    #MANAGEMENT FEES
    let (millionTimeDuration_:Uint256) = uint256_mul_low(remainingAmount_, durationPermillion)
    let (managementAmount_ : Uint256) = uint256_div(millionTimeDuration_, PRECISION)
    let (fee1, feeAssetManager1, feeDaoTreasury1, feeStackingVault1) = __get_fee(fund_, FeeConfig.MANAGEMENT_FEE, managementAmount_)

    let (remainingAmount1_ : Uint256) = uint256_sub(remainingAmount0_, fee1)
    let (cumulativeFeeAssetManager1 : Uint256) = uint256_add(feeAssetManager0, feeAssetManager1)
    let (cumulativeFeeStackingVault1 : Uint256) = uint256_add(feeStackingVault0, feeStackingVault1)
    let (cumulativeFeeDaoTreasury1 : Uint256) = uint256_add(feeDaoTreasury0, feeDaoTreasury1)

    #EXIT FEES
    let (fee2, feeAssetManager2, feeDaoTreasury2, feeStackingVault2) = __get_fee(fund_, FeeConfig.EXIT_FEE, amount_)
    let (remainingAmount2_ : Uint256) = uint256_sub(remainingAmount1_, fee2)
    let (cumulativeFeeAssetManager2 : Uint256) = uint256_add(cumulativeFeeAssetManager1, feeAssetManager2)
    let (cumulativeFeeStackingVault2 : Uint256) = uint256_add(cumulativeFeeStackingVault1, feeStackingVault2)
    let (cumulativeFeeDaoTreasury2 : Uint256) = uint256_add(cumulativeFeeDaoTreasury1, feeDaoTreasury2)

    let newLen_ = len - 1 
    let newAsset_ = [asset + 1]
    let newAmount_ = [amount + Uint256.SIZE]
    let newTabLen = tabLen + 1
    assert [callerAmount + Uint256.SIZE*tabLen] = remainingAmount2_
    assert [managerAmount + Uint256.SIZE*tabLen] = cumulativeFeeAssetManager2
    assert [stackingVaultAmount + Uint256.SIZE*tabLen] = cumulativeFeeStackingVault2
    assert [daoTreasuryAmount + Uint256.SIZE*tabLen] = cumulativeFeeDaoTreasury2

    return __reedemTab(newLen_, newAsset_, newAmount_, performancePermillion, durationPermillion, fund, newTabLen, callerAmount, managerAmount, stackingVaultAmount, daoTreasuryAmount)
end


func sellShare{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id : Uint256,
    amount : Uint256,
    assets_len : felt,
    assets : felt*,
    percents_len : felt,
    percents : felt*,
):
    alloc_locals
    let (callerAmount : Uint256*, managerAmount : Uint256*, stackingVaultAmount : Uint256*, daoTreasuryAmount : Uint256*) = previewReedem( id,amount,assets_len,assets,percents_len,percents)
   
    #check timelock
    let (policyManager_:felt) = getPolicyManager()
    let (mintedBlockTimesTamp_:felt) = getMintedTimesTamp(token_id)
    let (currentTimesTamp_:felt) = get_block_timestamp()
    let (timelock_:felt) = IPolicyManager.getTimelock(policyManager_, fund_)
    let diffTimesTamp_:felt = currentTimesTamp_ - mintedBlockTimesTamp_
    with_attr error_message("sell_share: timelock not reached"):
        assert_le(timelock_, diffTimesTamp_)
    end
    # burn share
    __burnShares(share_amount, token_id)

    #transferEachAsset
    let (fund_ : felt) = get_contract_address()
    let (caller : felt) = get_caller_address()
    let (manager : felt) = getManagerAccount()
    let (stackingVault_ : felt) = getStackingVault()
    let (daoTreasury_ : felt) = getDaoTreasury()
    __transferEachAsset(fund, caller, manager, stackingVault, daoTreasury, assets_len, assets, callerAmount, managerAmount, stackingVaultAmount, daoTreasuryAmount) 
    return ()
end

#
#Internal
#

func __get_fee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _vault:felt, key: felt, amount: Uint256) -> (fee: Uint256, fee_asset_manager:Uint256, fee_treasury: Uint256, fee_stacking_vault: Uint256):
    alloc_locals
    let (isEntrance) = __is_zero(key - FeeConfig.ENTRANCE_FEE)
    let (isExit) = __is_zero(key - FeeConfig.EXIT_FEE)
    let (isPerformance) = __is_zero(key - FeeConfig.PERFORMANCE_FEE)
    let (isManagement) = __is_zero(key - FeeConfig.MANAGEMENT_FEE)

    let entranceFee = isEntrance * FeeConfig.ENTRANCE_FEE
    let exitFee = isExit * FeeConfig.EXIT_FEE
    let performanceFee = isPerformance * FeeConfig.PERFORMANCE_FEE
    let managementFee = isManagement * FeeConfig.MANAGEMENT_FEE

    let config = entranceFee + exitFee + performanceFee + managementFee

    let (feeManager_) = __getFeeManager()
    let (percent) = IFeeManager.getFeeConfig(feeManager_, _vault, config)
    let (percent_uint256) = felt_to_uint256(percent)

    let (fee) = uint256_percent(amount, percent_uint256)
    # 80% to the assetmanager, 16% to stacking vault, 4% to the DAOtreasury
    # TODO: These value should be upgradable by the governance
    let (fee_asset_manager) = uint256_percent(fee, Uint256(80,0))
    let (fee_stacking_vault) = uint256_percent(fee, Uint256(16,0))
    let (fee_treasury) = uint256_percent(fee, Uint256(4,0))

    return (fee=fee, fee_asset_manager= fee_asset_manager,fee_treasury=fee_treasury, fee_stacking_vault=fee_stacking_vault)
end


func calc_amount_of_each_asset{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    total_value : Uint256, len : felt, assets : felt*, percents : felt*, amounts : Uint256*
):
    alloc_locals

    if len == 0:
        return ()
    end
    let (denominationAsset_)= denominationAsset.read()
    let (percent:Uint256) = felt_to_uint256(percents[0])
    let (valuePercent_:Uint256) = uint256_percent(total_value, percent)
    let (assetAmount_:Uint256) = getAssetValue(denominationAsset_, valuePercent_,assets[0])
    assert [amounts] = assetAmount_

    calc_amount_of_each_asset(
        total_value=total_value,
        len=len - 1,
        assets=assets + 1,
        percents=percents + 1,
        amounts=amounts + Uint256.SIZE,
    )

    return ()
end

func __is_zero{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(x : felt) -> (
    res : felt
):
    if x == 0:
        return (res=1)
    end
    return (res=0)
end


func __transferEachAsset{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    fund : felt, caller : felt, manager : felt, stackingVault : felt, daoTreasury : felt, assets_len : felt, assets : felt*, callerAmount : Uint256*, managerAmount : Uint256*, stackingVaultAmount : Uint256*, daoTreasuryAmount : Uint256*
):
    alloc_locals
    if assets_len == 0:
        return ()
    end

    let asset = assets[0]
    let(amount_:Uint256) = felt_to_uint256(amounts[0])
    
    let (callerAmount_) = [callerAmount]
    let (managerAmount_) = [managerAmount]
    let (stackingVaultAmount_) = [stackingVaultAmount]
    let (daoTreasuryAmount_) = [daoTreasuryAmount]

    __withdrawAssetTo(asset, caller, callerAmount_)
    __withdrawAssetTo(asset, manager, managerAmount_)
    __withdrawAssetTo(asset, stackingVault, stackingVaultAmount_)
    __withdrawAssetTo(asset, daoTreasury, daoTreasuryAmount_)

    return __transferEachAsset(fund, caller, manager, stackingVault, daoTreasury, assets_len - 1, assets + 1, callerAmount + Uint256.SIZE, managerAmount + Uint256.SIZE, stackingVaultAmount + Uint256.SIZE, daoTreasuryAmount + Uint256.SIZE)
end


func __calculGav1{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    assets_len : felt, assets : AssetInfo*
) -> (gav : Uint256):
    #Tracked assets GAV 
    alloc_locals
    if assets_len == 0:
        return (gav=Uint256(0, 0))
    end
    let asset_value:Uint256 = assets[(assets_len - 1 ) *AssetInfo.SIZE].valueInDeno
    let (gavOfRest) = __calculGav1(assets_len=assets_len - 1, assets=assets)
    let (gav, _) = uint256_add(asset_value, gavOfRest)
    return (gav=gav)
end

func __calculGav2{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    externalPositions_len : felt, externalPositions : PositionInfo*
) -> (gav : Uint256):
    #External position GAV 
    alloc_locals
    if externalPositions_len == 0:
        return (gav=Uint256(0, 0))
    end
    let asset_value:Uint256 = externalPositions[(externalPositions_len - 1 ) *PositionInfo.SIZE].valueInDeno
    let (gavOfRest) = __calculGav2(externalPositions_len=externalPositions_len - 1, externalPositions=externalPositions)
    let (gav, _) = uint256_add(asset_value, gavOfRest)
    return (gav=gav)
end




func __getTreasury{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res: felt
):
    let (vaultFactory_:felt) = vaultFactory.read()
    let (treasury_:felt) = IVaultFactory.getDaoTreasury(vaultFactory_)
    return (res=treasury_)
end

func __getStackingVault{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res: felt
):
    let (vaultFactory_:felt) = vaultFactory.read()
    let (stackingVault_:felt) = IVaultFactory.getStackingVault(vaultFactory_)
    return (res=stackingVault_)
end

func __getFeeManager{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res: felt
):
    let (vaultFactory_:felt) = vaultFactory.read()
    let (feeManager_:felt) = IVaultFactory.getFeeManager(vaultFactory_)
    return (res=feeManager_)
end

func getPolicyManager{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res: felt
):
    let (vaultFactory_:felt) = vaultFactory.read()
    let (policyManager_:felt) = IVaultFactory.getPolicyManager(vaultFactory_)
    return (res=policyManager_)
end

func __getIntegrationManager{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res: felt
):
    let (vaultFactory_:felt) = vaultFactory.read()
    let (integrationManager_:felt) = IVaultFactory.getIntegrationManager(vaultFactory_)
    return (res=integrationManager_)
end

func __getValueInterpretor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res: felt
):
    let (vaultFactory_:felt) = vaultFactory.read()
    let (valueInterpretor_:felt) = IVaultFactory.getValueInterpretor(vaultFactory_)
    return (res=valueInterpretor_)
end



func __assertMaxminRange{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _amount : Uint256):
    alloc_locals
    let (policyManager_) = getPolicyManager()
    let (fund_:felt) = get_contract_address()
    let (max:Uint256, min:Uint256) = IPolicyManager.getMaxminAmount(policyManager_, fund_)
    let (le_max) = uint256_le(_amount, max)
    let (be_min) = uint256_le(min, _amount)
    with_attr error_message("__assertMaxminRange: amount is too high"):
        assert le_max = 1
    end
    with_attr error_message("__assertMaxminRange: amount is too low"):
        assert be_min = 1
    end
    return ()
end

func __assertAllowedDepositor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _caller : felt):
    alloc_locals
    let (policyManager_) = getPolicyManager()
    let (fund_:felt) = get_contract_address()
    let (isPublic_:felt) = IPolicyManager.checkIsPublic(policyManager_, fund_)
    if isPublic_ == 1:
        return()
    else:
        let (isAllowedDepositor_:felt) = IPolicyManager.checkIsAllowedDepositor(policyManager_, fund_, _caller)
        with_attr error_message("__assertAllowedDepositor: not allowed depositor"):
        assert isAllowedDepositor_ = 1
        end
    end
    return ()
end

#helper to make sure the sum is 100%
func __calculTab100{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _percents_len : felt, _percents : felt*) -> (res:felt):
    alloc_locals
    if _percents_len == 0:
        return (0)
    end
    let newPercents_len:felt = _percents_len - 1
    let newPercents:felt* = _percents + 1
    let (_previousElem:felt) = __calculTab100(newPercents_len, newPercents)
    let res:felt = [_percents] + _previousElem
    return (res=res)
end





   #
   # Logic
   #




   func __burnShares{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _amount: Uint256,
        _tokenId:Uint256,
    ):
    alloc_locals
    let(_sharesAmount:Uint256) = sharesBalance(_tokenId)
    let (equal_) = uint256_eq(_sharesAmount, _amount)
    if equal_ == TRUE:
        burn(_tokenId)
        return ()
    else:
        subShares(_tokenId, _amount)
        return ()
    end
end

func __withdrawAssetTo{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        _asset: felt,
        _amount:Uint256,
        _target:felt,
    ):
    let (_success) = IERC20.transfer(contract_address = _asset,recipient = _target,amount = _amount)
    with_attr error_message("__withdrawAssetTo: transfer didn't work"):
        assert_not_zero(_success)
    end

    AssetWithdrawn.emit(_asset, _target, _amount)
    return ()
end
    
end
