%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.interfaces.IARFPool import IARFPool
from contracts.interfaces.IARFSwapController import IARFSwapController
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc
from contracts.interfaces.IVaultFactory import IVaultFactory
from contracts.interfaces.IFuccount import IFuccount, ShareWithdraw
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


#
#Getter
#


@view
func calcUnderlyingValues{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_derivative: felt, _amount: Uint256) -> ( underlyingsAssets_len:felt, underlyingsAssets:felt*, underlyingsAmount_len:felt, underlyingsAmount:Uint256* ):
    alloc_locals
    let (denominationAsset_:felt) = IFuccount.getDenominationAsset(_derivative)
    let (amount:Uint256) = felt_to_uint256(_amount.low)
    let (id:Uint256) = felt_to_uint256(_amount.high)

    let (local assets_:felt*) = alloc()
    let (local percentsAsset_:felt*) = alloc()
    assert assets_[0] = denominationAsset_
    assert percentsAsset_[0] = 100
    let (local shares_:ShareWithdraw*) = alloc()
    let (local percentsShare_:felt*) = alloc()

    let (_,amount_:Uint256*,_,_,_,_,_,_,_,_,_,_,_,_,_,_) =IFuccount.previewReedem(_derivative, id, amount, 1, assets_, 1, percentsAsset_, 0, shares_, 0, percentsShare_)
    return (1, assets_, 1, amount_)
end

