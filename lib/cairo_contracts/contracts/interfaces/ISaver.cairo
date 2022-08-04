# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace ISaver:
    func setNewMint(_vault: felt, _caller:felt, _contract: felt, _tokenId:Uint256):
    end

    func setNewBurn(_vault: felt, _caller:felt, _contract: felt, _tokenId:Uint256):
    end
end
