%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin


@contract_interface
namespace IStackingDispute:

    func getSecurityFundBalance(stackingDispute_: felt)-> (res: Uint256):
    end

end

