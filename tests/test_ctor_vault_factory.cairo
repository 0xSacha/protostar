%lang starknet

from starkware.starknet.common.syscalls import get_contract_address

from starkware.cairo.common.cairo_builtins import HashBuiltin

from contracts.interfaces.IVaultFactory import IVaultFactory
from contracts.interfaces.IEmpiricOracle import IEmpiricOracle
from contracts.interfaces.IOraclePriceFeedMixin import IOraclePriceFeedMixin

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



@view
func __setup__{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    tempvar vf_contract
    tempvar pm_contract
    tempvar im_contract
    tempvar fm_contract
    tempvar eth_contract
    tempvar btc_contract
    tempvar dai_contract
    tempvar vi_contract
    tempvar or_contract
    tempvar pp_contract
    tempvar la_contract
    tempvar sp_contract

    ##Vault Factory
    %{ 
    context.VF = deploy_contract("./contracts/VaultFactory.cairo",[ids.ADMIN]).contract_address 
    ids.vf_contract = context.VF
    %}    
    #Extensions
    %{ 
    context.PM = deploy_contract("./contracts/PolicyManager.cairo",[context.VF]).contract_address 
    ids.pm_contract = context.PM
    context.IM = deploy_contract("./contracts/IntegrationManager.cairo",[context.VF]).contract_address 
    ids.im_contract = context.IM
    context.FM = deploy_contract("./contracts/FeeManager.cairo",[context.VF]).contract_address 
    ids.fm_contract = context.FM
    %}

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.vf_contract] ] %}

    
     IVaultFactory.setFeeManager(vf_contract, fm_contract)
     IVaultFactory.setPolicyManager(vf_contract, pm_contract)
     IVaultFactory.setIntegrationManager(vf_contract, im_contract)

    %{ [stop_prank() for stop_prank in stop_pranks] %}


    #Coins
    %{ 
    context.ETH = deploy_contract("./contracts/mock/ERC20.cairo",[400,401, 18, 1000000000000000000, 0, ids.ADMIN, ids.ADMIN]).contract_address 
    ids.eth_contract = context.ETH 
    context.BTC = deploy_contract("./contracts/mock/ERC20.cairo",[400,401, 18, 1000000000000000000, 0, ids.ADMIN, ids.ADMIN]).contract_address 
    ids.btc_contract = context.BTC
    context.DAI = deploy_contract("./contracts/mock/ERC20.cairo",[400,401, 6, 1000000, 0, ids.ADMIN, ids.ADMIN]).contract_address
    ids.dai_contract = context.DAI
     %}


    #Value Interpreter
    %{ 
    context.VI = deploy_contract("./contracts/valueInterpretor/ValueInterpreter.cairo",[context.VF, context.ETH]).contract_address 
    ids.vi_contract = context.VI
    context.OR = deploy_contract("./contracts/mock/EmpiricOracle.cairo",[]).contract_address 
    ids.or_contract = context.OR
    context.PP = deploy_contract("./contracts/valueInterpretor/OraclePriceFeedMixin.cairo",[context.VF]).contract_address 
    ids.pp_contract = context.PP
    %}

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.vf_contract, ids.or_contract, ids.pp_contract] ] %}
    
     IVaultFactory.setValueInterpretor(vf_contract, vi_contract)
     IVaultFactory.setOracle(vf_contract, or_contract)
     IEmpiricOracle.set_value(or_contract,ETHkey, 2000000000000000000000, 18)
     IEmpiricOracle.set_value(or_contract,BTCkey, 25000000000000000000000, 18)
     IEmpiricOracle.set_value(or_contract,DAIkey, 1000000, 6)

     IVaultFactory.setPrimitivePriceFeed(vf_contract, pp_contract)
     IOraclePriceFeedMixin.addPrimitive(pp_contract, eth_contract, ETHkey)
     IOraclePriceFeedMixin.addPrimitive(pp_contract, btc_contract, BTCkey)
     IOraclePriceFeedMixin.addPrimitive(pp_contract, dai_contract, DAIkey)
    
    %{ [stop_prank() for stop_prank in stop_pranks] %}



    #Initial PreLogic

    %{ 
    context.LA = deploy_contract("./contracts/PreLogic/Approve.cairo",[context.VF]).contract_address 
    ids.la_contract = context.LA
    context.SP = deploy_contract("contracts/valueInterpretor/ExternalPositionPriceFeed/MgtyShare.cairo",[]).contract_address 
    ids.or_contract = context.OR
    %}
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.vf_contract] ] %}

    %{ [stop_prank() for stop_prank in stop_pranks] %}

    return ()
end

    # %{ context.FU = deploy_contract("./contracts/Fuccount_mock.cairo",[8338,context.VF]).contract_address %}

@external
func test_something():
    tempvar contract_address
    %{ ids.contract_address = context.VF_address %}

    return ()
end

@external
func test_ctor_basic{syscall_ptr : felt*,pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    tempvar contract_address
    %{ ids.contract_address = context.VF_address %}
    let (res) = IVaultFactory.getOwner(contract_address)
    assert res = 111
    return ()
end


@external
func test_ctor_basic_fail{syscall_ptr : felt*,pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    local contract_address : felt
    # We deploy contract and put its address into a local variable. Second argument is calldata array
    %{ ids.contract_address = deploy_contract("./contracts/VaultFactory.cairo",[1]).contract_address %}
    let (res) = IVaultFactory.getOwner(contract_address)
    %{ expect_revert() %}
    assert_eq(res,111)
    return ()
end

@external
func test_ctor_basic_using_revert{syscall_ptr : felt*,pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    local contract_address : felt
    # We deploy contract and put its address into a local variable. Second argument is calldata array
    %{ ids.contract_address = deploy_contract("./contracts/VaultFactory.cairo",[0]).contract_address %}
    let (res) = IVaultFactory.getOwner(contract_address)
    %{ expect_revert() %}
    assert_not_eq(res,0)
    return ()
end


namespace token_instance:
    func deployed() -> (token_contract : felt):
        tempvar token_contract
        %{ ids.token_contract = context.token_contract %}
        return (token_contract)
    end
end

