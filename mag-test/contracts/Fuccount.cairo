%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin


from openzeppelin.introspection.ERC165 import ERC165

from contracts.Account_Lib import Account, AccountCallArray
from contracts.Fund import Fund, AssetInfo, PositionInfo

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

## Account

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
func supportsInterfaceFuccount{
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
    }(_asset: felt) -> (assetBalance_: Uint256):
    let (assetBalance_:Uint256) = Fund.getAssetBalance(_asset)
    return (assetBalance_)
end


func getNotNulAssets{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (notNulAssets_len:felt, notNulAssets: AssetInfo*):
    let (notNulAssets_len:felt, notNulAssets:AssetInfo*) = Fund.getNotNulAssets()
    return(notNulAssets_len, notNulAssets)
end

func getNotNulPositions{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (notNulPositions_len:felt, notNulPositition: felt*):
    let (notNulPositions_len:felt, notNulPositition:AssetInfo*) = Fund.getNotNulAssets()
    return(notNulPositions_len, notNulPositition)
end


## Shares

func getName{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (name_: felt):
    let (name_) = Fund.getName()
    return (name_)
end

func getSymbol{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (symbol_: felt):
    let (symbol_) = Fund.getSymbol()
    return (symbol_)
end

func getTotalSupply{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }() -> (totalSupply_: Uint256):
    let (totalSupply_: Uint256) = Fund.getTotalSupply()
    return (totalSupply_)
end

func getSharesTotalSupply{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }() -> (sharesTotalSupply_: Uint256):
    let (sharesTotalSupply_: Uint256) = Fund.getSharesTotalSupply()
    return (sharesTotalSupply_)
end


func getBalanceOf{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner: felt) -> (balance: Uint256):
    let (balance: Uint256) = Fund.getBalanceOf(owner)
    return (balance)
end


func getOwnerOf{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(tokenId: Uint256) -> (owner: felt):
    let (owner: felt) = Fund.getOwnerOf(tokenId)
    return (owner)
end

func getSharesBalance{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(tokenId: Uint256) -> (sharesBalance_: Uint256):
    let (sharesBalance_: Uint256) = Fund.getSharesBalance(tokenId)
    return (sharesBalance_)
end

func getSharePricePurchased{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(tokenId: Uint256) -> (sharePricePurchased_: Uint256):
    let (sharePricePurchased_: Uint256) =  Fund.getSharePricePurchased(tokenId)
    return (sharePricePurchased_)
end

func getMintedTimesTamp{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(tokenId: Uint256) -> (mintedTimesTamp_: felt):
    let (mintedTimesTamp_: felt) = Fund.getMintedTimesTamp(tokenId)
    return (mintedTimesTamp_)
end



## Business 

func getSharePrice{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
     price : Uint256
):
    let (price : Uint256) = Fund.getSharePrice()
    return (price=price)
end

func calculLiquidGav{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    gav : Uint256
):
    let (gav) = Fund.calculLiquidGav()
    return (gav=gav)
end

func calculNotLiquidGav{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    gav : Uint256
):
    let (gav) = Fund.calculNotLiquidGav()
    return (gav=gav)
end

func calculGav{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    gav : Uint256
):
    let (gav) = Fund.calculGav()
    return (gav=gav)
end

func getManagementFeeValue{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (res:Uint256):
    let (claimAmount_) = Fund.getManagementFeeValue()
    return(res=claimAmount_)
end

#
# Setters
#

## Account
@external
func set_public_key{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(new_public_key: felt):
    Account.set_public_key(new_public_key)
    return ()
end

## Fund
@external
func activater{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        _fundName: felt,
        _fundSymbol: felt,
        _denominationAsset: felt,
        _managerAccount:felt,
    ):
    Fund.activater(_fundName, _fundSymbol, _denominationAsset, _managerAccount)
    return ()
end

#
# Business logic
#

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


func claimManagementFee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _assets_len : felt, _assets : felt*, _percents_len:felt, _percents: felt*,
):
    Fund.claimManagementFee( _assets_len, _assets, _percents_len, _percents)
    return ()
end


func mintFromVF{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_assetManager : felt, share_amount : Uint256, share_price : Uint256):
    Fund.mintFromVF(_assetManager, share_amount, share_price)
    return ()
end

func buyShare{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
     _amount: Uint256
):
   Fund.buyShare(_amount)
    return ()
end


@external
func sellShares{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256,
    share_amount : Uint256,
    assets_len : felt,
    assets : felt*,
    percents_len : felt,
    percents : felt*,
):
    Fund.sellShare(token_id, share_amount, assets_len, assets, percents_len, percents)
    return ()
end
