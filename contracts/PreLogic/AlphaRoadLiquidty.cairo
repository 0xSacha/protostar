%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.interfaces.IVault import IVault
from contracts.interfaces.IARFPoolFactory import IARFPoolFactory, PoolPair
from starkware.cairo.common.math import assert_not_zero

@storage_var
func IARFPoolFactoryContract() -> (res : felt):
end



@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        _IARFPoolFactory: felt,
    ):
    IARFPoolFactoryContract.write(_IARFPoolFactory)
    return ()
end

@external
func runPreLogic{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr 
    }(_vault:felt, _callData_len:felt, _callData:felt*):
    let (IARFPoolFactoryContract_:felt) = IARFPoolFactoryContract.read()
    let token0_:felt = [_callData]
    let token1_:felt = [_callData + 1]
    let poolPair_ = PoolPair(token0_,token1_)
    let (incomingAsset_:felt) = IARFPoolFactory.getPool(IARFPoolFactoryContract_, poolPair_)
    let (isTrackedAsset_:felt) = IVault.isTrackedAsset(_vault, incomingAsset_)
    with_attr error_message("addLiquidityFromAlpha: incoming LP Asset not tracked"):
        assert_not_zero(isTrackedAsset_)
    end
    return()
end
