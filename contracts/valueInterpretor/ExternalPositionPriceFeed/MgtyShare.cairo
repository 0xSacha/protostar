%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.interfaces.IARFPool import IARFPool
from contracts.interfaces.IARFSwapController import IARFSwapController
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc
from contracts.interfaces.IVaultFactory import IVaultFactory
from contracts.interfaces.IFuccount import IFuccount
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
    let (denominationAsset_:felt) = IFuccount.getDenominationAsset(_holder)
    let (assetId_len:felt, assetId:Uint256*, assetAmount_len:felt,assetAmount:Uint256*) = IFuccount.ownerShares(_externalPosition, _holder)  
    let (amount_ : Uint256) =  __calculValueInDeno(assetId_len, assetId, assetAmount_len,assetAmount, denominationAsset_, _externalPosition)
    let (underlyingsAssets_ : felt*) = alloc()
    let (underlyingsAmount_ : Uint256*) = alloc()
    assert [underlyingsAssets_] = denominationAsset_
    assert [underlyingsAmount_] = amount_
    return (underlyingsAssets_len=1, underlyingsAssets=underlyingsAssets_, underlyingsAmount_len=1, underlyingsAmount=underlyingsAmount_)
end



func __calculValueInDeno{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(assetId_len:felt, assetId:Uint256*, assetAmount_len:felt,assetAmount:Uint256*, denominationAsset : felt, fund : felt) -> (amount : Uint256) :
    alloc_locals
    if assetId_len == 0:
        return (Uint256(0,0))
    end
    let (assets_ : felt*) = alloc()
    let (percents_ : felt*) = alloc()
    assert [assets_] = denominationAsset
    assert [percents_] = 100
    let (_,amount_:Uint256*,_,_,_,_,_,_) =IFuccount.previewReedem(fund, [assetId], [assetAmount], 1, assets_, 1, percents_)
    let (previousAmount_:Uint256) = __calculValueInDeno(assetId_len - 1, assetId + Uint256.SIZE, assetAmount_len - 1,assetAmount + Uint256.SIZE, denominationAsset , fund )
    let (res : Uint256,_) = uint256_add([amount_], previousAmount_)
    return (res)
end