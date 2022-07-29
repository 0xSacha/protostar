%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.interfaces.IARFPool import IARFPool
from contracts.interfaces.IARFSwapController import IARFSwapController
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc
from interfaces.IVaultFactory import IVaultFactory
from interfaces.IFuccount import IFuccount
from starkware.cairo.common.uint256 import (
    uint256_sub,
    uint256_check,
    uint256_le,
    uint256_eq,
    uint256_add,
    uint256_mul,
)
from starkware.starknet.common.syscalls import (
    get_tx_info,
    get_block_number,
    get_block_timestamp,
    get_contract_address,
    get_caller_address,
)
from contracts.utils.utils import felt_to_uint256, uint256_div, uint256_percent

const POW18 = 1000000000000000000

#
#Getter
#

@view
func calcUnderlyingValues{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_externalPosition: felt, _holder: felt) -> ( underlyingsAssets_len:felt, underlyingsAssets:felt*, underlyingsAmount_len:felt, underlyingsAmount:Uint256* ):
    alloc_locals
    
    let (holderBalance_:Uint256) = IFuccount.getBalanceOf(_externalPosition, _holder)
    ##get ID tab
    let (IDs : Uint256*) = alloc()
    __completeIdTab(holderBalance_.low, IDs, _holder, _externalPosition)

    let (underlyingsAssets_ : felt*) = alloc()
    let (underlyingsAmount_ : Uint256*) = alloc()
    let (deno_:felt) = IFuccount.getDenominationAsset(_externalPosition)
    assert [underlyingsAssets_] = deno_
    let (totalUnderlyingsAssetAmount_:Uint256) = __sumSharesValue(holderBalance_.low, IDs, _externalPosition)
    assert [underlyingsAmount_] = totalUnderlyingsAssetAmount_
    return (underlyingsAssets_len=1, underlyingsAssets=underlyingsAssets_, underlyingsAmount_len=1, underlyingsAmount=underlyingsAmount_)
end



func __completeIdTab{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _id_len : felt, _id : Uint256*, holder:felt, fundAddress:felt):
    alloc_locals
    let newId_len:felt = _id_len - 1
    let newId:Uint256* = _id + 2
    let (id_:Uint256) = IFuccount.getTokenOfOwnerByIndex(fundAddress,holder, Uint256(newId_len,0))
    assert [_id] = id_
    if newId_len == 0:
        return ()
    end
    return __completeIdTab(newId_len, newId, holder, fundAddress)
end



func __sumSharesValue{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _id_len : felt, _id : Uint256*, _externalPosition : felt) -> (res:Uint256):
    alloc_locals
    if _id_len == 0:
        return (Uint256(0,0))
    end
    let newId_len:felt = _id_len - 1
    let newId:Uint256* = _id + 2
    let (_previousElem:Uint256) = __sumSharesValue(newId_len, newId, _externalPosition)
    let (shareBalance_:Uint256) = IFuccount.getSharesBalance(_externalPosition, [_id])
    let (sharePrice_:Uint256) = IFuccount.getSharePrice(_externalPosition)
    let (step1_:Uint256,_) = uint256_mul(sharePrice_, shareBalance_)
    let (shareValue_:Uint256) = uint256_div(step1_,Uint256(POW18,0))
    ##shares have 18 decimals
    let (res:Uint256,_) = uint256_add(_previousElem, shareValue_)
    return (res=res)
end