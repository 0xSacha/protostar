%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin

from starkware.cairo.common.uint256 import (
    Uint256, uint256_check, uint256_add, uint256_sub, uint256_mul,
    uint256_unsigned_div_rem, uint256_le, uint256_lt, uint256_eq
)


from starkware.starknet.common.syscalls import (
    get_block_timestamp, get_contract_address
)

from starkware.cairo.common.bool import (
    TRUE,
    FALSE
)

from openzeppelin.security.safemath import SafeUint256

from openzeppelin.token.erc721.library import ERC721

from openzeppelin.token.erc721_enumerable.library import ERC721_Enumerable

from openzeppelin.introspection.ERC165 import ERC165

#
# Storage
#

@storage_var
func ERC721_sharesBalance(token_id: Uint256) -> (res: Uint256):
end

@storage_var
func ERC721_sharePricePurchased(token_id: Uint256) -> (res: Uint256):
end

@storage_var
func ERC721_sharesTotalSupply() -> (res: Uint256):
end

@storage_var
func ERC721_mintedBlockTimesTamp(token_id: Uint256) -> (res: felt):
end

#
# Constructor
#

@external
func initializeShares{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        name: felt,
        symbol: felt,
    ):
    ERC721.initializer(name, symbol)
    ERC721_Enumerable.initializer()
    return ()
end

#
# Getters
#

@view
func totalSupply{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }() -> (totalSupply: Uint256):
    let (totalSupply: Uint256) = ERC721_Enumerable.total_supply()
    return (totalSupply)
end

@view
func sharesTotalSupply{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }() -> (sharesTotalSupply: Uint256):
    let (sharesTotalSupply: Uint256) = ERC721_sharesTotalSupply.read()
    return (sharesTotalSupply)
end

@view
func tokenByIndex{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(index: Uint256) -> (tokenId: Uint256):
    let (tokenId: Uint256) = ERC721_Enumerable.token_by_index(index)
    return (tokenId)
end

@view
func tokenOfOwnerByIndex{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(owner: felt, index: Uint256) -> (tokenId: Uint256):
    let (tokenId: Uint256) = ERC721_Enumerable.token_of_owner_by_index(owner, index)
    return (tokenId)
end

@view
func supportsInterface{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(interfaceId: felt) -> (success: felt):
    let (success) = ERC165.supports_interface(interfaceId)
    return (success)
end

@view
func name{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (name: felt):
    let (name) = ERC721.name()
    return (name)
end

@view
func symbol{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (symbol: felt):
    let (symbol) = ERC721.symbol()
    return (symbol)
end

@view
func balanceOf{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner: felt) -> (balance: Uint256):
    let (balance: Uint256) = ERC721.balance_of(owner)
    return (balance)
end


@view
func ownerOf{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(tokenId: Uint256) -> (owner: felt):
    let (owner: felt) = ERC721.owner_of(tokenId)
    return (owner)
end

@view
func getApproved{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(tokenId: Uint256) -> (approved: felt):
    let (approved: felt) = ERC721.get_approved(tokenId)
    return (approved)
end

@view
func isApprovedForAll{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner: felt, operator: felt) -> (isApproved: felt):
    let (isApproved: felt) = ERC721.is_approved_for_all(owner, operator)
    return (isApproved)
end

@view
func sharesBalance{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(tokenId: Uint256) -> (sharesBalance: Uint256):

    let (exists) = ERC721._exists(tokenId)
    with_attr error_message("ERC721_Metadata: sharesBalance query for nonexistent token"):
        assert exists = TRUE
    end

    let (sharesBalance: Uint256) = ERC721_sharesBalance.read(tokenId)
    return (sharesBalance)
end

@view
func sharePricePurchased{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(tokenId: Uint256) -> (sharePricePurchased: Uint256):

    let (exists) = ERC721._exists(tokenId)
    with_attr error_message("ERC721_Metadata: sharePricePurchased query for nonexistent token"):
        assert exists = TRUE
    end

    let (sharePricePurchased: Uint256) = ERC721_sharePricePurchased.read(tokenId)
    return (sharePricePurchased)
end

@view
func mintedBlockTimesTamp{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(tokenId: Uint256) -> (mintedBlockTimesTamp: felt):

    let (exists) = ERC721._exists(tokenId)
    with_attr error_message("ERC721_Metadata: mintedBlock query for nonexistent token"):
        assert exists = TRUE
    end

    let (mintedBlockTimesTamp: felt) = ERC721_mintedBlockTimesTamp.read(tokenId)
    return (mintedBlockTimesTamp)
end




#
# External
#

@external
func approve{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(to: felt, tokenId: Uint256):
    ERC721.approve(to, tokenId)
    return ()
end

@external
func setApprovalForAll{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*, 
        range_check_ptr
    }(operator: felt, approved: felt):
    ERC721.set_approval_for_all(operator, approved)
    return ()
end

@external
func transferSharesFrom{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        from_: felt, 
        to: felt, 
        tokenId: Uint256
    ):
    ERC721_Enumerable.transfer_from(from_, to, tokenId)
    return ()
end


@external
func safeTransferFrom{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        from_: felt, 
        to: felt, 
        tokenId: Uint256, 
        data_len: felt,
        data: felt*
    ):
    ERC721_Enumerable.safe_transfer_from(from_, to, tokenId, data_len, data)
    return ()
end

@external
func mint{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(to: felt, sharesAmount: Uint256, sharePricePurchased:Uint256):
    alloc_locals
    let (tokenId:Uint256) = totalSupply()
    ERC721_Enumerable._mint(to, tokenId)

    #set metadata 
    ERC721_sharesBalance.write(tokenId, sharesAmount)
    ERC721_sharePricePurchased.write(tokenId, sharePricePurchased)
    let (block_timestamp) = get_block_timestamp()
    ERC721_mintedBlockTimesTamp.write(tokenId, block_timestamp)

    #set the new supply
    let (supply: Uint256) = ERC721_sharesTotalSupply.read()
    let (new_supply: Uint256) = SafeUint256.add(supply, sharesAmount)
    ERC721_sharesTotalSupply.write(new_supply)
    return ()
end

@external
func burn{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(tokenId: Uint256):
    uint256_check(tokenId)
    let (exists) = ERC721._exists(tokenId)
    with_attr error_message("ERC721_Metadata: sharesBalance query for nonexistent token"):
        assert exists = TRUE
    end

    let (shares:Uint256) = ERC721_sharesBalance.read(tokenId)

    #set the token id balance to 0
    ERC721_sharesBalance.write(tokenId, Uint256(0,0))

    #set the new shares supply
    let (supply:Uint256) = ERC721_sharesTotalSupply.read()
    let (new_supply:Uint256) = SafeUint256.add(supply, shares)
    ERC721_sharesTotalSupply.write(new_supply)

    #burn erc721
    ERC721_Enumerable._burn(tokenId)

    return ()
end

@external
func subShares{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(tokenId: Uint256, sharesToSub:Uint256):
    alloc_locals
    uint256_check(tokenId)
    uint256_check(sharesToSub)

    let (exists) = ERC721._exists(tokenId)

    with_attr error_message("ERC721_Metadata: sharesBalance query for nonexistent token"):
        assert exists = TRUE
    end

    let (res) = uint256_eq(sharesToSub, Uint256(0,0))

    with_attr error_message("ERC721_Metadata: can not sub zero shares"):
        assert res = FALSE 
    end

    let (shares: Uint256) = ERC721_sharesBalance.read(tokenId)

    let (isLess) = uint256_lt(sharesToSub, shares)

    with_attr error_message("ERC721_Metadata: can not sub more than available shares"):
        assert isLess = TRUE
    end


    let (new_shares) = SafeUint256.sub_le(shares, sharesToSub)
    ERC721_sharesBalance.write(tokenId, new_shares)

    #set the new shares supply
    let (supply:Uint256) = ERC721_sharesTotalSupply.read()
    let (new_supply:Uint256) = SafeUint256.sub_le(supply, sharesToSub)
    ERC721_sharesTotalSupply.write(new_supply)

    return ()
end
