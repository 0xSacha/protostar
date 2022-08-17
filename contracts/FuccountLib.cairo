%lang starknet


from starkware.cairo.common.registers import get_fp_and_pc
from starkware.starknet.common.syscalls import (get_block_timestamp, get_contract_address, get_caller_address, call_contract, get_tx_info)
from starkware.cairo.common.signature import verify_ecdsa_signature
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.cairo_secp.signature import verify_eth_signature_uint256
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.math import (
    assert_not_zero,
    assert_not_equal,
    assert_le,
    unsigned_div_rem,
    split_felt,
)

from openzeppelin.introspection.erc165.IERC165 import IERC165
from openzeppelin.introspection.erc165.library import ERC165
from contracts.interfaces.IERC1155Receiver import IERC1155_Receiver
from openzeppelin.security.safemath.library import SafeUint256
from openzeppelin.security.reentrancyguard.library import ReentrancyGuard

from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_sub,
    uint256_check,
    uint256_le,
    uint256_add,
    uint256_mul,
)
from contracts.utils.utils import felt_to_uint256, uint256_div, uint256_percent, uint256_pow, uint256_mul_low

from openzeppelin.token.erc20.IERC20 import IERC20
from contracts.interfaces.IVaultFactory import IVaultFactory
from contracts.interfaces.IFeeManager import FeeConfig, IFeeManager
from contracts.interfaces.IPolicyManager import IPolicyManager
from contracts.interfaces.IFuccount import IFuccount
from contracts.interfaces.IStackingDispute import IStackingDispute
from contracts.interfaces.IPreLogic import IPreLogic
from contracts.interfaces.IIntegrationManager import IIntegrationManager
from contracts.interfaces.IValueInterpretor import IValueInterpretor


const IERC1155_ID = 0xd9b67a26
const IERC1155_METADATA_ID = 0x0e89341c
const IERC1155_RECEIVER_ID = 0x4e2312e0
const ON_ERC1155_RECEIVED_SELECTOR = 0xf23a6e61
const ON_ERC1155_BATCH_RECEIVED_SELECTOR = 0xbc197c81
const IACCOUNT_ID = 0xf10dbd44
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

struct ShareInfo:
    member address : felt
    member amount : Uint256
    member id : Uint256
    member valueInDeno : Uint256
end

struct ShareWithdraw:
    member address : felt
    member id : Uint256
end

struct PositionInfo:
    member address : felt
    member valueInDeno : Uint256
end

struct Call:
    member to: felt
    member selector: felt
    member calldata_len: felt
    member calldata: felt*
end

# Tmp struct introduced while we wait for Cairo
# to support passing `[AccountCall]` to __execute__
struct AccountCallArray:
    member to: felt
    member selector: felt
    member data_offset: felt
    member data_len: felt
end


#
# Events
#

@event
func TransferSingle(
    operator: felt,
    from_: felt,
    to: felt,
    id: Uint256,
    value: Uint256
):
end

@event
func TransferBatch(
    operator: felt,
    from_: felt,
    to: felt,
    ids_len: felt,
    ids: Uint256*,
    values_len: felt,
    values: Uint256*
):
end

@event
func ApprovalForAll(account: felt, operator: felt, approved: felt):
end

#
# Storage
#

@storage_var
func ERC1155_balances(id: Uint256, account: felt) -> (balance: Uint256):
end

@storage_var
func ERC1155_operator_approvals(account: felt, operator: felt) -> (approved: felt):
end

@storage_var
func totalId() -> (res: Uint256):
end

@storage_var
func sharePricePurchased(token_id: Uint256) -> (res: Uint256):
end

@storage_var
func mintedBlockTimesTamp(token_id: Uint256) -> (res: felt):
end

@storage_var
func sharesTotalSupply() -> (res: Uint256):
end

@storage_var
func name() -> (res: felt):
end

@storage_var
func symbol() -> (res: felt):
end

@storage_var
func vaultFactory() -> (res : felt):
end

@storage_var
func managerAccount() -> (res : felt):
end

@storage_var
func denominationAsset() -> (res : felt):
end

@storage_var
func Account_current_nonce() -> (res: felt):
end

@storage_var
func Account_public_key() -> (res: felt):
end

@storage_var
func Account_public_key() -> (res: felt):
end

@storage_var
func fundLevel() -> (res: felt):
end

@storage_var
func isFundRevoked() -> (res: felt):
end

@storage_var
func isFundClosed() -> (res: felt):
end




namespace FuccountLib:

    #
    # Constructor
    #

    func initializer{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        _public_key: felt,
        _vaultFactory: felt,
    ):
        with_attr error_message("constructor: cannot set the vaultFactory to the zero address"):
        assert_not_zero(_vaultFactory)
        end
        vaultFactory.write(_vaultFactory)
        Account_public_key.write(_public_key)
        ERC165.register_interface(IACCOUNT_ID)
        ERC165.register_interface(IERC1155_ID)
        ERC165.register_interface(IERC1155_METADATA_ID)
        return ()
    end

    func activater{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(
            _name: felt,
            _symbol: felt,
            _denominationAsset: felt,
            _managerAccount:felt,
            _shareAmount:Uint256,
            _sharePrice:Uint256,
        ):
        onlyVaultFactory()
        name.write(_name)
        symbol.write(_symbol)
        denominationAsset.write(_denominationAsset)
        managerAccount.write(_managerAccount)
        mint(_managerAccount, _shareAmount, _sharePrice)
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


    func balance_of{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(account: felt, id: Uint256) -> (balance: Uint256):
        with_attr error_message("ERC1155: balance query for the zero address"):
            assert_not_zero(account)
        end
        let (balance) = ERC1155_balances.read(id, account)
        return (balance)
    end

    func balance_of_batch{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(
            accounts_len: felt,
            accounts: felt*,
            ids_len: felt,
            ids: Uint256*
        ) -> (
            batch_balances_len: felt,
            batch_balances: Uint256*
        ):
        alloc_locals
        # Check args are equal length arrays
        with_attr error_message("ERC1155: accounts and ids length mismatch"):
            assert ids_len = accounts_len
        end
        # Allocate memory
        let (local batch_balances: Uint256*) = alloc()
        let len = accounts_len
        # Call iterator
        balance_of_batch_iter(len, accounts, ids, batch_balances)
        let batch_balances_len = len
        return (batch_balances_len, batch_balances)
    end

    func is_approved_for_all{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(account: felt, operator: felt) -> (approved: felt):
        let (approved) = ERC1155_operator_approvals.read(account, operator)
        return (approved)
    end

    func getSharePricePurchased{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(tokenId: Uint256) -> (res: Uint256):
    let (sharePricePurchased_: Uint256) = sharePricePurchased.read(tokenId)
    return (sharePricePurchased_)
    end

    func getMintedBlockTimesTamp{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(tokenId: Uint256) -> (res: felt):
    let (mintedBlockTimesTamp_: felt) = mintedBlockTimesTamp.read(tokenId)
    return (mintedBlockTimesTamp_)
    end

    func supportsInterface{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(interfaceId: felt) -> (success: felt):
    return ERC165.supports_interface(interfaceId)
    end

    func getSharesTotalSupply{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }() -> (totalSupply: Uint256):
    let (totalSupply: Uint256) = sharesTotalSupply.read()
    return (totalSupply)
    end

    func getTotalId{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }() -> (res: Uint256):
    let (totalId_: Uint256) = totalId.read()
    return (totalId_)
    end


func ownerShares{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(account: felt) -> (assetId_len:felt, assetId:Uint256*, assetAmount_len:felt,assetAmount:Uint256*):
    alloc_locals
    let (totalId_:Uint256) = totalId.read()
    let (local assetId : Uint256*) = alloc()
    let (local assetAmount : Uint256*) = alloc()
    let (tabSize_:felt) = _completeMultiShareTab(totalId_, 0, assetId, 0, assetAmount, account)    
    return (tabSize_, assetId, tabSize_, assetAmount)
end


func getName{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (name_) = name.read()
    return (name_)
end

func getSymbol{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (symbol_) = symbol.read()
    return (symbol_)
end

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

func getShareBalance{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_share: felt, _id: felt) -> (shareBalance_: Uint256):
    let (account_:felt) = get_contract_address()
    let (shareBalance_:Uint256) = IFuccount.balanceOf(account_, _share, _id)
    return (shareBalance_)
end


func getNotNulAssets{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (notNulAssets_len:felt, notNulAssets: AssetInfo*):
    alloc_locals
    let (IM_:felt) = _getIntegrationManager()
    let (availableAssets_len: felt, availableAssets:felt*) = IIntegrationManager.getAvailableAssets(IM_)
    let (local notNulAssets : AssetInfo*) = alloc()
    let (notNulAssets_len:felt) = _completeNonNulAssetTab(availableAssets_len, availableAssets, 0, notNulAssets)    
    return(notNulAssets_len, notNulAssets)
end


func getNotNulShares{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (notNulShares_len:felt, notNulShares: ShareInfo*):
    alloc_locals
    let (IM_:felt) = _getIntegrationManager()
    let (selfAddress) = get_contract_address()
    let (denominationAsset_) = getDenominationAsset()
    let (availableAShares_len: felt, availableShares:felt*) = IIntegrationManager.getAvailableShares(IM_)
    let (local notNulShares : ShareInfo*) = alloc()
    let (notNulShares_len:felt) = _completeNotNulSharesTab(availableAShares_len, availableShares, 0, notNulShares, selfAddress, denominationAsset_)    
    return(notNulShares_len, notNulShares)
end

func getNotNulPositions{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (notNulPositions_len:felt, notNulPositition: felt*):
    alloc_locals
    let (IM_:felt) = _getIntegrationManager()
    let (availableExternalPositions_len: felt, availableExternalPositions:felt*) = IIntegrationManager.getAvailableExternalPositions(IM_)
    let (local notNulExternalPositions : PositionInfo*) = alloc()
    let (notNulExternalPositions_len:felt) = _completeNonNulPositionTab(availableExternalPositions_len, availableExternalPositions, 0, notNulExternalPositions)    
    return(notNulExternalPositions_len, notNulExternalPositions)
end



func getSharePrice{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
     res : Uint256
):
    alloc_locals
    let (gav) = calculGav()
    #shares have 18 decimals
    let (gavPow18_:Uint256,_) = uint256_mul(gav, Uint256(POW18,0))
    let (total_supply) = sharesTotalSupply.read()
    let (price : Uint256) = uint256_div(gavPow18_, total_supply)
    return (res=price)
end


func getAssetValue{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _asset: felt, _amount: Uint256, _denominationAsset: felt
) -> (res: Uint256):
    let (valueInterpretor_:felt) = _getValueInterpretor()
    let (value_:Uint256) = IValueInterpretor.calculAssetValue(valueInterpretor_, _asset, _amount, _denominationAsset)
    return (res=value_)
end

func getShareValue{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _share: felt, _id: Uint256, _amount: Uint256, _denominationAsset: felt
) -> (res: Uint256):
    let (valueInterpretor_:felt) = _getValueInterpretor()
    let (value_:Uint256) = IValueInterpretor.calculAssetValue(valueInterpretor_, _share, Uint256(_amount.low, _id.low), _denominationAsset)
    return (res=value_)
end



func calculLiquidGav{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res : Uint256
):
    alloc_locals
    let (assets_len: felt, assets: AssetInfo*) = getNotNulAssets()
    let (gavAsset_) = __calculGavAsset(assets_len, assets)
    let (shares_len:felt, shares: ShareInfo*) = getNotNulShares()
    let (gavShare_) = __calculGavShare(shares_len, shares)
    let (gav,_) = uint256_add(gavAsset_, gavShare_)
    return (res=gav)
end

func calculNotLiquidGav{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res : Uint256
):
    alloc_locals
    let (externalPosition_len: felt, externalPosition: PositionInfo*) = getNotNulPositions()
    let (gav) = __calculGavPosition(externalPosition_len, externalPosition)
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


func isFreeReedem{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(amount: Uint256) -> (isFreeReedem: felt):
    let (policyManager_:felt) = _getPolicyManager()
    let (contractAddress_:felt) = get_contract_address()
    let (allowedAssetToReedem_len: felt, allowedAssetToReedem:felt*) = IPolicyManager.getAllowedAssetToReedem(contractAddress_)
    if allowedAssetToReedem_len == 0:
    return (1)
    else:
    let (denominationAsset_)= denominationAsset.read()
    let (valueInDeno_:Uint256) = _sumValueInDeno(allowedAssetToReedem_len, allowedAssetToReedem, denominationAsset_)
    let (sharePrice_) = getSharePrice()
    let (shareValueInDenoTemp_:Uint256) = SafeUint256.mul(sharePrice_, amount)
    let (shareValueInDeno_:Uint256,_) = SafeUint256.div_rem(shareValueInDenoTemp_, Uint256(POW18,0))
    let (isFreeReedem:felt) = uint256_le(valueInDeno_, shareValueInDeno_)
    return(isFreeReedem)
    end
end

func isAvailableReedem{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(amount: Uint256) -> (isAvailableReedem: felt):
    let (liquidGav_) = calculLiquidGav()
    let (sharePrice_) = getSharePrice()
    let (shareValueInDenoTemp_:Uint256) = SafeUint256.mul(sharePrice_, amount)
    let (shareValueInDeno_:Uint256,_) = SafeUint256.div_rem(shareValueInDenoTemp_, Uint256(POW18,0))
    let (isAvailableReedem) = uint256_le(shareValueInDeno_, liquidGav_)
    return(isAvailableReedem)
    end
end

func shareToDeno{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id : Uint256, amount : Uint256) -> (denominationAsset: felt, amount_len: felt, amount:Uint256*):
    alloc_locals

    let (denominationAsset_:felt) = denominationAsset.read()
    let (sharePrice_) = getSharePrice()
    let (sharesValuePow_:Uint256,_) = uint256_mul(sharePrice_, amount)
    let (sharesValue_:Uint256) = uint256_div(sharesValuePow_, Uint256(POW18,0))

    #calculate the performance 
    let(previous_share_price_:Uint256) = sharePricePurchased.read(id)
    let(has_performed_) = uint256_le(previous_share_price_, sharePrice_)
    if has_performed_ == 1 :
        let(diff_:Uint256) = SafeUint256.sub_le(sharePrice_, previous_share_price_)
        let(diffPermillion_:Uint256,diffperc_h_) = uint256_mul(diff_, Uint256(PRECISION,0))
        let(perfF_:Uint256)=uint256_div(diffPermillion_, sharePrice_)
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

    let (mintedBlockTimesTamp_:felt) = getMintedBlockTimesTamp(id)
    let (currentTimesTamp_:felt) = get_block_timestamp()
    let diff = currentTimesTamp_ - mintedBlockTimesTamp_
    let diff_precision = diff * PRECISION
    let (durationPermillion_,_) = unsigned_div_rem(diff_precision, SECOND_YEAR)


    let (fund_:felt) = get_caller_address()
    let (local assetCallerAmount : Uint256*) = alloc()
    let (local assetManagerAmount : Uint256*) = alloc()
    let (local assetStackingVaultAmount : Uint256*) = alloc()
    let (local assetDaoTreasuryAmount : Uint256*) = alloc()
    let (local assetAmounts : Uint256*) = alloc()
    assert assetAmounts[0] = sharesValue_
    _reedemTab(1,  assetAmounts, performancePermillion_, durationPermillion_, fund_, 0, assetCallerAmount, assetManagerAmount, assetStackingVaultAmount, assetDaoTreasuryAmount)
    return(denominationAsset_,1, len,assetCallerAmount)
    end
end

func previewReedem{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id : Uint256,
    amount : Uint256,
    assets_len : felt,
    assets : felt*,
    shares_len : felt,
    shares : ShareWithdraw*,
) -> (assetCallerAmount_len: felt,assetCallerAmount:Uint256*, assetManagerAmount_len: felt,assetManagerAmount:Uint256*,assetStackingVaultAmount_len: felt, assetStackingVaultAmount:Uint256*, assetDaoTreasuryAmount_len: felt,assetDaoTreasuryAmount:Uint256*, shareCallerAmount_len: felt, shareCallerAmount:Uint256*, shareManagerAmount_len: felt, shareManagerAmount:Uint256*, shareStackingVaultAmount_len: felt, shareStackingVaultAmount:Uint256*, shareDaoTreasuryAmount_len: felt, shareDaoTreasuryAmount:Uint256*):
    alloc_locals

    let (isAvailableReedem) = isAvailableReedem(amount)
    with_attr error_message("previewReedem: Not enought liquid positions"):
            assert isAvailableReedem = 1
    end

    let (isFreeReedem_:felt) = isFreeReedem(amount)
    let (fund_:felt) = get_contract_address()
    if isFreeReedem_ == 0:
        with_attr error_message("previewReedem: Only allowed assets can be reedem"):
            assert shares_len = 0
        end
        let (policyManager_:felt) = _getPolicyManager()
        _assertAllowedAssetToReedem(assets_len, assets, policyManager_, fund_)
    end

    let (denominationAsset_:felt) = denominationAsset.read()
    let (sharePrice_) = getSharePrice()
    let (sharesValuePow_:Uint256,_) = uint256_mul(sharePrice_, amount)
    let (sharesValue_:Uint256) = uint256_div(sharesValuePow_, Uint256(POW18,0))

    #calculate the performance 
    let(previous_share_price_:Uint256) = sharePricePurchased.read(id)
    let(has_performed_) = uint256_le(previous_share_price_, sharePrice_)
    if has_performed_ == 1 :
        let(diff_:Uint256) = SafeUint256.sub_le(sharePrice_, previous_share_price_)
        let(diffPermillion_:Uint256,diffperc_h_) = uint256_mul(diff_, Uint256(PRECISION,0))
        let(perfF_:Uint256)=uint256_div(diffPermillion_, sharePrice_)
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

    let (mintedBlockTimesTamp_:felt) = getMintedBlockTimesTamp(id)
    let (currentTimesTamp_:felt) = get_block_timestamp()
    let diff = currentTimesTamp_ - mintedBlockTimesTamp_
    let diff_precision = diff * PRECISION
    let (durationPermillion_,_) = unsigned_div_rem(diff_precision, SECOND_YEAR)

    let (local assetCallerAmount : Uint256*) = alloc()
    let (local assetManagerAmount : Uint256*) = alloc()
    let (local assetStackingVaultAmount : Uint256*) = alloc()
    let (local assetDaoTreasuryAmount : Uint256*) = alloc()
    let (local shareCallerAmount : Uint256*) = alloc()
    let (local shareManagerAmount : Uint256*) = alloc()
    let (local shareStackingVaultAmount : Uint256*) = alloc()
    let (local shareDaoTreasuryAmount : Uint256*) = alloc()

    let (local assetAmounts : Uint256*) = alloc()
    let (local shareAmounts : Uint256*) = alloc()

    let (remainingValue_: Uint256, len: felt) = _calcAmountOfEachAsset(sharesValue_, assets_len, assets, 0,assetAmounts , denominationAsset_)
    let (isRemaingValueNul_: felt) = uint256_eq(remainingValue, Uint256(0,0))
    if isRemaingValueNul_ = 0:
        let (remainingValue2_: Uint256, len2: felt) = _calcAmountOfEachShare(remainingValue_, shares_len, shares, 0, shareAmounts , denominationAsset_)
        let (isRemaingValue2Nul_: felt) = uint256_eq(remainingValue2_, Uint256(0,0))
        with_attr error_message("previewReedem: Choose more Assets/Shares to reedem"):
            assert isRemaingValue2Nul_ = 1
        end
        _reedemTab(len,  assetAmounts, performancePermillion_, durationPermillion_, fund_, 0, assetCallerAmount, assetManagerAmount, assetStackingVaultAmount, assetDaoTreasuryAmount)
        _reedemTab(len2, shareAmounts, performancePermillion_, durationPermillion_, fund_, 0, shareCallerAmount, shareManagerAmount, shareStackingVaultAmount, shareDaoTreasuryAmount)
        return(len,assetCallerAmount, len,assetManagerAmount,len, assetStackingVaultAmount, len,assetDaoTreasuryAmount, len2, shareCallerAmount, len2, shareManagerAmount, len2, shareStackingVaultAmount, len2, shareDaoTreasuryAmount)
    else:
    _reedemTab(len,  assetAmounts, performancePermillion_, durationPermillion_, fund_, 0, assetCallerAmount, assetManagerAmount, assetStackingVaultAmount, assetDaoTreasuryAmount)
    return(len,assetCallerAmount, len,assetManagerAmount,len, assetStackingVaultAmount, len,assetDaoTreasuryAmount, 0, shareCallerAmount, 0, shareManagerAmount, 0, shareStackingVaultAmount, 0, shareDaoTreasuryAmount)
    end
end

func _assertAllowedAssetToReedem{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }(asset_len:felt, asset: felt, policyManager: felt, contractAddress: felt):
        if asset_len == 0:
            return()
        end
        let (isAllowedAssetToReedem_) = IPolicyManager.checkIsAllowedAssetToReedem(policyManager, contractAddress, asset[0])
        with_attr error_message("_assertAllowedAssetToReedem:  Only allowed assets can be reedem"):
            assert isAllowedAssetToReedem_ = 1
        end
        return _assertAllowedAssetToReedem(asset_len - 1, asset + 1, policyManager, contractAddress)
    end


    func get_public_key{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }() -> (res: felt):
        let (res) = Account_public_key.read()
        return (res=res)
    end

    func get_nonce{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }() -> (res: felt):
        let (res) = Account_current_nonce.read()
        return (res=res)
    end

    func getFundLevel{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }() -> (res: felt):
        let (res) = fundLevel.read()
        return (res=res)
    end
    
    func previewDeposit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
     _amount: Uint256
) -> (shareAmount: Uint256, fundAmount: Uint256, managerAmount: Uint256, treasuryAmount: Uint256, stackingVaultAmount: Uint256):
    alloc_locals
    let (fund_:felt) = get_contract_address()
    let (denominationAsset_:felt) = denominationAsset.read()
    let (caller_ : felt) = get_caller_address()
    let (fee, fee_assset_manager, fee_treasury, fee_stacking_vault) = _get_fee(fund_, FeeConfig.ENTRANCE_FEE, _amount)
    let (sharePrice_) = getSharePrice()
    let (fundAmount_) = uint256_sub(_amount, fee)
    let (amountWithoutFeesPow_,_) = uint256_mul(fundAmount_, Uint256(10**18,0))
    let (shareAmount_) = uint256_div(amountWithoutFeesPow_, sharePrice_)
    return (shareAmount_, fundAmount_, fee_assset_manager, fee_treasury, fee_stacking_vault)
end



    #
    # Externals
    #

    func revoke{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
        alloc_locals
        let (vaultFactory_:felt) = vaultFactory.read()
        let (stackingDispute_:felt) = IVaultFactory.getStackingDispute()
        let (caller_ : felt) = get_caller_address()
        with_attr error_message("revoke: not allowed caller"):
            assert caller_ = stackingDispute_
        end
        isFundRevoked.write(1)
        return ()
    end

    func revokeResult{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(isReportAccepted: felt):
        alloc_locals
        let (vaultFactory_:felt) = vaultFactory.read()
        let (stackingDispute_:felt) = IVaultFactory.getStackingDispute()
        let (caller_ : felt) = get_caller_address()
        with_attr error_message("revoke: not allowed caller"):
            assert caller_ = stackingDispute_
        end
        if isReportAccepted == 1:
            isFundRevoked.write(0)
            isFundClosed.write(1)
        else:
            isFundRevoked.write(0)
        end
        return ()
    end

    func close{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
        alloc_locals
        onlyVaultFactory()
        isFundClosed.write(1)
        return ()
    end

func deposit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
     _amount: Uint256,
):
    alloc_locals
    let (fund_:felt) = get_contract_address()
    let (denominationAsset_:felt) = denominationAsset.read()
    let (caller_ : felt) = get_caller_address()

    _assertMaxminRange(_amount)
    _assertAllowedDepositor(caller_)

    let (shareAmount_: Uint256, fundAmount_: Uint256, managerAmount_: Uint256, treasuryAmount_: Uint256, stackingVaultAmount_: Uint256) = previewDeposit(_amount)
    # transfer fee to fee_treasury, stacking_vault
    let (_managerAccount:felt) = managerAccount.read()
    let (treasury:felt) = _getDaoTreasury()
    let (stacking_vault:felt) = _getStackingVault()

    # transfer asset
    IERC20.transferFrom(denominationAsset_, caller_, _managerAccount, managerAmount_)
    IERC20.transferFrom(denominationAsset_, caller_, treasury, treasuryAmount_)
    IERC20.transferFrom(denominationAsset_, caller_, stacking_vault, stackingVaultAmount_)
    IERC20.transferFrom(denominationAsset_, caller_, fund_, fundAmount_)
    let (sharePrice_) = getSharePrice()

    # mint share
    mint(caller_, shareAmount_, sharePrice_)
    _assertEnoughtGuarantee()
    return ()
end


func deposit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
     _amount: Uint256,
):
    alloc_locals
    let (fund_:felt) = get_contract_address()
    let (denominationAsset_:felt) = denominationAsset.read()
    let (caller_ : felt) = get_caller_address()

    _assertMaxminRange(_amount)
    _assertAllowedDepositor(caller_)

    let (shareAmount_: Uint256, fundAmount_: Uint256, managerAmount_: Uint256, treasuryAmount_: Uint256, stackingVaultAmount_: Uint256) = previewDeposit(_amount)
    # transfer fee to fee_treasury, stacking_vault
    let (_managerAccount:felt) = managerAccount.read()
    let (treasury:felt) = _getDaoTreasury()
    let (stacking_vault:felt) = _getStackingVault()

    # transfer asset
    IERC20.transferFrom(denominationAsset_, caller_, _managerAccount, managerAmount_)
    IERC20.transferFrom(denominationAsset_, caller_, treasury, treasuryAmount_)
    IERC20.transferFrom(denominationAsset_, caller_, stacking_vault, stackingVaultAmount_)
    IERC20.transferFrom(denominationAsset_, caller_, fund_, fundAmount_)
    let (sharePrice_) = getSharePrice()

    # mint share
    mint(caller_, shareAmount_, sharePrice_)
    _assertEnoughtGuarantee()
    return ()
end

func reedem{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    id : Uint256,
    amount : Uint256,
    assets_len : felt,
    assets : felt*,
    percentsAsset_len : felt,
    percentsAsset : felt*,
    shares_len : felt,
    shares : ShareWithdraw*,
    percentsShare_len : felt,
    percentsShare : felt*,
):
    alloc_locals
    let (len: felt,assetCallerAmount:Uint256*, len: felt,assetManagerAmount:Uint256*, len: felt, assetStackingVaultAmount:Uint256*,  len: felt, assetDaoTreasuryAmount:Uint256*, len2: felt, shareCallerAmount:Uint256*,  len2: felt, shareManagerAmount:Uint256*,  len2: felt, shareStackingVaultAmount:Uint256*,  len2: felt, shareDaoTreasuryAmount:Uint256*) = previewReedem( id,amount,assets_len,assets,percentsAsset_len,percentsAsset, shares_len, shares, percentsShare_len, percentsShare )
   
    let (caller_:felt) = get_caller_address()
    let (fund_:felt) = get_contract_address()

    #check timelock (fund lvl3)
    let (fundLevel_:felt) = getFundLevel()
    if fundLevel_ == 3:
        let (policyManager_:felt) = _getPolicyManager()
        let (currentTimesTamp_:felt) = get_block_timestamp()
        let (reedemTime_:felt) = IPolicyManager.getReedemTime(policyManager_, fund_)
        with_attr error_message("reedem: timelock not reached"):
            assert_le(reedemTime_, currentTimesTamp_)
        end
    end

    # burn share
    burn(caller_, id, amount)

    #transferEachAsset
    let (fund_ : felt) = get_contract_address()
    let (caller : felt) = get_caller_address()
    let (manager : felt) = getManagerAccount()
    let (stackingVault_ : felt) = _getStackingVault()
    let (daoTreasury_ : felt) = _getDaoTreasury()
    _transferEachAsset(fund_, caller, manager, stackingVault_, daoTreasury_, assets_len, assets, assetCallerAmount, assetManagerAmount, assetStackingVaultAmount, assetDaoTreasuryAmount)
    _transferEachShare(fund_, caller, manager, stackingVault_, daoTreasury_, shares_len, shares, shareCallerAmount, shareManagerAmount, shareStackingVaultAmount, shareDaoTreasuryAmount)
    return ()
end



    func set_approval_for_all{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(operator: felt, approved: felt):
        let (caller) = get_caller_address()
        with_attr error_message("ERC1155: cannot approve from the zero address"):
            assert_not_zero(caller)
        end
        _set_approval_for_all(caller, operator, approved)
        return ()
    end

    func safe_transfer_from{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(
            from_: felt,
            to: felt,
            id: Uint256,
            amount: Uint256,
        ):
        let (caller) = get_caller_address()
        with_attr error_message("ERC1155: cannot call transfer from the zero address"):
            assert_not_zero(caller)
        end
        with_attr error_message("ERC1155: caller is not owner nor approved"):
            assert_owner_or_approved(from_)
        end
        _safe_transfer_from(from_, to, id, amount)
        return ()
    end

    func safe_batch_transfer_from{
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
        ):
        let (caller) = get_caller_address()
        with_attr error_message("ERC1155: cannot call transfer from the zero address"):
            assert_not_zero(caller)
        end
        with_attr error_message("ERC1155: transfer caller is not owner nor approved"):
            assert_owner_or_approved(from_)
        end
        _safe_batch_transfer_from(from_, to, ids_len, ids, amounts_len, amounts)
        return ()
    end


func mint{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        to: felt, 
        sharesAmount: Uint256, 
        _sharePricePurchased:Uint256,
    ):
    let (totalId_) = totalId.read()
    sharePricePurchased.write(totalId_, _sharePricePurchased)
    let (currentTimesTamp_:felt) = get_block_timestamp()
    mintedBlockTimesTamp.write(totalId_, currentTimesTamp_)
    let (currentTotalSupply_) = sharesTotalSupply.read()
    let (newTotalSupply_,_) = uint256_add(currentTotalSupply_, sharesAmount )
    sharesTotalSupply.write(newTotalSupply_)
    let (newTotalId_,_) = uint256_add(totalId_, Uint256(1,0) )
    totalId.write(newTotalId_)
    _mint(to, totalId_, sharesAmount)
    return ()
end


func burn{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(from_: felt, id: Uint256, amount: Uint256):
    assert_owner_or_approved(owner=from_)
    let (caller) = get_caller_address()
    with_attr error_message("ERC1155: called from zero address"):
        assert_not_zero(caller)
    end
    _burn(from_, id, amount)
    let (currentTotalSupply_) = sharesTotalSupply.read()
    let (newTotalSupply_) = uint256_sub(currentTotalSupply_, amount )
    sharesTotalSupply.write(newTotalSupply_)
    return ()
end



func burnBatch{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        from_: felt,
        ids_len: felt,
        ids: Uint256*,
        amounts_len: felt,
        amounts: Uint256*
    ):
    assert_owner_or_approved(owner=from_)
    let (caller) = get_caller_address()
    with_attr error_message("ERC1155: called from zero address"):
        assert_not_zero(caller)
    end
    _burn_batch(from_, ids_len, ids, amounts_len, amounts)
    reduceSupplyBatch(amounts_len, amounts)
    return ()
end

func set_public_key{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }(new_public_key: felt):
        assert_only_self()
        Account_public_key.write(new_public_key)
        return ()
    end

    func setFundLevel{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr
        }(_fundLevel: felt):
        onlyVaultFactory()
        fundLevel.write(_fundLevel)
        return ()
    end

    func execute{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr,
            ecdsa_ptr: SignatureBuiltin*,
            bitwise_ptr: BitwiseBuiltin*
        }(
            call_array_len: felt,
            call_array: AccountCallArray*,
            calldata_len: felt,
            calldata: felt*,
            nonce: felt
        ) -> (response_len: felt, response: felt*):
        alloc_locals
        let (isFundClosed_:felt) = isFundClosed.read()
        let (isFundRevoked_: felt) = isFundRevoked.read()
        with_attr error_message("Account: fund is revoked or closed"):
            assert isFundClosed_ + isFundRevoked_ = 0
        end

        let (__fp__, _) = get_fp_and_pc()
        let (tx_info) = get_tx_info()

        # validate transaction
        with_attr error_message("Account: invalid signature"):
            let (is_valid) = is_valid_signature(tx_info.transaction_hash, tx_info.signature_len, tx_info.signature)
            assert is_valid = TRUE
        end

        return _unsafe_execute(call_array_len, call_array, calldata_len, calldata, nonce)
    end

    func eth_execute{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr,
            ecdsa_ptr: SignatureBuiltin*,
            bitwise_ptr: BitwiseBuiltin*
        }(
            call_array_len: felt,
            call_array: AccountCallArray*,
            calldata_len: felt,
            calldata: felt*,
            nonce: felt
        ) -> (response_len: felt, response: felt*):
        alloc_locals

        let (__fp__, _) = get_fp_and_pc()
        let (tx_info) = get_tx_info()

        # validate transaction
        with_attr error_message("Account: invalid secp256k1 signature"):
            let (is_valid) = is_valid_eth_signature(tx_info.transaction_hash, tx_info.signature_len, tx_info.signature)
            assert is_valid = TRUE
        end

        return _unsafe_execute(call_array_len, call_array, calldata_len, calldata, nonce)
    end


    #
    # Internals
    #

func _sumValueInDeno{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(asset_len: felt, asset: felt*, denominationAsset: felt) -> (valueInDeno: Uint256):
    if asset_len == 0:
        return(Uint256(0,0)
    end
    let (fundAssetBalance:Uint256) = getAssetBalance(asset[0])
    let (AssetvalueInDeno_: Uint256) = getAssetValue(asset[0], fundAssetBalance, denominationAsset)
    let (valueOfRest_: Uint256) = _sumValueInDeno(asset_len - 1, asset + 1, denominationAsset)
    let (totalValueInDeno:Uint256) = SafeUint256.add(AssetvalueInDeno_, valueOfRest_)
    return(valueInDeno=totalValueInDeno)
end


func _unsafe_execute{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr,
            ecdsa_ptr: SignatureBuiltin*,
            bitwise_ptr: BitwiseBuiltin*
        }(
            call_array_len: felt,
            call_array: AccountCallArray*,
            calldata_len: felt,
            calldata: felt*,
            nonce: felt
        ) -> (response_len: felt, response: felt*):
        alloc_locals

        let (caller) = get_caller_address()
        with_attr error_message("Account: no reentrant call"):
            assert caller = 0
        end

        # validate nonce

        let (_current_nonce) = Account_current_nonce.read()

        with_attr error_message("Account: nonce is invalid"):
            assert _current_nonce = nonce
        end

        # bump nonce
        Account_current_nonce.write(_current_nonce + 1)

        # TMP: Convert `AccountCallArray` to 'Call'.
        let (calls : Call*) = alloc()
        _from_call_array_to_call(call_array_len, call_array, calldata, calls)
        let calls_len = call_array_len

        # execute call
        let (response : felt*) = alloc()
        let (response_len) = _execute_list(calls_len, calls, response)

        return (response_len=response_len, response=response)
    end

    func _execute_list{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
            calls_len: felt,
            calls: Call*,
            response: felt*
        ) -> (response_len: felt):
        alloc_locals

        # if no more calls
        if calls_len == 0:
           return (0)
        end

        # do the current call
        let this_call: Call = [calls]
        _checkCall(this_call.to, this_call.selector, this_call.calldata_len, this_call.calldata)
        let res = call_contract(
            contract_address=this_call.to,
            function_selector=this_call.selector,
            calldata_size=this_call.calldata_len,
            calldata=this_call.calldata
        )
        # copy the result in response
        memcpy(response, res.retdata, res.retdata_size)
        # do the next calls recursively
        let (response_len) = _execute_list(calls_len - 1, calls + Call.SIZE, response + res.retdata_size)
        return (response_len + res.retdata_size)
    end

    func _from_call_array_to_call{syscall_ptr: felt*}(
            call_array_len: felt,
            call_array: AccountCallArray*,
            calldata: felt*,
            calls: Call*
        ):
        # if no more calls
        if call_array_len == 0:
           return ()
        end

        # parse the current call
        assert [calls] = Call(
                to=[call_array].to,
                selector=[call_array].selector,
                calldata_len=[call_array].data_len,
                calldata=calldata + [call_array].data_offset
            )
        # parse the remaining calls recursively
        _from_call_array_to_call(call_array_len - 1, call_array + AccountCallArray.SIZE, calldata, calls + Call.SIZE)
        return ()
    end


func _checkCall{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _contract: felt, _selector: felt, _callData_len: felt, _callData: felt*):
    alloc_locals
    #check if allowed call
    let (vaultFactory_:felt) = vaultFactory.read()
    let (integrationManager_:felt) = IVaultFactory.getIntegrationManager(vaultFactory_)
    let (isIntegrationAvailable_) = IIntegrationManager.checkIsIntegrationAvailable(integrationManager_, _contract, _selector)
    with_attr error_message("the operation is not allowed on Magnety"):
        assert isIntegrationAvailable_ = 1
    end

    let (fundLevel_) = getFundLevel()
    let (integrationLevel_) = IIntegrationManager.getIntegrationRequiredLevel(integrationManager_, _contract, _selector)
    with_attr error_message("the operation is not allowed for this fund"):
        assert_le(integrationLevel_, fundLevel_)
    end

    #perform pre-call logic if necessary
    let (preLogicContract:felt) = IIntegrationManager.getIntegration(integrationManager_, _contract, _selector)
    let (isPreLogicNonRequired:felt) = _is_zero(preLogicContract)
    let (contractAddress_:felt) = get_contract_address()
    if isPreLogicNonRequired ==  0:
        IPreLogic.runPreLogic(preLogicContract, contractAddress_, _callData_len, _callData)
        return ()
    end
    return ()
end


func is_valid_signature{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            range_check_ptr,
            ecdsa_ptr: SignatureBuiltin*
        }(
            hash: felt,
            signature_len: felt,
            signature: felt*
        ) -> (is_valid: felt):
        let (_public_key) = Account_public_key.read()

        # This interface expects a signature pointer and length to make
        # no assumption about signature validation schemes.
        # But this implementation does, and it expects a (sig_r, sig_s) pair.
        let sig_r = signature[0]
        let sig_s = signature[1]

        verify_ecdsa_signature(
            message=hash,
            public_key=_public_key,
            signature_r=sig_r,
            signature_s=sig_s)

        return (is_valid=TRUE)
    end

    func is_valid_eth_signature{
            syscall_ptr : felt*,
            pedersen_ptr : HashBuiltin*,
            bitwise_ptr: BitwiseBuiltin*,
            range_check_ptr
        }(
            hash: felt,
            signature_len: felt,
            signature: felt*
        ) -> (is_valid: felt):
        alloc_locals
        let (_public_key) = get_public_key()
        let (__fp__, _) = get_fp_and_pc()

        # This interface expects a signature pointer and length to make
        # no assumption about signature validation schemes.
        # But this implementation does, and it expects a the sig_v, sig_r,
        # sig_s, and hash elements.
        let sig_v : felt = signature[0]
        let sig_r : Uint256 = Uint256(low=signature[1], high=signature[2])
        let sig_s : Uint256 = Uint256(low=signature[3], high=signature[4])
        let (high, low) = split_felt(hash)
        let msg_hash : Uint256 = Uint256(low=low, high=high)

        let (local keccak_ptr : felt*) = alloc()

        with keccak_ptr:
            verify_eth_signature_uint256(
                msg_hash=msg_hash,
                r=sig_r,
                s=sig_s,
                v=sig_v,
                eth_address=_public_key)
        end

        return (is_valid=TRUE)
    end


func _get_fee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _vault:felt, key: felt, amount: Uint256) -> (fee: Uint256, fee_asset_manager:Uint256, fee_treasury: Uint256, fee_stacking_vault: Uint256):
    alloc_locals
    let (isEntrance) = _is_zero(key - FeeConfig.ENTRANCE_FEE)
    let (isExit) = _is_zero(key - FeeConfig.EXIT_FEE)
    let (isPerformance) = _is_zero(key - FeeConfig.PERFORMANCE_FEE)
    let (isManagement) = _is_zero(key - FeeConfig.MANAGEMENT_FEE)

    let entranceFee = isEntrance * FeeConfig.ENTRANCE_FEE
    let exitFee = isExit * FeeConfig.EXIT_FEE
    let performanceFee = isPerformance * FeeConfig.PERFORMANCE_FEE
    let managementFee = isManagement * FeeConfig.MANAGEMENT_FEE

    let config = entranceFee + exitFee + performanceFee + managementFee

    let (feeManager_) = _getFeeManager()
    let (percent) = IFeeManager.getFeeConfig(feeManager_, _vault, config)
    let (percent_uint256) = felt_to_uint256(percent)
    let (VF_) = getVaultFactory()
    let (daoTreasuryFee_) = _getDaoTreasuryFee()
    let (stackingVaultFee_) = _getStackingVaultFee()
    let sum_ = daoTreasuryFee_ + stackingVaultFee_
    let assetManagerFee_ = 100 - sum_

    let (fee) = uint256_percent(amount, percent_uint256)
    let (fee_asset_manager) = uint256_percent(fee, Uint256(assetManagerFee_,0))
    let (fee_stacking_vault) = uint256_percent(fee, Uint256(stackingVaultFee_,0))
    let (fee_treasury) = uint256_percent(fee, Uint256(daoTreasuryFee_,0))

    return (fee=fee, fee_asset_manager= fee_asset_manager,fee_treasury=fee_treasury, fee_stacking_vault=fee_stacking_vault)
end


func _calcAmountOfEachAsset{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    totalValue : Uint256, asset_len : felt, asset : felt*, assetAmount_len: felt, assetAmount: Uint256*,denominationAsset: felt) -> (remainingValue:Uint256, len : felt):
    alloc_locals
    if len == 0:
        return (total_value, assetAmount_len)
    end
    let (assetFundbalance_: Uint256) = getAssetBalance(asset[0])
    let (isAssetFundBalanceNul_ : felt) = uint256_eq(assetFundbalance_, Uint256(0,0))
    if isAssetFundBalanceNul_ == 1:
        return _calcAmountOfEachAsset(totalValue, asset_len - 1, asset + 1, assetAmount_len, assetAmount)
    else:
        let (assetvalueInDeno_: Uint256) = getAssetValue(asset[0], assetFundbalance_, denominationAsset_)
        let (isAssetFundBalanceEnought: felt) = uint256_le(totalValue, assetvalueInDeno_)
        if isAssetFundBalanceEnought == 1:
            let (requiredAmount: Uint256) = getAssetValue(denominationAsset_, totalValue, asset[0])
            assert assetAmount[assetAmount_len] = requiredAmount
            return(Uint256(0,0), assetAmount_len + 1)
        else:
            let (remainingAmount_:Uint256) = SafeUint256.sub_le(totalValue, assetvalueInDeno_)
            assert assetAmount[assetAmount_len] = assetFundbalance_
            return _calcAmountOfEachAsset(remainingAmount_, asset_len - 1, asset + 1, assetAmount_len + 1, assetAmount)
        end
    end
end

func _calcAmountOfEachShare{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    totalValue : Uint256, share_len : felt, share : ShareWithdraw*, shareAmount_len : felt*, shareAmount : Uint256*, denominationAsset: felt) -> (remainingValue:Uint256, len : felt):
    alloc_locals
    if len == 0:
        return (total_value, shareAmount_len)
    end
    let (shareFundbalance_: Uint256) = getShareBalance(share[0].address, share[0].id)
    let (isShareFundBalanceNul_ : felt) = uint256_eq(shareFundbalance_, Uint256(0,0))
    if isShareFundBalanceNul_ == 1:
        return _calcAmountOfEachShare(totalValue, share_len - 1, share + ShareWithdraw.SIZE, shareAmount_len, shareAmount)
    else:
        let (sharevalueInDeno_: Uint256) = getShareValue(share[0].address, share[0].id,shareFundbalance_, denominationAsset_)
        let (isShareFundBalanceEnought: felt) = uint256_le(totalValue, sharevalueInDeno_)
        if isShareFundBalanceEnought == 1:
            let (oneSharevalueInDeno_: Uint256) = getShareValue(share[0].address, share[0].id,Uint256(POW18,0), denominationAsset_)
            let (totalValuePow_:Uint256) = uint256_mul(totalValuePow_, POW18)
            let (requiredAmount: Uint256) = uint256_div(totalValuePow_, oneSharevalueInDenoPow_)
            assert shareAmount[shareAmount_len] = requiredAmount
            return(Uint256(0,0), shareAmount_len + 1)
        else:
            let (remainingAmount_:Uint256) = SafeUint256.sub_le(totalValue, sharevalueInDeno_)
            assert shareAmount[shareAmount_len] = shareFundbalance_
            return _calcAmountOfEachShare(remainingAmount_, share_len - 1, share + ShareWithdraw.SIZE, shareAmount_len + 1, shareAmount)
        end
    end
end


func _transferEachAsset{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    fund : felt, caller : felt, manager : felt, stackingVault : felt, daoTreasury : felt, assets_len : felt, assets : felt*, callerAmount : Uint256*, managerAmount : Uint256*, stackingVaultAmount : Uint256*, daoTreasuryAmount : Uint256*
):
    alloc_locals
    if assets_len == 0:
        return ()
    end

    let asset = assets[0]    
    let callerAmount_ = [callerAmount]
    let managerAmount_ = [managerAmount]
    let stackingVaultAmount_ = [stackingVaultAmount]
    let daoTreasuryAmount_ = [daoTreasuryAmount]

    _withdrawAssetTo(asset, caller, callerAmount_)
    _withdrawAssetTo(asset, manager, managerAmount_)
    _withdrawAssetTo(asset, stackingVault, stackingVaultAmount_)
    _withdrawAssetTo(asset, daoTreasury, daoTreasuryAmount_)

    return _transferEachAsset(fund, caller, manager, stackingVault, daoTreasury, assets_len - 1, assets + 1, callerAmount + Uint256.SIZE, managerAmount + Uint256.SIZE, stackingVaultAmount + Uint256.SIZE, daoTreasuryAmount + Uint256.SIZE)
end

func _transferEachShare{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    fund : felt, caller : felt, manager : felt, stackingVault : felt, daoTreasury : felt, shares_len : felt, shares: ShareWithdraw*, callerAmount : Uint256*, managerAmount : Uint256*, stackingVaultAmount : Uint256*, daoTreasuryAmount : Uint256*
):
    alloc_locals
    if shares_len == 0:
        return ()
    end

    let shareAddress = shares[0].address
    let shareId = shares[0].id
    let callerAmount_ = callerAmount[0]
    let managerAmount_ = managerAmount[0]
    let stackingVaultAmount_ = stackingVaultAmount[0]
    let daoTreasuryAmount_ = daoTreasuryAmount[0]
    let (local data : felt*) = alloc()

    _withdrawShareTo(fund, caller, shareAddress, shareId, callerAmount_, 0, data)
    _withdrawShareTo(fund, manager, shareAddress, shareId, callerAmount_, 0, data)
    _withdrawShareTo(fund, stackingVault, shareAddress, shareId, callerAmount_, 0, data)
    _withdrawShareTo(fund, daoTreasury, shareAddress, shareId, callerAmount_, 0, data)

    return _transferEachShare(fund, caller, manager, stackingVault, daoTreasury, shares_len - 1, shares + ShareWithdraw.SIZE, callerAmount + Uint256.SIZE, managerAmount + Uint256.SIZE, stackingVaultAmount + Uint256.SIZE, daoTreasuryAmount + Uint256.SIZE)
end


func __calculGavAsset{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    assets_len : felt, assets : AssetInfo*
) -> (gav : Uint256):
    #Tracked assets GAV 
    alloc_locals
    if assets_len == 0:
        return (gav=Uint256(0, 0))
    end
    let asset_value:Uint256 = assets[assets_len - 1].valueInDeno
    let (gavOfRest) = __calculGavAsset(assets_len=assets_len - 1, assets=assets)
    let (gav, _) = uint256_add(asset_value, gavOfRest)
    return (gav=gav)
end

func __calculGavShare{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    shares_len : felt, shares : ShareInfo*
) -> (gav : Uint256):
    #Tracked assets GAV 
    alloc_locals
    if shares_len == 0:
        return (gav=Uint256(0, 0))
    end
    let share_value:Uint256 = shares[shares_len - 1].valueInDeno
    let (gavOfRest) = __calculGavShare(shares_len=shares_len - 1, shares=shares)
    let (gav, _) = uint256_add(share_value, gavOfRest)
    return (gav=gav)
end

func __calculGavPosition{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    externalPositions_len : felt, externalPositions : PositionInfo*
) -> (gav : Uint256):
    #External position GAV 
    alloc_locals
    if externalPositions_len == 0:
        return (gav=Uint256(0, 0))
    end
    let asset_value:Uint256 = externalPositions[externalPositions_len - 1 ].valueInDeno
    let (gavOfRest) = __calculGavPosition(externalPositions_len=externalPositions_len - 1, externalPositions=externalPositions)
    let (gav, _) = uint256_add(asset_value, gavOfRest)
    return (gav=gav)
end




func _getDaoTreasury{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res: felt
):
    let (vaultFactory_:felt) = vaultFactory.read()
    let (treasury_:felt) = IVaultFactory.getDaoTreasury(vaultFactory_)
    return (res=treasury_)
end

func _getStackingVault{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res: felt
):
    let (vaultFactory_:felt) = vaultFactory.read()
    let (stackingVault_:felt) = IVaultFactory.getStackingVault(vaultFactory_)
    return (res=stackingVault_)
end

func _getDaoTreasuryFee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res: felt
):
    let (vaultFactory_:felt) = vaultFactory.read()
    let (treasury_:felt) = IVaultFactory.getDaoTreasuryFee(vaultFactory_)
    return (res=treasury_)
end

func _getStackingVaultFee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res: felt
):
    let (vaultFactory_:felt) = vaultFactory.read()
    let (stackingVault_:felt) = IVaultFactory.getStackingVaultFee(vaultFactory_)
    return (res=stackingVault_)
end

func _getFeeManager{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res: felt
):
    let (vaultFactory_:felt) = vaultFactory.read()
    let (feeManager_:felt) = IVaultFactory.getFeeManager(vaultFactory_)
    return (res=feeManager_)
end

func _getPolicyManager{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res: felt
):
    let (vaultFactory_:felt) = vaultFactory.read()
    let (policyManager_:felt) = IVaultFactory.getPolicyManager(vaultFactory_)
    return (res=policyManager_)
end

func _getIntegrationManager{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res: felt
):
    let (vaultFactory_:felt) = vaultFactory.read()
    let (integrationManager_:felt) = IVaultFactory.getIntegrationManager(vaultFactory_)
    return (res=integrationManager_)
end

func _getValueInterpretor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    res: felt
):
    let (vaultFactory_:felt) = vaultFactory.read()
    let (valueInterpretor_:felt) = IVaultFactory.getValueInterpretor(vaultFactory_)
    return (res=valueInterpretor_)
end



func _assertMaxminRange{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _amount : Uint256):
    alloc_locals
    let (policyManager_) = _getPolicyManager()
    let (fund_:felt) = get_contract_address()
    let (max:Uint256, min:Uint256) = IPolicyManager.getMaxminAmount(policyManager_, fund_)
    let (le_max) = uint256_le(_amount, max)
    let (be_min) = uint256_le(min, _amount)
    with_attr error_message("_assertMaxminRange: amount is too high"):
        assert le_max = 1
    end
    with_attr error_message("_assertMaxminRange: amount is too low"):
        assert be_min = 1
    end
    return ()
end

func _assertAllowedDepositor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _caller : felt):
    alloc_locals
    let (policyManager_) = _getPolicyManager()
    let (fund_:felt) = get_contract_address()
    let (isPublic_:felt) = IPolicyManager.checkIsPublic(policyManager_, fund_)
    if isPublic_ == 1:
        return()
    else:
        let (isAllowedDepositor_:felt) = IPolicyManager.checkIsAllowedDepositor(policyManager_, fund_, _caller)
        with_attr error_message("_assertAllowedDepositor: not allowed depositor"):
        assert isAllowedDepositor_ = 1
        end
    end
    return ()
end

#helper to make sure the sum is 100%
func _calculTab100{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _percents_len : felt, _percents : felt*) -> (res:felt):
    alloc_locals
    if _percents_len == 0:
        return (0)
    end
    let newPercents_len:felt = _percents_len - 1
    let newPercents:felt* = _percents + 1
    let (_previousElem:felt) = _calculTab100(newPercents_len, newPercents)
    let res:felt = [_percents] + _previousElem
    return (res=res)
end


func _assertEnoughtGuarantee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    let (contractAddress_ : felt) = get_contract_address()
    let (vaultFactory_) = vaultFactory.read()
    let (stackingDispute_) = IVaultFactory.getStackingDispute(vaultFactory_)
    let (securityFundBalance_)  = IStackingDispute.getSecurityFundBalance(stackingDispute_, contractAddress_)
  
    let (shareSupply_) = sharesTotalSupply.read()
    let (managerAccount_) = getManagerAccount()
    let (guaranteeRatio_) = IVaultFactory.getManagerGuaanteeRatio(vaultFactory_, managerAmount_)
    ##Given Per Million
    let (minGuarantee_) =  uint256_permillion(shareSupply_, guaranteeRatio_)

   let (isEnoughtGuarantee_) = uint256_le(minGuarantee_, securityFundBalance_)
   with_attr error_message("_assertEnoughtGuarantee: Asser manager need to provide more guarantee "):
        assert_not_zero(isEnoughtGuarantee_)
    end
   return()
end

func _withdrawAssetTo{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        _asset: felt,
        _target:felt,
        _amount:Uint256,
    ):
    let (_success) = IERC20.transfer(contract_address = _asset,recipient = _target,amount = _amount)
    with_attr error_message("_withdrawAssetTo: transfer didn't work"):
        assert_not_zero(_success)
    end
    return ()
end

func _withdrawShareTo{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        _fund: felt,
        _target:felt,
        _share: felt,
        _id:Uint256,
        _amount:Uint256,
    ):
    IFuccount.safeTransferFrom(_share, _fund, _target, _id, _amount)
    return ()
end

func _reedemTab{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    len : felt, amount : Uint256*, performancePermillion : Uint256, durationPermillion : felt, fund : felt,
    tabLen : felt, callerAmount : Uint256*, managerAmount : Uint256*, stackingVaultAmount : Uint256*, daoTreasuryAmount : Uint256*
) -> ():
    alloc_locals
    if len == 0:
        return ()
    end

    let amount_ : Uint256 = amount[0]

    #PERFORMANCE FEES
    let (millionTimePerf:Uint256) = uint256_mul_low(amount_, performancePermillion)
    let (performanceAmount_ : Uint256) = uint256_div(millionTimePerf, Uint256(PRECISION,0))
    let (fee0, feeAssetManager0, feeDaoTreasury0, feeStackingVault0) = _get_fee(fund, FeeConfig.PERFORMANCE_FEE, performanceAmount_)

    let (remainingAmount0_ : Uint256) = uint256_sub(amount_, fee0)

    #MANAGEMENT FEES
    let (millionTimeDuration_:Uint256) = uint256_mul_low(amount_, Uint256(durationPermillion,0))
    let (managementAmount_ : Uint256) = uint256_div(millionTimeDuration_, Uint256(PRECISION,0))
    let (fee1, feeAssetManager1, feeDaoTreasury1, feeStackingVault1) = _get_fee(fund, FeeConfig.MANAGEMENT_FEE, managementAmount_)

    let (remainingAmount1_ : Uint256) = uint256_sub(remainingAmount0_, fee1)
    let (cumulativeFeeAssetManager1 : Uint256,_) = uint256_add(feeAssetManager0, feeAssetManager1)
    let (cumulativeFeeStackingVault1 : Uint256,_) = uint256_add(feeStackingVault0, feeStackingVault1)
    let (cumulativeFeeDaoTreasury1 : Uint256,_) = uint256_add(feeDaoTreasury0, feeDaoTreasury1)

    #EXIT FEES
    let (fee2, feeAssetManager2, feeDaoTreasury2, feeStackingVault2) = _get_fee(fund, FeeConfig.EXIT_FEE, amount_)
    let (remainingAmount2_ : Uint256) = uint256_sub(remainingAmount1_, fee2)
    let (cumulativeFeeAssetManager2 : Uint256,_) = uint256_add(cumulativeFeeAssetManager1, feeAssetManager2)
    let (cumulativeFeeStackingVault2 : Uint256,_) = uint256_add(cumulativeFeeStackingVault1, feeStackingVault2)
    let (cumulativeFeeDaoTreasury2 : Uint256,_) = uint256_add(cumulativeFeeDaoTreasury1, feeDaoTreasury2)

    assert callerAmount[tabLen] = remainingAmount2_
    assert managerAmount[tabLen] = cumulativeFeeAssetManager2
    assert stackingVaultAmount[tabLen] = cumulativeFeeStackingVault2
    assert daoTreasuryAmount[tabLen] = cumulativeFeeDaoTreasury2

    return _reedemTab(len - 1, amount + Uint256.SIZE, performancePermillion, durationPermillion, fund, tabLen + 1, callerAmount, managerAmount, stackingVaultAmount, daoTreasuryAmount)
end


func _completeNonNulAssetTab{
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
    let (isZero_:felt) = _is_zero(assetBalance_.low)
    if isZero_ == 0:
        assert notNulAssets[notNulAssets_len].address = assetIndex_
        assert notNulAssets[notNulAssets_len].amount = assetBalance_
        let (denominationAsset_:felt) = denominationAsset.read()
        let (assetValue:Uint256) = getAssetValue(assetIndex_, assetBalance_, denominationAsset_)
        assert notNulAssets[notNulAssets_len].valueInDeno = assetValue
        let newNotNulAssets_len = notNulAssets_len + 1
         return _completeNonNulAssetTab(
        availableAssets_len=newAvailableAssets_len,
        availableAssets= availableAssets,
        notNulAssets_len=newNotNulAssets_len,
        notNulAssets=notNulAssets,
        )
    end

    return _completeNonNulAssetTab(
        availableAssets_len=newAvailableAssets_len,
        availableAssets= availableAssets,
        notNulAssets_len=notNulAssets_len,
        notNulAssets=notNulAssets,
        )
end


    func _completeNotNulSharesTab{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(availableAShares_len:felt, availableShares:felt*, notNulShares_len:felt, notNulShares:ShareInfo*, selfAddress:felt, denominationAsset:felt) -> (notNulShares_len:felt):
    alloc_locals
    if availableAShares_len == 0:
        return (notNulShares_len)
    end
    let fundAddress_:felt = availableShares[availableAShares_len - 1] 
    let (assetId_len:felt, assetId:Uint256*, assetAmount_len:felt,assetAmount:Uint256*) = IFuccount.ownerShares(fundAddress_, selfAddress)
    if assetId_len == 0:
        return _completeNotNulSharesTab(
            availableAShares_len=availableAShares_len - 1,
            availableShares= availableShares,
            notNulShares_len=notNulShares_len,
            notNulShares=notNulShares,
            selfAddress=selfAddress,
            denominationAsset= denominationAsset,
            )
    end

    let (newTabLen) = _completeShareInfo(assetId_len, selfAddress, assetId, assetAmount, 0, notNulShares + notNulShares_len, denominationAsset)
    return _completeNotNulSharesTab(
        availableAShares_len=availableAShares_len - 1,
        availableShares= availableShares,
        notNulShares_len= newTabLen ,
        notNulShares=notNulShares,
        selfAddress=selfAddress,
        denominationAsset= denominationAsset,
        )
end

func _completeShareInfo{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(len:felt, fundAddress:felt, assetId:Uint256*, assetAmount:Uint256*, shareInfo_len:felt,shareInfo : ShareInfo*, denominationAsset_:felt) -> (shareInfo_len: felt):
    alloc_locals
    if len == 0:
        return (shareInfo_len)
    end
    assert shareInfo[shareInfo_len].address = fundAddress
    assert shareInfo[shareInfo_len].id = assetId[len -1]
    assert shareInfo[shareInfo_len].amount = assetAmount[len - 1]
    let (valueInDeno_) = getShareValue(fundAddress, assetId[shareInfo_len -1], assetAmount[shareInfo_len - 1], denominationAsset_)
    assert shareInfo[shareInfo_len].valueInDeno = valueInDeno_
    return _completeShareInfo(
        len=len -1,
        fundAddress= fundAddress,
        assetId=assetId,
        assetAmount=assetAmount,
        shareInfo_len=shareInfo_len + 1,
        shareInfo=shareInfo,
        denominationAsset_=denominationAsset_,
        )
end


    func _completeNonNulPositionTab{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(availableExternalPositions_len:felt, availableExternalPositions:felt*, notNulExternalPositions_len:felt, notNulExternalPositions:PositionInfo*) -> (notNulExternalPositions_len:felt):
    alloc_locals
    if availableExternalPositions_len == 0:
        return (notNulExternalPositions_len)
    end
    let newAvailableExternalPositions_len = availableExternalPositions_len - 1
    let externalPositionIndex_:felt = availableExternalPositions[newAvailableExternalPositions_len] 
    let (denominationAsset_:felt) = denominationAsset.read()
    let (contractAddress_:felt) = get_contract_address()
    let (VI_:felt) = _getValueInterpretor()
    let (value_:Uint256) = IValueInterpretor.calculAssetValue(VI_, externalPositionIndex_, Uint256(contractAddress_, 0), denominationAsset_)
    let (isZero_:felt) = _is_zero(value_.low)
    if isZero_ == 0:
        assert notNulExternalPositions[notNulExternalPositions_len].address = externalPositionIndex_
        assert notNulExternalPositions[notNulExternalPositions_len].valueInDeno = value_
        let newNotNulExternalPositions_len = notNulExternalPositions_len +1
         return _completeNonNulPositionTab(
        availableExternalPositions_len=newAvailableExternalPositions_len,
        availableExternalPositions= availableExternalPositions,
        notNulExternalPositions_len=newNotNulExternalPositions_len,
        notNulExternalPositions=notNulExternalPositions,
        )
    end
         return _completeNonNulPositionTab(
        availableExternalPositions_len=newAvailableExternalPositions_len,
        availableExternalPositions= availableExternalPositions,
        notNulExternalPositions_len=notNulExternalPositions_len,
        notNulExternalPositions=notNulExternalPositions,
        )
end


    func _completeMultiShareTab{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(totalId:Uint256, assetId_len:felt, assetId:Uint256*, assetAmount_len:felt,assetAmount:Uint256*, account:felt) -> (tabSize:felt):
    alloc_locals
    if totalId.low == 0:
        return (tabSize=assetId_len)
    end
    let (newTotalId_) =  uint256_sub( totalId, Uint256(1,0))
    let (balance_) = balance_of(account, newTotalId_)
    let (isZero_) = _is_zero(balance_.low)
    if isZero_ == 0:
        # assert assetId[assetId_len*Uint256.SIZE] = newTotalId_
        # assert assetAmount[assetId_len*Uint256.SIZE] = balance_
        assert assetId[assetId_len] = newTotalId_
        assert assetAmount[assetId_len] = balance_
         return _completeMultiShareTab(
        totalId= newTotalId_,
        assetId_len=assetId_len+1,
        assetId= assetId ,
        assetAmount_len=assetAmount_len+1,
        assetAmount=assetAmount ,
        account=account,
        )
    end
    return _completeMultiShareTab(
        totalId=newTotalId_,
        assetId_len= assetId_len,
        assetId=assetId,
        assetAmount_len=assetAmount_len,
        assetAmount=assetAmount,
        account=account,
        )
end


func reduceSupplyBatch{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        amounts_len: felt,
        amounts: Uint256*
    ):

        if amounts_len == 0 :
    return()
end
    let (currentTotalSupply_) = sharesTotalSupply.read()
    let (newTotalSupply_) = uint256_sub(currentTotalSupply_, amounts[amounts_len* Uint256.SIZE - Uint256.SIZE] )
    sharesTotalSupply.write(newTotalSupply_)    
    return reduceSupplyBatch(
        amounts_len= amounts_len - 1,
        amounts=amounts)
end


    func _is_zero{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(x : felt) -> (
    res : felt
):
    if x == 0:
        return (res=1)
    end
    return (res=0)
end


    func _safe_transfer_from{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(
            from_: felt,
            to: felt,
            id: Uint256,
            amount: Uint256,
        ):
        alloc_locals
        # Check args
        with_attr error_message("ERC1155: transfer to the zero address"):
            assert_not_zero(to)
        end
        with_attr error_message("ERC1155: id is not a valid Uint256"):
            uint256_check(id)
        end
        with_attr error_message("ERC1155: amount is not a valid Uint256"):
            uint256_check(amount)
        end

        # Deduct from sender
        let (from_balance: Uint256) = ERC1155_balances.read(id, from_)
        with_attr error_message("ERC1155: insufficient balance for transfer"):
            let (new_balance: Uint256) = SafeUint256.sub_le(from_balance, amount)
        end
        ERC1155_balances.write(id, from_, new_balance)

        # Add to receiver
        let (to_balance: Uint256) = ERC1155_balances.read(id, to)
        with_attr error_message("ERC1155: balance overflow"):
            let (new_balance: Uint256) = SafeUint256.add(to_balance, amount)
        end
        ERC1155_balances.write(id, to, new_balance)

        # Emit events and check
        let (operator) = get_caller_address()
        TransferSingle.emit(
            operator,
            from_,
            to,
            id,
            amount
        )
        return ()
    end

    func _safe_batch_transfer_from{
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
        ):
        alloc_locals
        # Check args
        with_attr error_message("ERC1155: transfer to the zero address"):
            assert_not_zero(to)
        end
        with_attr error_message("ERC1155: ids and amounts length mismatch"):
            assert ids_len = amounts_len
        end
        # Recursive call
        let len = ids_len
        safe_batch_transfer_from_iter(from_, to, len, ids, amounts)

        # Emit events and check
        let (operator) = get_caller_address()
        TransferBatch.emit(
            operator,
            from_,
            to,
            ids_len,
            ids,
            amounts_len,
            amounts
        )
        return ()
    end

    func _mint{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(
            to: felt,
            id: Uint256,
            amount: Uint256,
        ):
        # Cannot mint to zero address
        with_attr error_message("ERC1155: mint to the zero address"):
            assert_not_zero(to)
        end
        # Check uints valid
        with_attr error_message("ERC1155: id is not a valid Uint256"):
            uint256_check(id)
        end
        with_attr error_message("ERC1155: amount is not a valid Uint256"):
            uint256_check(amount)
        end

        # add to minter, check for overflow
        let (to_balance: Uint256) = ERC1155_balances.read(id, to)
        with_attr error_message("ERC1155: balance overflow"):
            let (new_balance: Uint256) = SafeUint256.add(to_balance, amount)
        end
        ERC1155_balances.write(id, to, new_balance)

        # Emit events and check
        let (operator) = get_caller_address()
        TransferSingle.emit(
            operator=operator,
            from_=0,
            to=to,
            id=id,
            value=amount
        )
        return ()
    end

    func _mint_batch{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(
            to: felt,
            ids_len: felt,
            ids: Uint256*,
            amounts_len: felt,
            amounts: Uint256*,
        ):
        alloc_locals
        # Cannot mint to zero address
        with_attr error_message("ERC1155: mint to the zero address"):
            assert_not_zero(to)
        end
        # Check args are equal length arrays
        with_attr error_message("ERC1155: ids and amounts length mismatch"):
            assert ids_len = amounts_len
        end

        # Recursive call
        let len = ids_len
        mint_batch_iter(to, len, ids, amounts)

        # Emit events and check
        let (operator) = get_caller_address()
        TransferBatch.emit(
            operator=operator,
            from_=0,
            to=to,
            ids_len=ids_len,
            ids=ids,
            values_len=amounts_len,
            values=amounts,
        )
        return ()
    end

    func _burn{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(from_: felt, id: Uint256, amount: Uint256):
        alloc_locals
        with_attr error_message("ERC1155: burn from the zero address"):
            assert_not_zero(from_)
        end

        # Check uints valid
        with_attr error_message("ERC1155: id is not a valid Uint256"):
            uint256_check(id)
        end
        with_attr error_message("ERC1155: amount is not a valid Uint256"):
            uint256_check(amount)
        end

        # Deduct from burner
        let (from_balance: Uint256) = ERC1155_balances.read(id, from_)
        with_attr error_message("ERC1155: burn amount exceeds balance"):
            let (new_balance: Uint256) = SafeUint256.sub_le(from_balance, amount)
        end
        ERC1155_balances.write(id, from_, new_balance)

        let (operator) = get_caller_address()
        TransferSingle.emit(operator=operator, from_=from_, to=0, id=id, value=amount)
        return ()
    end

    func _burn_batch{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(
            from_: felt,
            ids_len: felt,
            ids: Uint256*,
            amounts_len: felt,
            amounts: Uint256*
        ):
        alloc_locals
        with_attr error_message("ERC1155: burn from the zero address"):
            assert_not_zero(from_)
        end
        with_attr error_message("ERC1155: ids and amounts length mismatch"):
            assert ids_len = amounts_len
        end

        # Recursive call
        let len = ids_len
        burn_batch_iter(from_, len, ids, amounts)
        let (operator) = get_caller_address()
        TransferBatch.emit(
            operator=operator,
            from_=from_,
            to=0,
            ids_len=ids_len,
            ids=ids,
            values_len=amounts_len,
            values=amounts
        )
        return ()
    end

    func _set_approval_for_all{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(owner: felt, operator: felt, approved: felt):
        # check approved is bool
        assert approved * (approved - 1) = 0
        # caller/owner already checked  non-0
        with_attr error_message("ERC1155: setting approval status for zero address"):
            assert_not_zero(operator)
        end
        with_attr error_message("ERC1155: setting approval status for self"):
            assert_not_equal(owner, operator)
        end
        ERC1155_operator_approvals.write(owner, operator, approved)
        ApprovalForAll.emit(owner, operator, approved)
        return ()
    end


    func assert_owner_or_approved{
            syscall_ptr: felt*,
            pedersen_ptr: HashBuiltin*,
            range_check_ptr
        }(owner):
        let (caller) = get_caller_address()
        if caller == owner:
            return ()
        end
        let (approved) = is_approved_for_all(owner, caller)
        with_attr error_message("ERC1155: caller is not owner nor approved"):
            assert approved = TRUE
        end
        return ()
    end



#
# Private
#





#
# Helpers
#

func balance_of_batch_iter{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        len: felt,
        accounts: felt*,
        ids: Uint256*,
        batch_balances: Uint256*
    ):
    if len == 0:
        return ()
    end
    # Read current entries
    let id: Uint256 = [ids]
    with_attr error_message("ERC1155: id is not a valid Uint256"):
        uint256_check(id)
    end
    let account: felt = [accounts]

    # Get balance
    let (balance: Uint256) = balance_of(account, id)
    assert [batch_balances] = balance
    return balance_of_batch_iter(
        len - 1, accounts + 1, ids + Uint256.SIZE, batch_balances + Uint256.SIZE
    )
end

func safe_batch_transfer_from_iter{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        from_: felt,
        to: felt,
        len: felt,
        ids: Uint256*,
        amounts: Uint256*
    ):
    # Base case
    alloc_locals
    if len == 0:
        return ()
    end

    # Read current entries,  perform Uint256 checks
    let id = [ids]
    with_attr error_message("ERC1155: id is not a valid Uint256"):
        uint256_check(id)
    end
    let amount = [amounts]
    with_attr error_message("ERC1155: amount is not a valid Uint256"):
        uint256_check(amount)
    end

    # deduct from sender
    let (from_balance: Uint256) = ERC1155_balances.read(id, from_)
    with_attr error_message("ERC1155: insufficient balance for transfer"):
        let (new_balance: Uint256) = SafeUint256.sub_le(from_balance, amount)
    end
    ERC1155_balances.write(id, from_, new_balance)

    # add to
    let (to_balance: Uint256) = ERC1155_balances.read(id, to)
    with_attr error_message("ERC1155: balance overflow"):
        let (new_balance: Uint256) = SafeUint256.add(to_balance, amount)
    end
    ERC1155_balances.write(id, to, new_balance)

    # Recursive call
    return safe_batch_transfer_from_iter(
        from_, to, len - 1, ids + Uint256.SIZE, amounts + Uint256.SIZE
    )
end

func mint_batch_iter{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        to: felt,
        len: felt,
        ids: Uint256*,
        amounts: Uint256*
    ):
    # Base case
    alloc_locals
    if len == 0:
        return ()
    end

    # Read current entries
    let id: Uint256 = [ids]
    with_attr error_message("ERC1155: id is not a valid Uint256"):
        uint256_check(id)
    end
    let amount: Uint256 = [amounts]
    with_attr error_message("ERC1155: amount is not a valid Uint256"):
        uint256_check(amount)
    end

    # add to
    let (to_balance: Uint256) = ERC1155_balances.read(id, to)
    with_attr error_message("ERC1155: balance overflow"):
        let (new_balance: Uint256) = SafeUint256.add(to_balance, amount)
    end
    ERC1155_balances.write(id, to, new_balance)

    # Recursive call
    return mint_batch_iter(to, len - 1, ids + Uint256.SIZE, amounts + Uint256.SIZE)
end

func burn_batch_iter{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        from_: felt,
        len: felt,
        ids: Uint256*,
        amounts: Uint256*
    ):
    # Base case
    alloc_locals
    if len == 0:
        return ()
    end

    # Read current entries
    let id: Uint256 = [ids]
    with_attr error_message("ERC1155: id is not a valid Uint256"):
        uint256_check(id)
    end
    let amount: Uint256 = [amounts]
    with_attr error_message("ERC1155: amount is not a valid Uint256"):
        uint256_check(amount)
    end

    # Deduct from burner
    let (from_balance: Uint256) = ERC1155_balances.read(id, from_)
    with_attr error_message("ERC1155: burn amount exceeds balance"):
        let (new_balance: Uint256) = SafeUint256.sub_le(from_balance, amount)
    end
    ERC1155_balances.write(id, from_, new_balance)

    # Recursive call
    return burn_batch_iter(from_, len - 1, ids + Uint256.SIZE, amounts + Uint256.SIZE)
end

end