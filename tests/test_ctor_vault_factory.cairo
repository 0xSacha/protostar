
%lang starknet

from starkware.starknet.common.syscalls import get_contract_address
from starkware.starknet.compiler.compile import get_selector_from_name
from starkware.cairo.common.alloc import (
    alloc,
)
from starkware.cairo.common.cairo_builtins import HashBuiltin

from contracts.interfaces.IVaultFactory import IVaultFactory, Integration
from contracts.interfaces.IEmpiricOracle import IEmpiricOracle
from contracts.interfaces.IOraclePriceFeedMixin import IOraclePriceFeedMixin
from contracts.interfaces.IFuccountMock import IFuccountMock
from contracts.interfaces.IERC20 import IERC20
from contracts.interfaces.IIntegrationManager import IIntegrationManager



from starkware.cairo.common.uint256 import Uint256


from protostar.asserts import (
    assert_eq, assert_not_eq, assert_signed_lt, assert_signed_le, assert_signed_gt,
    assert_unsigned_lt, assert_unsigned_le, assert_unsigned_gt, assert_signed_ge,
    assert_unsigned_ge)



#USER
const ADMIN = 'magnety-admin'
const USER_1 = 'user-1'
##PRICEFEED
const BTCkey = 27712517064455012
const DAIkey = 28254602066752356
const ETHkey = 28556963469423460
const APPROVE_SELECTOR = 949021990203918389843157787496164629863144228991510976554585288817234167820
const BUYSHARE_SELECTOR = 1739160585925371971880668508720131927045855609588612196644536989289532392537
const SELLSHARE_SELECTOR = 481719463807444873104482035153189208627524278231225222947146558976722465517

struct integration:
    member contract : felt
    member selector : felt
end

# @view
# func __setup__{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
#     alloc_locals
#     tempvar vf_contract
#     tempvar pm_contract
#     tempvar im_contract
#     tempvar fm_contract
#     tempvar eth_contract
#     tempvar btc_contract
#     tempvar dai_contract
#     tempvar vi_contract
#     tempvar or_contract
#     tempvar pp_contract
#     tempvar la_contract
#     tempvar sp_contract
#     tempvar f1_contract
#     tempvar f2_contract
#     tempvar f3_contract

#     ##Vault Factory
#     %{ 
#     context.VF = deploy_contract("./contracts/VaultFactory.cairo",[ids.ADMIN]).contract_address 
#     ids.vf_contract = context.VF
#     %}    
#     #Extensions
#     %{ 
#     context.PM = deploy_contract("./contracts/PolicyManager.cairo",[context.VF]).contract_address 
#     ids.pm_contract = context.PM
#     context.IM = deploy_contract("./contracts/IntegrationManager.cairo",[context.VF]).contract_address 
#     ids.im_contract = context.IM
#     context.FM = deploy_contract("./contracts/FeeManager.cairo",[context.VF]).contract_address 
#     ids.fm_contract = context.FM
#     %}

#     %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.vf_contract] ] %}

    
#      IVaultFactory.setFeeManager(vf_contract, fm_contract)
#      IVaultFactory.setPolicyManager(vf_contract, pm_contract)
#      IVaultFactory.setIntegrationManager(vf_contract, im_contract)

#     %{ [stop_prank() for stop_prank in stop_pranks] %}


#     #Coins
#     %{ 
#     context.ETH = deploy_contract("./contracts/mock/ERC20.cairo",[400,401, 18, 10000000000000000000, 0, ids.ADMIN, ids.ADMIN]).contract_address 
#     ids.eth_contract = context.ETH 
#     context.BTC = deploy_contract("./contracts/mock/ERC20.cairo",[400,401, 18, 10000000000000000000, 0, ids.ADMIN, ids.ADMIN]).contract_address 
#     ids.btc_contract = context.BTC
#     context.DAI = deploy_contract("./contracts/mock/ERC20.cairo",[400,401, 6, 100000000, 0, ids.ADMIN, ids.ADMIN]).contract_address
#     ids.dai_contract = context.DAI
#      %}


#     #Value Interpreter
#     %{ 
#     context.VI = deploy_contract("./contracts/valueInterpretor/ValueInterpreter.cairo",[context.VF, context.ETH]).contract_address 
#     ids.vi_contract = context.VI
#     context.OR = deploy_contract("./contracts/mock/EmpiricOracle.cairo",[]).contract_address 
#     ids.or_contract = context.OR
#     context.PP = deploy_contract("./contracts/valueInterpretor/OraclePriceFeedMixin.cairo",[context.VF]).contract_address 
#     ids.pp_contract = context.PP
#     %}

#     %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.vf_contract, ids.or_contract, ids.pp_contract] ] %}
    
#      IVaultFactory.setValueInterpretor(vf_contract, vi_contract)
#      IVaultFactory.setOracle(vf_contract, or_contract)
#      IEmpiricOracle.set_value(or_contract,ETHkey, 2000000000000000000000, 18)
#      IEmpiricOracle.set_value(or_contract,BTCkey, 25000000000000000000000, 18)
#      IEmpiricOracle.set_value(or_contract,DAIkey, 1000000, 6)

#      IVaultFactory.setPrimitivePriceFeed(vf_contract, pp_contract)
#      IOraclePriceFeedMixin.addPrimitive(pp_contract, eth_contract, ETHkey)
#      IOraclePriceFeedMixin.addPrimitive(pp_contract, btc_contract, BTCkey)
#      IOraclePriceFeedMixin.addPrimitive(pp_contract, dai_contract, DAIkey)
    
#     %{ [stop_prank() for stop_prank in stop_pranks] %}



#     #Initial PreLogic

#     %{ 
#     context.LA = deploy_contract("./contracts/PreLogic/Approve.cairo",[context.VF]).contract_address 
#     ids.la_contract = context.LA
#     context.SP = deploy_contract("contracts/valueInterpretor/ExternalPositionPriceFeed/MgtyShare.cairo",[]).contract_address 
#     ids.sp_contract = context.SP
#     %}

#     %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.vf_contract] ] %}
#     IVaultFactory.setSharePriceFeed(vf_contract, sp_contract)
#     IVaultFactory.setApprovePreLogic(vf_contract, la_contract)
#     %{ [stop_prank() for stop_prank in stop_pranks] %}

#     ## deploy 3 Funds
#     %{ 
#     context.F1 = deploy_contract("./contracts/mock/Fuccount.cairo",[123,context.VF]).contract_address 
#     context.F2 = deploy_contract("./contracts/mock/Fuccount.cairo",[231,context.VF]).contract_address 
#     context.F3 = deploy_contract("./contracts/mock/Fuccount.cairo",[312,context.VF]).contract_address 
#     ids.f1_contract = context.F1
#     ids.f2_contract = context.F2
#     ids.f3_contract = context.F3
#     %}

#     #Add asset and deploy 3 Funds
#     %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.vf_contract] ] %}
#     let (local assets : felt*) = alloc()
#     assert [assets] = eth_contract
#     assert [assets + 1] = btc_contract
#     assert [assets + 2] = dai_contract
#      IVaultFactory.addGlobalAllowedAsset(vf_contract,3, assets)
#     %{ [stop_prank() for stop_prank in stop_pranks] %}
#     return ()
# end



# @external
# func test_initialize_fuccount{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
# alloc_locals
#     tempvar vf_contract
#     tempvar f1_contract
#     tempvar eth_contract
#     %{ 
#     ids.vf_contract = context.VF
#     ids.f1_contract = context.F1
#     ids.eth_contract = context.ETH
#     %}

#     %{ stop_prank = start_prank(ids.ADMIN, ids.eth_contract) %}
#      IERC20.approve(eth_contract, vf_contract, Uint256(10000000000000000000,0))
#     %{ stop_prank() %}
    
#     let (local data : felt*) = alloc()
#     let (local feeConfig : felt*) = alloc()
#     assert [feeConfig] = 10
#     assert [feeConfig + 1] = 10
#     assert [feeConfig + 2] = 10
#     assert [feeConfig + 3] = 10
#     %{ stop_prank = start_prank(ids.ADMIN, ids.vf_contract) %}
#     IVaultFactory.initializeFund(
#     vf_contract, f1_contract, 420, 42, 24, eth_contract, Uint256(1000000000000000000,0), Uint256(10000000000000000000,0), 0, data, 4, feeConfig, Uint256(100000000000000000000,0), Uint256(10000000000000000,0), 100, 1)
#     %{ stop_prank()  %}
#     return ()
# end

# @external
# func test_global_allowance{syscall_ptr : felt*,pedersen_ptr : HashBuiltin*, range_check_ptr}():
#     alloc_locals
#     tempvar im_contract
#     tempvar eth_contract
#     tempvar btc_contract
#     tempvar dai_contract
#     %{ 
#     ids.im_contract = context.IM
#     ids.eth_contract = context.ETH
#     ids.dai_contract = context.DAI
#     ids.btc_contract = context.BTC
#     %}
#     let (availableAssets_len :felt,  availableAssets:felt*) = IIntegrationManager.getAvailableAssets(im_contract)
#     assert availableAssets[0] = eth_contract
#     assert availableAssets[1] = btc_contract
#     assert availableAssets[2] = dai_contract

#     let (availableIntegrations_len:felt, availableIntegrations: integration*) = IIntegrationManager.getAvailableIntegrations(im_contract)
#     let integr_:integration = availableIntegrations[0]
#         %{ 
#         print(ids.availableIntegrations_len)
#         print(ids.integr_.contract)
#     %}
#     assert availableIntegrations[0] = integration(eth_contract, APPROVE_SELECTOR)
#     assert availableIntegrations[1] = integration(btc_contract, APPROVE_SELECTOR)
#     assert availableIntegrations[2] = integration(dai_contract, APPROVE_SELECTOR)

#     return ()
# end

@external
func test_ctor_basic{syscall_ptr : felt*,pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    %{ 
    print(get_selector_from_name('deposit'))
    %}
    return ()
end


# @external
# func test_ctor_basic_fail{syscall_ptr : felt*,pedersen_ptr : HashBuiltin*, range_check_ptr}():
#     alloc_locals
#     local contract_address : felt
#     # We deploy contract and put its address into a local variable. Second argument is calldata array
#     %{ ids.contract_address = deploy_contract("./contracts/VaultFactory.cairo",[1]).contract_address %}
#     let (res) = IVaultFactory.getOwner(contract_address)
#     %{ expect_revert() %}
#     assert_eq(res,111)
#     return ()
# end

# @external
# func test_ctor_basic_using_revert{syscall_ptr : felt*,pedersen_ptr : HashBuiltin*, range_check_ptr}():
#     alloc_locals
#     local contract_address : felt
#     # We deploy contract and put its address into a local variable. Second argument is calldata array
#     %{ ids.contract_address = deploy_contract("./contracts/VaultFactory.cairo",[0]).contract_address %}
#     let (res) = IVaultFactory.getOwner(contract_address)
#     %{ expect_revert() %}
#     assert_not_eq(res,0)
#     return ()
# end


# namespace token_instance:
#     func deployed() -> (token_contract : felt):
#         tempvar token_contract
#         %{ ids.token_contract = context.token_contract %}
#         return (token_contract)
#     end
# end

