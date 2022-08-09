# SPDX-License-Identifier: MIT
# OpenZeppelin Contracts for Cairo v0.2.1 (account/presets/Account.cairo)

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin

from openzeppelin.introspection.erc165.library import ERC165

from contracts.Account_Lib import Account, AccountCallArray
from contracts.Fund import Fund, AssetInfo, PositionInfo, ShareWithdraw

from starkware.cairo.common.uint256 import (
    Uint256,
)


# Constructor
#

@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(public_key: felt, vaultFactory:felt):
    Account.initializer(public_key, vaultFactory)
    Fund.initializer(vaultFactory)
    return ()
end

#
# Getters
#

@view
func get_public_key{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res) = Account.get_public_key()
    return (res=res)
end

@view
func get_nonce{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res) = Account.get_nonce()
    return (res=res)
end

@view
func supportsInterface{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    } (interfaceId: felt) -> (success: felt):
    let (success) = ERC165.supports_interface(interfaceId)
    return (success)
end



## Fund
@view
func getManagerAccount{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = Fund.getManagerAccount()
    return (res) 
end
@view
func getDenominationAsset{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (res:felt) = Fund.getDenominationAsset()
    return (res=res)
end

@view
func getAssetBalance{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_asset: felt) -> (res: Uint256):
    let (assetBalance_:Uint256) = Fund.getAssetBalance(_asset)
    return (assetBalance_)
end

@view
func getNotNulAssets{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (notNulAssets_len:felt, notNulAssets: AssetInfo*):
    let (notNulAssets_len:felt, notNulAssets:AssetInfo*) = Fund.getNotNulAssets()
    return(notNulAssets_len, notNulAssets)
end

@view
func getNotNulPositions{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (notNulPositions_len:felt, notNulPositions: felt*):
    let (notNulPositions_len:felt, notNulPositions:AssetInfo*) = Fund.getNotNulPositions()
    return(notNulPositions_len, notNulPositions)
end

@view
func getSharePrice{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
     price : Uint256
):
    let (price : Uint256) = Fund.getSharePrice()
    return (price=price)
end

@view
func calculLiquidGav{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    gav : Uint256
):
    let (gav) = Fund.calculLiquidGav()
    return (gav=gav)
end

@view
func calculNotLiquidGav{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    gav : Uint256
):
    let (gav) = Fund.calculNotLiquidGav()
    return (gav=gav)
end


@view
func calculGav{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    gav : Uint256
):
    let (gav) = Fund.calculGav()
    return (gav=gav)
end


@view
func previewReedem{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
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
) -> (assetCallerAmount_len: felt,assetCallerAmount:Uint256*, assetManagerAmount_len: felt,assetManagerAmount:Uint256*,assetStackingVaultAmount_len: felt, assetStackingVaultAmount:Uint256*, assetDaoTreasuryAmount_len: felt,assetDaoTreasuryAmount:Uint256*, shareCallerAmount_len: felt, shareCallerAmount:Uint256*, shareManagerAmount_len: felt, shareManagerAmount:Uint256*, shareStackingVaultAmount_len: felt, shareStackingVaultAmount:Uint256*, shareDaoTreasuryAmount_len: felt, shareDaoTreasuryAmount:Uint256*):
    let (assetCallerAmount_len: felt,assetCallerAmount:Uint256*, assetManagerAmount_len: felt,assetManagerAmount:Uint256*,assetStackingVaultAmount_len: felt, assetStackingVaultAmount:Uint256*, assetDaoTreasuryAmount_len: felt,assetDaoTreasuryAmount:Uint256*, shareCallerAmount_len: felt, shareCallerAmount:Uint256*, shareManagerAmount_len: felt, shareManagerAmount:Uint256*, shareStackingVaultAmount_len: felt, shareStackingVaultAmount:Uint256*, shareDaoTreasuryAmount_len: felt, shareDaoTreasuryAmount:Uint256*) = Fund.previewReedem(id,
    amount,
    assets_len,
    assets,
    percentsAsset_len,
    percentsAsset,
    shares_len,
    shares,
    percentsShare_len,
    percentsShare,
    )
    return(assetCallerAmount_len,assetCallerAmount, assetManagerAmount_len,assetManagerAmount,assetStackingVaultAmount_len, assetStackingVaultAmount, assetDaoTreasuryAmount_len,assetDaoTreasuryAmount, shareCallerAmount_len, shareCallerAmount, shareManagerAmount_len, shareManagerAmount, shareStackingVaultAmount_len, shareStackingVaultAmount, shareDaoTreasuryAmount_len, shareDaoTreasuryAmount)
end


## Shares

@view
func uri{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (uri: felt):
    return Fund.uri()
end



@view
func getName{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (name_) = Fund.name()
    return (name_)
end


@view
func getSymbol{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (symbol_) = Fund.symbol()
    return (symbol_)
end

@view
func totalId{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }() -> (res: Uint256):
    let (totalSupply_: Uint256) = Fund.getTotalId()
    return (totalSupply_)
end

@view
func sharesTotalSupply{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }() -> (res: Uint256):
    let (sharesTotalSupply_: Uint256) = Fund.sharesTotalSupply()
    return (sharesTotalSupply_)
end

@view
func balanceOf{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(account: felt, id: Uint256) -> (balance: Uint256):
    let (balance: Uint256) = Fund.balanceOf(account, id)
    return (balance)
end

@view
func ownerShares{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(account: felt) -> (assetId_len:felt, assetId:Uint256*, assetAmount_len:felt,assetAmount:Uint256*):
    let (assetId_len:felt, assetId:Uint256*, assetAmount_len:felt,assetAmount:Uint256*) = Fund.ownerShares(account)
    return (assetId_len, assetId, assetAmount_len,assetAmount)
end

@view
func getSharePricePurchased{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(tokenId: Uint256) -> (res: Uint256):
    let (sharePricePurchased_: Uint256) =  Fund.sharePricePurchased(tokenId)
    return (sharePricePurchased_)
end


@view
func getMintedTimesTamp{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(tokenId: Uint256) -> (res: felt):
    let (mintedTimesTamp_: felt) = Fund.mintedBlockTimesTamp(tokenId)
    return (mintedTimesTamp_)
end


@view
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
    let (balances_len, balances) =  Fund.balanceOfBatch(accounts_len, accounts, ids_len, ids)
    return (balances_len, balances)
end

@view
func isApprovedForAll{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(account: felt, operator: felt) -> (isApproved: felt):
    let (is_approved) = Fund.isApprovedForAll(account, operator)
    return (is_approved)
end



#
# Setters
#

@external
func activater{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        _fundName: felt,
        _fundSymbol: felt,
        _uri: felt,
        _fundLevel: felt,
        _denominationAsset: felt,
        _managerAccount:felt,
        _shareAmount:Uint256,
        _sharePrice:Uint256,
        data_len:felt,
        data:felt*,
    ):
    Fund.activater( _fundName,
        _fundSymbol,
        _uri,
        _denominationAsset,
        _managerAccount,
        _shareAmount,
        _sharePrice,
        data_len,
        data)
    Account.setFundLevel(_fundLevel)
    return ()
end

@external
func set_public_key{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(new_public_key: felt):
    Account.set_public_key(new_public_key)
    return ()
end

#
# Business logic
#

#Account

@view
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
    let (is_valid) = Account.is_valid_signature(hash, signature_len, signature)
    return (is_valid=is_valid)
end

@external
func __execute__{
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
    let (response_len, response) = Account.execute(
        call_array_len,
        call_array,
        calldata_len,
        calldata,
        nonce
    )
    return (response_len=response_len, response=response)
end

#Fund

@external
func deposit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
      _amount: Uint256, data_len: felt, data: felt*
):
   Fund.deposit(_amount, data_len, data)
    return ()
end


@external
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
    Fund.reedem(id, amount, assets_len, assets, percentsAsset_len, percentsAsset, shares_len, shares, percentsShare_len, percentsShare)
    return ()
end


#Shares

@external
func setApprovalForAll{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(operator: felt, approved: felt):
    Fund.setApprovalForAll(operator, approved)
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
    Fund.safeTransferFrom(from_, to, id, amount, data_len, data)
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
    Fund.safeBatchTransferFrom(
        from_, to, ids_len, ids, amounts_len, amounts, data_len, data)
    return ()
end


@external
func burn{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(from_: felt, id: Uint256, amount: Uint256):
    Fund.burn(from_, id, amount)
    return ()
end

@external
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
    Fund.burnBatch(from_, ids_len, ids, amounts_len, amounts)
    return ()
end