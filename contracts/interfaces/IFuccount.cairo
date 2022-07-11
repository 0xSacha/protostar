%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IFuccount:

    # set comptroller only callable by fund deployer 
    func activater(_fundName : felt, _fundSymbol : felt, _assetManager : felt, _denominationAsset : felt):
    end   

    func mintFromVF(_assetManager : felt, share_amount : Uint256, share_price : Uint256):
    end   

    # Vault getters

    func getManagerAccount() -> (res : felt):
    end

    func getDenominationAsset() -> (res : felt):
    end


    # NFT getters

    func getName() -> (name : felt):
    end

    func getSymbol() -> (symbol : felt):
    end

    func getTotalSupply() -> (totalSupply : Uint256):
    end

    func getSharesTotalSupply() -> (sharesTotalSupply : Uint256):
    end

    func getSharesBalance(token_id : Uint256) -> (sharesBalance : Uint256):
    end

    func getBalanceOf(owner : felt) -> (balance : Uint256):
    end

    func getOwnerOf(tokenId : Uint256) -> (owner : felt):
    end

    func getSharePricePurchased(tokenId : Uint256) -> (sharePricePurchased : Uint256):
    end

    func getMintedTimesTamp(tokenId : Uint256) -> (mintedBlock : felt):
    end
end
