# Declare this file as a StarkNet contract.
%lang starknet
from starkware.starknet.common.syscalls import (
    get_tx_info,
    get_block_number,
    get_block_timestamp,
    get_contract_address,
    get_caller_address,
)
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.uint256 import (
    uint256_sub,
    uint256_check,
    uint256_le,
    uint256_eq,
    uint256_add,
    uint256_mul,
    uint256_unsigned_div_rem,
)
from contracts.utils.utils import felt_to_uint256, uint256_div, uint256_percent, uint256_mul_low, uint256_pow
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.PreLogic.interfaces.IOraclePriceFeedMixin import IOraclePriceFeedMixin
from contracts.interfaces.IVaultFactory import IVaultFactory
from contracts.interfaces.IDerivativePriceFeed import IDerivativePriceFeed
from contracts.interfaces.IExternalPositionPriceFeed import IExternalPositionPriceFeed
from contracts.interfaces.IERC20 import IERC20

from starkware.cairo.common.math import assert_not_zero


@storage_var
func vault_factory() -> (vault_factoryAddress : felt):
end

@storage_var
func eth_address() -> (eth_address : felt):
end


@storage_var
func derivative_to_price_feed(derivative:felt) -> (res: felt):
end

@storage_var
func is_supported_derivative_asset(derivative:felt) -> (res: felt):
end


@storage_var
func external_position_to_price_feed(externalPosition:felt) -> (res: felt):
end

@storage_var
func is_supported_external_position(externalPosition:felt) -> (res: felt):
end


@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        _vault_factory: felt,
        _eth_address:felt,
    ):
    vault_factory.write(_vault_factory)
    eth_address.write(_eth_address)
    return ()
end

func only_authorized{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}():
    let (vault_factory_) = vault_factory.read()
    let (caller_) = get_caller_address()
    let (owner_) = IVaultFactory.getOwner(vault_factory_)
    with_attr error_message("onlyAuthorized: only callable by the owner or VF"):
        assert (owner_ - caller_) * (vault_factory_ - caller_) = 0
    end
    return ()
end


#getters

@view
func calcul_asset_value{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _baseAsset: felt,
        _amount: Uint256,
        _denominationAsset:felt,
    ) -> (res:Uint256):
    alloc_locals
    if _amount.low == 0:
        return(Uint256(0,0))
    end

    let (vault_factory_:felt) = vault_factory.read()
    let (primitivePriceFeed_:felt) = IVaultFactory.getPrimitivePriceFeed(vault_factory_)
    let (is_supported_primitive_denomination_asset_:felt) = IOraclePriceFeedMixin.checkIsSupportedPrimitiveAsset(primitivePriceFeed_, _denominationAsset)
    if is_supported_primitive_denomination_asset_ == 1:
        let (res:Uint256) = __calcul_asset_value(_baseAsset, _amount, _denominationAsset)
        return(res=res)
    else:
        let (eth_address_:felt) = eth_address.read()
        let (decimalsDenominationAsset_:felt) = IERC20.decimals(_denominationAsset)
        let (decimalsDenominationAssetPow_:Uint256) = uint256_pow(Uint256(10,0),decimalsDenominationAsset_)
        let (baseAsssetValueInEth_:Uint256) = __calcul_asset_value(_baseAsset, _amount, eth_address_)
        let (oneUnityDenominationAsssetValueInEth_:Uint256) = __calcul_asset_value(_denominationAsset, decimalsDenominationAssetPow_, eth_address_)
        let (step_1:Uint256) = uint256_mul_low(baseAsssetValueInEth_, decimalsDenominationAssetPow_)
        let (res:Uint256) = uint256_div(step_1, oneUnityDenominationAsssetValueInEth_)
        return(res)
    end
end

@view
func get_derivative_price_feed{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _derivative: felt,
    ) -> (res:felt):
    let (res:felt) = derivative_to_price_feed.read(_derivative)
    return(res=res)
end

@view
func check_is_supported_derivative_asset{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _derivative: felt,
    ) -> (res:felt):
    let (res:felt) = is_supported_derivative_asset.read(_derivative)
    return(res=res)
end

@view
func get_external_position_price_feed{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _externalPosition: felt,
    ) -> (res:felt):
    let (res:felt) = external_position_to_price_feed.read(_externalPosition)
    return(res=res)
end

@view
func check_is_supported_external_position{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _externalPosition: felt,
    ) -> (res:felt):
    let (res:felt) = is_supported_external_position.read(_externalPosition)
    return(res=res)
end

#
#External
#

@external
func add_derivative{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _derivative: felt,
        _priceFeed: felt,
    ):
    only_authorized()
    is_supported_derivative_asset.write(_derivative, 1)
    derivative_to_price_feed.write(_derivative, _priceFeed)
    return()
end

@external
func add_external_position{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _externalPosition: felt,
        _priceFeed: felt,
    ):
    only_authorized()
    is_supported_external_position.write(_externalPosition, 1)
    external_position_to_price_feed.write(_externalPosition, _priceFeed)
    return()
end


#
# Internal
#


func __calcul_asset_value{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _baseAsset: felt,
        _amount: Uint256,
        _denominationAsset:felt,
    ) -> (res:Uint256):
    if  _baseAsset == _denominationAsset:
        return (res=_amount)
    end
    let (vault_factory_:felt) = vault_factory.read()
    let (primitivePriceFeed_:felt) = IVaultFactory.getPrimitivePriceFeed(vault_factory_)
    let (isSupportedPrimitiveAsset_) = IOraclePriceFeedMixin.checkIsSupportedPrimitiveAsset(primitivePriceFeed_, _baseAsset)

    if isSupportedPrimitiveAsset_ == 1:
        let (res:Uint256) = IOraclePriceFeedMixin.calcAssetValueBmToDeno(primitivePriceFeed_, _baseAsset, _amount, _denominationAsset)
        return(res=res)
    else:
        let (isSupportedDerivativeAsset_) = is_supported_derivative_asset.read(_baseAsset)
        if isSupportedDerivativeAsset_ == 1:
        let (derivativePriceFeed_:felt) = get_derivative_price_feed(_baseAsset)
        let (res:Uint256) = __calc_derivative_value(derivativePriceFeed_, _baseAsset, _amount, _denominationAsset)
        return(res=res)
        else:
        let (externalPositionPriceFeed_:felt) = get_external_position_price_feed(_baseAsset)
        let (res:Uint256) = __calc_external_position_value(externalPositionPriceFeed_, _baseAsset, _amount, _denominationAsset)
        return(res=res)
        end
    end
end

func __calc_derivative_value{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _derivativePriceFeed: felt,
        _derivative: felt,
        _amount: Uint256,
        _denominationAsset:felt,
    ) -> (res:Uint256):
    let ( underlyingsAssets_len:felt, underlyingsAssets:felt*, underlyingsAmount_len:felt, underlyingsAmount:Uint256* ) = IDerivativePriceFeed.calc_underlying_values(_derivativePriceFeed, _derivative, _amount)
    with_attr error_message("__calc_derivative_value: No underlyings"):
        assert_not_zero(underlyingsAssets_len)
    end

    with_attr error_message("__calc_derivative_value: Arrays unequal lengths"):
        assert underlyingsAssets_len = underlyingsAmount_len
    end

    let (res_:Uint256) = __calc_underlying_values(underlyingsAssets_len, underlyingsAssets, underlyingsAmount_len, underlyingsAmount, _denominationAsset)
    return(res=res_)
end


func __calc_external_position_value{
        pedersen_ptr: HashBuiltin*, 
        syscall_ptr: felt*, 
        range_check_ptr
    }(
        _externalPositionPriceFeed: felt,
        _externalPosition: felt,
        _amount: Uint256,
        _denominationAsset:felt,
    ) -> (res:Uint256):
    let ( underlyingsAssets_len:felt, underlyingsAssets:felt*, underlyingsAmount_len:felt, underlyingsAmount:Uint256* ) = IExternalPositionPriceFeed.calc_underlying_values(_externalPositionPriceFeed, _externalPosition, _amount)
    with_attr error_message("__calc_external_position_value: No underlyings"):
        assert_not_zero(underlyingsAssets_len)
    end

    with_attr error_message("__calc_external_position_value: Arrays unequal lengths"):
        assert underlyingsAssets_len = underlyingsAmount_len
    end

    let (res_:Uint256) = __calc_underlying_values(underlyingsAssets_len, underlyingsAssets, underlyingsAmount_len, underlyingsAmount, _denominationAsset)
    return(res=res_)
end


func __calc_underlying_values{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_underlyingsAssets_len:felt, _underlyingsAssets:felt*, _underlyingsAmount_len:felt, _underlyingsAmount:Uint256*, _denominationAsset:felt) -> (res:Uint256):
    alloc_locals
    if _underlyingsAssets_len == 0:
        return (Uint256(0,0))
    end

    let baseAsset_:felt = [_underlyingsAssets]
    let amount_:Uint256 = [_underlyingsAmount]        

    let (underlyingValue_:Uint256) = calcul_asset_value(baseAsset_, amount_, _denominationAsset)

    let newUnderlyingsAssets_len_:felt = _underlyingsAssets_len -1
    let newUnderlyingsAssets_:felt* = _underlyingsAssets + 1
    let newUnderlyingsAmount_len_:felt = _underlyingsAmount_len -1
    let newUnderlyingsAmount_:Uint256* = _underlyingsAmount + 2
    let (nextValue_:Uint256) = __calc_underlying_values(newUnderlyingsAssets_len_, newUnderlyingsAssets_, newUnderlyingsAmount_len_, newUnderlyingsAmount_, _denominationAsset)
    let (res_:Uint256, _) = uint256_add(underlyingValue_, nextValue_)  
    return (res=res_)
end