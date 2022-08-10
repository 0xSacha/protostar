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

from contracts.interfaces.IFuccount import IFuccount

from openzeppelin.access.ownable.library import Ownable

@storage_var
func is_fund_disputed(vault : felt) -> (bool : felt):
end

@storage_var
func user_to_share (address : felt, token_id: Uint256) -> (balance : Uint256):
end

@storage_var
func report_fund_balance(vault_address : felt) -> (balance : Uint256):
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
func deposit_to_dispute_fund {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(token_id : felt, amount_to_deposit: Uint256) -> ():
    let (caller_addr) = get_caller_address()
    let (balance_user) = user_to_share.read(caller_addr,token_id)
    let(contract_address) = get_contract_address()
    IFuccount.safeTransferFrom(caller_addr,contract_address,token_id,amount_to_deposit,0,0)
    user_to_share.write(caller_addr,token_id,amount_to_deposit + balance_user)
    return()
end

@external
func withdraw_to_dispute_fund {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(vault_address : felt, token_id : felt,amount_to_withdraw : Uint256) -> ():
    let (caller_addr) = get_caller_address()
    let (vault_status) = is_fund_disputed.read(vault_address)
    if vault_status == TRUE:
        return()
    end

    let (balance_user) = user_to_share.read(caller_addr,token_id)
    let(contract_address) = get_contract_address()
    IFuccount.safeTransferFrom(contract_address,caller_addr,token_id,amount_to_withdraw,0,0)
    user_to_share.write(caller_addr,token_id, balance_user - amount_to_withdraw)
    return()
end

func check_report_fund_balance {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(vault_address : felt, token_id: Uint256) -> (balance: Uint256):
    let(contract_address) = get_contract_address()
    let (assetId_len:felt, assetId:Uint256*, assetAmount_len:felt,assetAmount:Uint256*) = IFuccount.ownerShares(contract_address)
    let (check_balance) = report_fund_balance_rec(assetId_len, assetId, assetAmount_len,assetAmount,0,token_id)
    report_fund_balance.write(vault_address, check_balance)
    return(check_balance) 
end

func report_fund_balance_rec (assetId_len:felt, assetId:Uint256*, assetAmount_len:felt,assetAmount:Uint256*, balance : Uint256, token_id : Uint256) -> (balance: Uint256):
    if assetId_len == 0:
        return (0)
    end
    let (current_asset_id) =  [assetId]
    if current_asset_id == token_id:
        let (balance_to_add) = [assetAmount] 
        return(assetId_len = assetId_len - 1, assetId = assetId + assetId.SIZE, assetAmount_len = assetAmount_len - 1, assetAmount = assetAmount + assetAmount.SIZE, balance = balance + balance_to_add, token_id = token_id)
    end

    return(assetId_len = assetId_len - 1, assetId = assetId + assetId.SIZE, assetAmount_len = assetAmount_len - 1, assetAmount = assetAmount + assetAmount.SIZE, balance = balance, token_id = token_id)
end

func dispute_start{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(vault_address: felt) -> (bool : felt):
    if is_fund_disputed(vault_token_id) == TRUE:
        return(TRUE)
    end

    let account : felt* = 0
    let (balance_complains_user) = report_fund_balance.read(vault_address)
    let (percent) = uint256_percent(IFuccount.sharesTotalSupply(),balance_complains_user) 
    if is_le(5,percent) == 1:
        is_fund_disputed.write(vault_address,1)
        return(TRUE)
    end
   return(FALSE) 
end
