%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_not_zero

from openzeppelin.access.ownable.library import Ownable
from openzeppelin.token.erc1155.library import ERC1155
from openzeppelin.introspection.erc165.library import ERC165


#
# Storage
#

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
func name() -> (res: Uint256):
end

@storage_var
func symbol() -> (res: Uint256):
end

namespace ERC1155Shares:

#
# initialize
#

@external
func initializeShares{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        name: felt,
        symbol: felt,
        uri: felt,
        
    ):
    name.write(name)
    symbol.write(symbol)
    ERC1155.initializer(uri)
    return ()
end

#
# Getters
#


func sharePricePurchased{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(tokenId: Uint256) -> (sharePricePurchased: Uint256):
    let (sharePricePurchased: Uint256) = sharePricePurchased.read(tokenId)
    return (sharePricePurchased)
end

func mintedBlockTimesTamp{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(tokenId: Uint256) -> (mintedBlockTimesTamp: felt):
    let (mintedBlockTimesTamp: felt) = mintedBlockTimesTamp.read(tokenId)
    return (mintedBlockTimesTamp)
end


@view
func supportsInterface{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(interfaceId: felt) -> (success: felt):
    return ERC165.supports_interface(interfaceId)
end

@view
func uri{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (uri: felt):
    return ERC1155.uri()
end

@view
func sharesTotalSupply{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }() -> (totalSupply: Uint256):
    let (totalSupply: Uint256) = sharesTotalSupply.read()
    return (totalSupply)
end

@view
func totalId{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }() -> (totalId: Uint256):
    let (totalId: Uint256) = totalId.read()
    return (totalId)
end

func balanceOf{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(account: felt, id: Uint256) -> (balance: Uint256):
    return ERC1155.balance_of(account, id)
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
    let (tabSize_:felt) = completeMultiAssetTab(totalId, 0, assetId, 0, assetAmount, account)    
    return (tabSize_, assetId, tabSize_, assetAmount)
end

func completeMultiAssetTab{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(totalId:felt, assetId_len:felt, assetId:Uint256*, assetAmount_len:felt,assetAmount:Uint256*, account:felt) -> (tabSize:felt):
    alloc_locals
    if totalId == 0:
        return (tabSize=assetId_len)
    end
    let newTotalId = totalId - 1
    let (balance:Uint256) = balanceOf(account, assetId_len)
    let (isZero_:felt) = __is_zero(balance.low)
    if isZero_ == 0:
        let newAssetId_len:felt = assetId_len + 1
        let newAssetAmount_len:felt = assetAmount_len + 1
        assert assetId[assetId_len*Uint256.SIZE].address = assetIndex_
        assert assetAmount[assetId_len*Uint256.SIZE].amount = assetBalance_
         return completeNonNulAssetTab(
        totalId= newTotalId
        assetId_len=newAssetId_len,
        assetId= availableAssets,
        assetAmount_len=newAssetAmount_len,
        assetAmount=assetAmount
        account=account,
        )
    end
    return completeMultiAssetTab(
        totalId=newTotalId,
        assetId_len= availableAssets,
        assetId=notNulAssets_len,
        assetAmount_len=notNulAssets,
        assetAmount=assetAmount,
        account=account,
        )
end

@view
func name{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (name: felt):
    let (name) = name.read()
    return (name)
end

@view
func symbol{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (symbol: felt):
    let (symbol) = symbol.read()
    return (symbol)
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
    let (balances_len, balances) =  ERC1155.balance_of_batch(accounts_len, accounts, ids_len, ids)
    return (balances_len, balances)
end

@view
func isApprovedForAll{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(account: felt, operator: felt) -> (isApproved: felt):
    let (is_approved) = ERC1155.is_approved_for_all(account, operator)
    return (is_approved)
end


#
# Externals
#

@external
func setURI{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(uri: felt):
    ERC1155._set_uri(uri)
    return ()
end

@external
func setApprovalForAll{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(operator: felt, approved: felt):
    ERC1155.set_approval_for_all(operator, approved)
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
    ERC1155.safe_transfer_from(from_, to, id, amount, data_len, data)
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
    ERC1155.safe_batch_transfer_from(
        from_, to, ids_len, ids, amounts_len, amounts, data_len, data)
    return ()
end

func mint{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        to: felt, 
        sharesAmount: Uint256, 
        sharePricePurchased:Uint256
        data_len: felt,
        data: felt*
    ):
    let (totalId_) = totalId.read()
    ERC1155._mint(to, totalId_, sharesAmount, data_len, data)
    sharePricePurchased.write(totalId_, sharePricePurchased)
    let (currentTimesTamp_:felt) = get_block_timestamp()
    mintedBlockTimesTamp.write(totalId_, currentTimesTamp_)
    return ()
end

func burn{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(from_: felt, id: Uint256, amount: Uint256):
    ERC1155.assert_owner_or_approved(owner=from_)
    let (caller) = get_caller_address()
    with_attr error_message("ERC1155: called from zero address"):
        assert_not_zero(caller)
    end
    ERC1155._burn(from_, id, amount)
    return ()
end

