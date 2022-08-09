%lang starknet

from contracts.ERC1155Shares import ERC1155Shares

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    get_block_timestamp,
    get_block_number
)

from starkware.cairo.common.cairo_builtins import HashBuiltin

from contracts.utils.utils import felt_to_uint256, uint256_div, uint256_percent, uint256_pow

from openzeppelin.access.ownable.library import Ownable

@storage_var
func is_fund_disputed(vault : felt) -> (bool : felt):
end

@constructor
func constructor{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(owner_address : felt):
    # Owner address must be the DAO contract
    Ownable.initializer(owner_address)
    return ()
end

@external
func dispute_start{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(vault_address: felt,vault_token_id: Uint256) -> (bool : felt):
    if is_fund_disputed(vault_token_id) == TRUE:
        return(TRUE)
    end

    ## How to get account list of poeple you lock their shares
    let account : felt* = 0
    let (balance_complains_user) = get_complainer_balance(token_id,account,3,0)
    let (percent) = uint256_percent( ERC1155Shares.totalSupply(),balance_complains_user) 
    if is_le(5,percent) == 1:
        is_fund_disputed.write(vault_address,1)
        return(TRUE)
    end
   return(FALSE) 
end

@view
func get_complainer_balance (token_id : felt, account: felt*, account_len : felt, res : felt) -> (res : Uint256):
    alloc_locals
    if account_len == 0:
        return (0)
    end
    if account != Ownable.owner:
        let (local balance : felt) = ERC1155Shares.balanceOf([account],token_id)
    end
    return get_complainer_balance(token_id, account= account + account.SIZE, account_len= account_len - 1, res = res + balance)
end
