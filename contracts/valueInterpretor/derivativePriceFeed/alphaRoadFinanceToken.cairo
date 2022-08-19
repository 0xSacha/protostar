 
 
 
 # Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.interfaces.IARFPool import IARFPool
from contracts.interfaces.IARFSwapController import IARFSwapController
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc
from contracts.interfaces.IVaultFactory import IVaultFactory

from starkware.starknet.common.syscalls import (
    get_tx_info,
    get_block_number,
    get_block_timestamp,
    get_contract_address,
    get_caller_address,
)

@storage_var
func poolAddress(derivative:felt) -> (res: felt):
end

@storage_var
func IARFSwapControllerContract() -> (res: felt):
end

@storage_var
func vaultFactory() -> (res: felt):
end



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
    let (poolAddress_:felt) = poolAddress.read(_derivative)
    with_attr error_message("calcUnderlyingValues: pool not registred for this token"):
        assert_not_zero(poolAddress_)
    end
    let (swapController_:felt) = IARFSwapControllerContract.read()
    with_attr error_message("calcUnderlyingValues: IARFSwapController not address not found"):
        assert_not_zero(swapController_)
    end
    let(token0_:felt) = IARFPool.getToken0(poolAddress_)
    let(token1_:felt) = IARFPool.getToken1(poolAddress_)
    let(token0Reserve_:Uint256, token1Reserve_:Uint256) = IARFPool.getReserves(poolAddress_)
    let (underlyingsAssets_ : felt*) = alloc()
    let (underlyingsAmount_ : Uint256*) = alloc()
    if token0_ == _derivative:
        assert [underlyingsAssets_] = token1_
        let (amount_:Uint256) = IARFSwapController.quote(swapController_, _amount, token0Reserve_, token1Reserve_)
        assert [underlyingsAmount_] = amount_
    else:
        assert [underlyingsAssets_] = token0_
        let (amount_:Uint256) = IARFSwapController.quote(swapController_, _amount, token1Reserve_, token0Reserve_)
        assert [underlyingsAmount_] = amount_
    end
    return (underlyingsAssets_len=1, underlyingsAssets=underlyingsAssets_, underlyingsAmount_len=1, underlyingsAmount=underlyingsAmount_)
end

 
@view
func getPoolAddress{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _derivative: felt,
    ) -> (res:felt):
    let (res:felt) = poolAddress.read(_derivative)
    return(res=res)
end

@view
func getIARFSwapController{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }() -> (res:felt):
    let(res_:felt) = IARFSwapControllerContract.read()
    return(res=res_)
end



func onlyOwner{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}():
    let (vaultFactory_) = vaultFactory.read()
    let (caller_) = get_caller_address()
    let (owner_) = IVaultFactory.getOwner(vaultFactory_)
    with_attr error_message("onlyVaultFactory: only callable by the owner"):
        assert owner_ = caller_
    end
    return ()
end


@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        _vaultFactory: felt,
    ):
    vaultFactory.write(_vaultFactory)
    return ()
end


#
#External
#
@external
func addPoolAddress{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _derivative: felt,
        _pool: felt,
    ):
    onlyOwner()
    poolAddress.write(_derivative, _pool)
    return()
end

@external
func setIARFSwapController{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _IARFSwapController: felt,
    ):
    IARFSwapControllerContract.write(_IARFSwapController)
    return()
end
 
