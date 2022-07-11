# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IValueInterpretor:
    func addDerivative(_derivative: felt, _priceFeed: felt):
    end

    func calculAssetValue(_baseAsset: felt, _amount: Uint256, _denominationAsset:felt) -> (res:Uint256):
    end

    func checkIsSupportedDerivativeAsset(_derivative: felt) -> (res:felt):
    end

    func getDerivativePriceFeed(_derivative: felt) -> (res:felt):
    end
end
