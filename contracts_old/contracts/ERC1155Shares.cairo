%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_sub,
    uint256_check,
    uint256_le,
    uint256_eq,
    uint256_add,
    uint256_mul,
)
from starkware.starknet.common.syscalls import (
    get_block_timestamp, get_contract_address, get_caller_address
)
from starkware.cairo.common.math import assert_not_zero

from contracts.erc1155 import ERC1155
from openzeppelin.introspection.erc165.library import ERC165

from starkware.cairo.common.alloc import (
    alloc,
)


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
func name() -> (res: felt):
end

@storage_var
func symbol() -> (res: felt):
end

namespace ERC1155Shares:

#
# initialize
#

func initializeShares{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        _name: felt,
        _symbol: felt,
        uri: felt,
        
    ):
    name.write(_name)
    symbol.write(_symbol)
    ERC1155.initializer(uri)
    return ()
end

#
# Getters
#


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

func uri{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }() -> (uri: felt):
    return ERC1155.uri()
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
    let (tabSize_:felt) = completeMultiAssetTab(totalId_, 0, assetId, 0, assetAmount, account)    
    return (tabSize_, assetId, tabSize_, assetAmount)
end

func completeMultiAssetTab{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(totalId:Uint256, assetId_len:felt, assetId:Uint256*, assetAmount_len:felt,assetAmount:Uint256*, account:felt) -> (tabSize:felt):
    alloc_locals
    if totalId.low == 0:
        return (tabSize=assetId_len)
    end
    let (newTotalId_) =  uint256_sub( totalId, Uint256(1,0))
    let (balance_) = balanceOf(account, newTotalId_)
    let (isZero_) = __is_zero(balance_.low)
    if isZero_ == 0:
        # assert assetId[assetId_len*Uint256.SIZE] = newTotalId_
        # assert assetAmount[assetId_len*Uint256.SIZE] = balance_
        assert assetId[assetId_len] = newTotalId_
        assert assetAmount[assetId_len] = balance_
         return completeMultiAssetTab(
        totalId= newTotalId_,
        assetId_len=assetId_len+1,
        assetId= assetId ,
        assetAmount_len=assetAmount_len+1,
        assetAmount=assetAmount ,
        account=account,
        )
    end
    return completeMultiAssetTab(
        totalId=newTotalId_,
        assetId_len= assetId_len,
        assetId=assetId,
        assetAmount_len=assetAmount_len,
        assetAmount=assetAmount,
        account=account,
        )
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


func setApprovalForAll{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(operator: felt, approved: felt):
    ERC1155.set_approval_for_all(operator, approved)
    return ()
end

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
        _sharePricePurchased:Uint256,
        data_len: felt,
        data: felt*
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
    ERC1155._mint(to, totalId_, sharesAmount, data_len, data)
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
    ERC1155.assert_owner_or_approved(owner=from_)
    let (caller) = get_caller_address()
    with_attr error_message("ERC1155: called from zero address"):
        assert_not_zero(caller)
    end
    ERC1155._burn_batch(from_, ids_len, ids, amounts_len, amounts)
    reduceSupplyBatch(amounts_len, amounts)
    return ()
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


    func __is_zero{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(x : felt) -> (
    res : felt
):
    if x == 0:
        return (res=1)
    end
    return (res=0)
end

end

