%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import (
    get_caller_address, 
    get_contract_address,
    call_contract,
)

from starkware.cairo.common.math import (
    assert_not_zero,
    assert_not_equal,
    assert_le,
)

from starkware.cairo.common.memcpy import memcpy


from openzeppelin.token.erc20.interfaces.IERC20 import IERC20

from contracts.utils.utils import (
    felt_to_uint256,
)

from starkware.cairo.common.alloc import (
    alloc,
)

from starkware.cairo.common.find_element import (
    find_element,
)


from starkware.cairo.common.uint256 import (
    Uint256, 
    uint256_check,
    uint256_le,
    uint256_eq,
)

from openzeppelin.security.safemath import (
    uint256_checked_add,
    uint256_checked_sub_le,
)

from contracts.interfaces.IVault import (
    VaultAction,
)


from shareBaseToken import (

    #NFT Shares getters
    totalSupply,
    sharesTotalSupply,
    name,
    symbol,
    balanceOf,
    ownerOf,
    sharesBalance,
    approve,
    sharePricePurchased,
    mintedBlockTimesTamp,

    #NFT Shares externals
    transferSharesFrom,
    mint,
    burn,
    subShares,

    #init
    initializeShares,
)

#
# Storage
#

@storage_var
func vaultFactory() -> (res : felt):
end

@storage_var
func comptroller() -> (res : felt):
end



@storage_var
func trackedAssets(id : felt) -> (res : felt):
end

@storage_var
func assetToId(asset : felt) -> (res : felt):
end

@storage_var
func trackedAssetsLength() -> (res : felt):
end

@storage_var
func assetToIsTracked(assetsAddress : felt) -> (res : felt):
end


@storage_var
func trackedExternalPositions(id : felt) -> (res : felt):
end

@storage_var
func externalPositionToId(asset : felt) -> (res : felt):
end

@storage_var
func trackedExternalPositionsLength() -> (res : felt):
end

@storage_var
func externalPositionToIsTracked(assetsAddress : felt) -> (res : felt):
end



@storage_var
func positionLimit() -> (res : Uint256):
end

@storage_var
func denominationAsset() -> (res : felt):
end

@storage_var
func assetManager() -> (res : felt):
end



#
# Events
#

@event
func AssetWithdrawn(assetAddress: felt, targetAddress: felt, amount: Uint256):
end

@event
func TrackedAssetAdded(assetAddress: felt):
end

@event
func TrackedAssetRemoved(assetAddress: felt):
end

@event
func TrackedExternalPositionAdded(externalPositionAddress: felt):
end

@event
func TrackedExternalPositionRemoved(externalPositionAddress: felt):
end

# @event
# func NameSet(name: felt):
# end

# @event
# func SymbolSet(symbol: felt):
# end

const FALSE = 0
const TRUE = 1


#
# Getters 
#




@view
func getAssetManager{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = assetManager.read()
    return (res=res)
end

@view
func getDenominationAsset{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = denominationAsset.read()
    return (res=res)
end



@view
func getVaultFactory{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = vaultFactory.read()
    return (res)
    
end

@view
func getAssetBalance{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_asset: felt) -> (assetBalance_: Uint256):
    let (account_:felt) = get_contract_address()
    let (assetBalance_:Uint256) = IERC20.balanceOf(contract_address=_asset, account=account_)
    return (assetBalance_)
end

@view
func getContractAddress{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = get_contract_address()
    return(res)
end

@view
func isTrackedAsset{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_asset: felt) -> (isTrackedAsset_: felt):
    let (isTrackedAsset_:felt) = assetToIsTracked.read(_asset)
    if isTrackedAsset_ == 0:
        return (FALSE)
    end
        return(TRUE)
end

@view
func isTrackedExternalPosition{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_externalPosition: felt) -> (isTrackedExternalPosition_: felt):
    let (isTrackedExternalPosition_:felt) = externalPositionToIsTracked.read(_externalPosition)
    if isTrackedExternalPosition_ == 0:
        return (FALSE)
    end
        return(TRUE)
end

@view
func getTrackedAssets{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (trackedAssets__len:felt, trackedAssets_: felt*):
    alloc_locals
    let (trackedAssets__len:felt) = trackedAssetsLength.read()
    let (local trackedAssets_ : felt*) = alloc()
    completeAssetTab(trackedAssets__len, trackedAssets_, 0)
    return(trackedAssets__len, trackedAssets_)
end


func completeAssetTab{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(trackedAssets__len:felt, trackedAssets_:felt*, index:felt) -> ():

    if trackedAssets__len == 0:
        return ()
    end
    let (trackedAsset_:felt) = trackedAssets.read(index)

    assert [trackedAssets_ + index] = trackedAsset_
    

    let new_index_:felt = index + 1
    let new_trackedAssets__len:felt = trackedAssets__len -1

    return completeAssetTab(
        trackedAssets__len=new_trackedAssets__len,
        trackedAssets_= trackedAssets_,
        index=new_index_,
    )
end

@view
func getTrackedExternalPositions{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (trackedExternalPositions__len:felt, trackedExternalPositions_: felt*):
    alloc_locals
    let (trackedExternalPositions__len:felt) = trackedExternalPositionsLength.read()
    let (local trackedExternalPositions_ : felt*) = alloc()
    completeAssetTab2(trackedExternalPositions__len, trackedExternalPositions_, 0)
    return(trackedExternalPositions__len, trackedExternalPositions_)
end


func completeAssetTab2{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(trackedExternalPositions__len:felt, trackedExternalPositions_:felt*, index:felt) -> ():

    if trackedExternalPositions__len == 0:
        return ()
    end

    let (trackedExternalPosition_:felt) = trackedExternalPositions.read(index)

    assert [trackedExternalPositions_ + index] = trackedExternalPosition_
    
    let new_index_:felt = index + 1
    let newTrackedExternalPositions__len:felt = trackedExternalPositions__len -1

    return completeAssetTab2(
        trackedExternalPositions__len=newTrackedExternalPositions__len,
        trackedExternalPositions_= trackedExternalPositions_,
        index=new_index_,
    )
end

@view
func getPositionsLimit{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (positionLimit_: Uint256):
    let (positionLimit_:Uint256) = positionLimit.read()
    return (positionLimit_)
end

@view
func getcomptroller{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (comptrollerAd: felt):
    let (comptrollerAd: felt) = comptroller.read()
    return (comptrollerAd)
end

#
# NFT Getters 
#

@view
func getTotalSupply{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }() -> (totalSupply_: Uint256):
    let (totalSupply_: Uint256) = totalSupply()
    return (totalSupply_)
end

@view
func getSharesTotalSupply{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }() -> (sharesTotalSupply_: Uint256):
    let (sharesTotalSupply_: Uint256) = sharesTotalSupply()
    return (sharesTotalSupply_)
end




@view
func getName{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (name_: felt):
    let (name_) = name()
    return (name_)
end

@view
func getSymbol{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (symbol_: felt):
    let (symbol_) = symbol()
    return (symbol_)
end

@view
func getBalanceOf{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner: felt) -> (balance: Uint256):
    let (balance: Uint256) = balanceOf(owner)
    return (balance)
end


@view
func getOwnerOf{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(tokenId: Uint256) -> (owner: felt):
    let (owner: felt) = ownerOf(tokenId)
    return (owner)
end



@view
func getSharesBalance{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(tokenId: Uint256) -> (sharesBalance_: Uint256):
    let (sharesBalance_: Uint256) = sharesBalance(tokenId)
    return (sharesBalance_)
end

@view
func getSharePricePurchased{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(tokenId: Uint256) -> (sharePricePurchased_: Uint256):
    let (sharePricePurchased_: Uint256) = sharePricePurchased(tokenId)
    return (sharePricePurchased_)
end

@view
func getMintedBlockTimesTamp{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(tokenId: Uint256) -> (mintedBlock_: felt):
    let (mintedBlock_: felt) = mintedBlockTimesTamp(tokenId)
    return (mintedBlock_)
end

#
# Modifiers
#

func onlyComptroller{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}():
    let (comptroller_) = comptroller.read()
    let (caller_) = get_caller_address()
    with_attr error_message("onlyComptroller: only callable by the comptroller"):
        assert (comptroller_ - caller_) = 0
    end
    return ()
end

func onlyVaultFactory{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}():
    let (vaultFactory_) = vaultFactory.read()
    let (caller_) = get_caller_address()
    with_attr error_message("onlyVaultFactory: only callable by the vaultFactory"):
        assert (vaultFactory_ - caller_) = 0
    end
    return ()
end


#
# Constructor
#
@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        _vaultFactory: felt,
        _comptroller:felt,
    ):
    with_attr error_message("constructor: cannot set the vaultFactory to the zero address"):
        assert_not_zero(_vaultFactory)
    end
    with_attr error_message("constructor: cannot set the comptroller to the zero address"):
        assert_not_zero(_comptroller)
    end
    vaultFactory.write(_vaultFactory)
    comptroller.write(_comptroller)
    return ()
end

#
# Initializer
#
@external
func initializer{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        _fundName: felt,
        _fundSymbol: felt,
        _assetManager: felt,
        _denominationAsset: felt,
        _positionLimitAmount: Uint256,
    ):
    onlyVaultFactory()
    initializeShares(_fundName, _fundSymbol)
    assetManager.write(_assetManager)
    denominationAsset.write(_denominationAsset)
    __addTrackedAsset(_denominationAsset)
    uint256_check(_positionLimitAmount)
    positionLimit.write(_positionLimitAmount)
    return ()
end




@external
func receiveValidatedVaultAction{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _action: felt,
        _actionData_len:felt,
        _actionData:felt*,
    ):
    alloc_locals
    onlyComptroller()
    if  _action == VaultAction.AddTrackedAsset : 
        __executeVaultActionAddTrackedAsset(_actionData)
        return ()
        else:
            if _action == VaultAction.BurnShares:
                __executeVaultActionBurnShares(_actionData)
                return ()
                else:
                    if _action == VaultAction.MintShares:
                        __executeVaultActionMintShares(_actionData)
                        return ()
                        else:
                            if _action == VaultAction.RemoveTrackedAsset:
                                __executeVaultActionRemoveTrackedAsset(_actionData)
                                return ()
                                else:
                                    if _action == VaultAction.TransferShares:
                                        __executeVaultActionTransferShares(_actionData)
                                        return ()
                                        else:
                                            if _action == VaultAction.WithdrawAssetTo:
                                                __executeVaultActionWithdrawAssetTo(_actionData)
                                                return ()
                                                else:
                                                    if _action == VaultAction.ExecuteCall:
                                                        __executeVaultActionExecuteCall(_actionData)
                                                        return ()
                                                        else:
                                                            if _action == VaultAction.AddTrackedExternalPosition: 
                                                            __executeVaultActionAddTrackedExternalPosition(_actionData)
                                                            return ()
                                                            else:
                                                                if _action == VaultAction.RemoveTrackedExternalPosition : 
                                                                __executeVaultActionRemoveTrackedExternalPosition(_actionData)
                                                                return ()
                                                                end
                                                            end
                                                        end
                                                end
                                        end
                                end
                        end
                end
        end
    return ()
end



#
# internal
#

func mintShares{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _amount: Uint256,
        _newSharesholder:felt,
        _sharePricePurchased:Uint256,
    ):
    onlyComptroller()
    let (_tokenId:Uint256) = totalSupply()
   mint(_newSharesholder, _amount, _sharePricePurchased)
   return ()
end







#
# VAULT ACTION DISPATCH
#

func __executeVaultActionAddTrackedAsset{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_actionData: felt*):
    let address_:felt = _actionData[0]
    __addTrackedAsset(address_)
    return ()
end

func __executeVaultActionAddTrackedExternalPosition{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_actionData: felt*):
    let address_:felt = _actionData[0]
    __addTrackedExternalPosition(address_)
    return ()
end

func __executeVaultActionRemoveTrackedAsset{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_actionData: felt*):
    let address_:felt = _actionData[0]
    __removeTrackedAsset(address_)
    return ()
end

func __executeVaultActionRemoveTrackedExternalPosition{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_actionData: felt*):
    let address_:felt = _actionData[0]
    __removeTrackedExternalPosition(address_)
    return ()
end


func __executeVaultActionBurnShares{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_actionData: felt*):
    let (tokenId_:Uint256) = felt_to_uint256(_actionData[0])
    let (amount_:Uint256) = felt_to_uint256(_actionData[1])
    __burnShares(amount_, tokenId_)
    return ()
end

func __burnShares{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _amount: Uint256,
        _tokenId:Uint256,
    ):
    alloc_locals
    let(_comptroller:felt) = comptroller.read()
    let(_caller:felt) = get_caller_address()
    let(_shareowner:felt)  = ownerOf(_tokenId)
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

func __executeVaultActionMintShares{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_actionData: felt*):
    let newSharesholder_:felt = _actionData[0]
    let (amount_:Uint256) = felt_to_uint256(_actionData[1])
    let (sharePricePurchased_:Uint256) = felt_to_uint256(_actionData[2])
    __mintShares(amount_, newSharesholder_, sharePricePurchased_)
    return ()
end

func __mintShares{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _amount: Uint256,
        _newSharesholder:felt,
        _sharePricePurchased:Uint256,
    ):
    let (_tokenId:Uint256) = totalSupply()
   mint(_newSharesholder, _amount, _sharePricePurchased)
   return ()
end


func __executeVaultActionTransferShares{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_actionData: felt*):
    let from_:felt = _actionData[0]
    let to_:felt = _actionData[1]
    let (tokenId_:Uint256) = felt_to_uint256(_actionData[2])
    transferSharesFrom(from_, to_, tokenId_)
    return ()
end

func __executeVaultActionWithdrawAssetTo{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_actionData: felt*):
    let asset_:felt = _actionData[0]
    let target_:felt = _actionData[1]
    let (amount_:Uint256) = felt_to_uint256(_actionData[2])
    __withdrawAssetTo(asset_, target_, amount_)
    return ()
end

func __executeVaultActionExecuteCall{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_actionData: felt*):
    alloc_locals
    
    let contract_:felt = _actionData[0]
    let selector_:felt = _actionData[1]
    let callData_len:felt = _actionData[2]

    let (callData: felt*) = alloc()
    memcpy(callData, _actionData + 3, callData_len)

     # execute call
    let response = call_contract(
        contract_address=contract_,
        function_selector=selector_,
        calldata_size=callData_len,
        calldata=callData)
    return ()
end



#
# VAULT ACTION 
#

func __addTrackedAsset{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_asset: felt):

    let (isTrackedAsset_:felt) = isTrackedAsset(_asset)
    with_attr error_message("__addTrackedAsset: asset already tracked"):
        assert isTrackedAsset_ = FALSE
    end
    __validatePositionsLimit()
    let (currentTrackedAssetsLength: felt) = trackedAssetsLength.read()
    assetToIsTracked.write(_asset,TRUE)
    trackedAssets.write(currentTrackedAssetsLength,_asset)
    assetToId.write(_asset,currentTrackedAssetsLength)
    let newTrackedAssetsLength_: felt = currentTrackedAssetsLength + 1
    trackedAssetsLength.write(newTrackedAssetsLength_)
    TrackedAssetAdded.emit(_asset)
    return ()
end

func __addTrackedExternalPosition{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_externalPosition: felt):

    let (isTrackedExternalPosition_:felt) = isTrackedExternalPosition(_externalPosition)
    with_attr error_message("__addTrackedExternalPosition: ExternalPosition already tracked"):
        assert isTrackedExternalPosition_ = FALSE
    end
    # __validatePositionsLimit()
    let (currentTrackedExternalPositionsLength: felt) = trackedExternalPositionsLength.read()
    externalPositionToIsTracked.write(_externalPosition,TRUE)
    trackedExternalPositions.write(currentTrackedExternalPositionsLength,_externalPosition)
    externalPositionToId.write(_externalPosition,currentTrackedExternalPositionsLength)
    let newTrackedExternalPositionsLength_: felt = currentTrackedExternalPositionsLength + 1
    trackedExternalPositionsLength.write(newTrackedExternalPositionsLength_)
    TrackedExternalPositionAdded.emit(_externalPosition)
    return ()
end

func __removeTrackedAsset{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_asset: felt):
    alloc_locals
    let (isTrackedAsset_:felt) = isTrackedAsset(_asset)
    with_attr error_message("__removeTrackedAsset: asset not tracked"):
        assert isTrackedAsset_ = TRUE
    end
    assetToIsTracked.write(_asset,FALSE)
    let (currentTrackedAssetsLength_: felt) = trackedAssetsLength.read()
    let (id:felt) = assetToId.read(_asset)
    let res:felt = currentTrackedAssetsLength_- id
    let newTrackedAssetsLength_: felt = currentTrackedAssetsLength_ - 1
    if res == 1: 
    trackedAssets.write(id, 0)
    else:
        let lastAssetId:felt = newTrackedAssetsLength_
        let (lastAsset:felt) = trackedAssets.read(lastAssetId)
        trackedAssets.write(lastAssetId, 0)
        trackedAssets.write(id, lastAsset)
        assetToId.write(lastAsset, id)
    end
    trackedAssetsLength.write(newTrackedAssetsLength_)
    TrackedAssetRemoved.emit(_asset)
    return ()
end

func __removeTrackedExternalPosition{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_externalPosition: felt):
    alloc_locals
    let (isTrackedExternalPosition_:felt) = isTrackedExternalPosition(_externalPosition)
    with_attr error_message("__removeTrackedExternalPosition: ExternalPosition not tracked"):
        assert isTrackedExternalPosition_ = TRUE
    end
    externalPositionToIsTracked.write(_externalPosition,FALSE)
    let (currentTrackedExternalPositionsLength_: felt) = trackedExternalPositionsLength.read()
    let (id:felt) = externalPositionToId.read(_externalPosition)
    let res:felt = currentTrackedExternalPositionsLength_- id
    let newTrackedExternalPositionsLength_: felt = currentTrackedExternalPositionsLength_ - 1
    if res == 1: 
    trackedExternalPositions.write(id, 0)
    else:
        let lastExternalPositionId:felt = newTrackedExternalPositionsLength_
        let (lastExternalPosition:felt) = trackedExternalPositions.read(lastExternalPositionId)
        trackedExternalPositions.write(lastExternalPositionId, 0)
        trackedExternalPositions.write(id, lastExternalPosition)
        externalPositionToId.write(lastExternalPosition, id)
    end
    trackedExternalPositionsLength.write(newTrackedExternalPositionsLength_)
    TrackedExternalPositionRemoved.emit(_externalPosition)
    return ()
end


func __validatePositionsLimit{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }():
    alloc_locals
    let (positionLimit_:Uint256) = getPositionsLimit()
    let (trackedAssetsLength_:felt) = trackedAssetsLength.read()
    let (trackedExternalPositionsLength_:felt) = trackedExternalPositionsLength.read()
    let (totalTrackedLengthUint_:Uint256) = felt_to_uint256(trackedAssetsLength_ + trackedExternalPositionsLength_)
    let (res__) = uint256_le(totalTrackedLengthUint_, positionLimit_)
    with_attr error_message("__validatePositionsLimit: Limit exceeded"):
        assert res__ = TRUE
    end
    return ()
end

func __withdrawAssetTo{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        _asset: felt,
        _target:felt,
        _amount:Uint256,
    ):
    let (_success) = IERC20.transfer(contract_address = _asset,recipient = _target,amount = _amount)
    with_attr error_message("__withdrawAssetTo: transfer didn't work"):
        assert_not_zero(_success)
    end

    AssetWithdrawn.emit(_asset, _target, _amount)
    return ()
end