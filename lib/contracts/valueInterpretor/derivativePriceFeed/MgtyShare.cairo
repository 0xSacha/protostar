%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
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
    let (amount:Uint256) = felt_to_uint256(_amount.low)
    let (id:Uint256) = felt_to_uint256(_amount.high)
    let (denominationAsset_: felt, amount_len: felt, amount_:Uint256*) = IFuccount.shareToDeno(id, amount)
    let (local assets_:felt*) = alloc()
    assert assets_[0] = denominationAsset_
    return (1, assets_, amount_len, amount_)
end

