
%lang starknet

from starkware.starknet.common.syscalls import get_contract_address
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
from contracts.interfaces.IFeeManager import IFeeManager, FeeConfig



from starkware.cairo.common.uint256 import Uint256


from protostar.asserts import (
    assert_eq, assert_not_eq, assert_signed_lt, assert_signed_le, assert_signed_gt,
    assert_unsigned_lt, assert_unsigned_le, assert_unsigned_gt, assert_signed_ge,
    assert_unsigned_ge)



#USER
const ADMIN = 'magnety-admin'
const USER_1 = 'user-1'

#FEE RECIPIENT
const STACKINGVAULT = 'stackingvault'
const DAOTREASURY = 'treasury'

##PRICEFEED
const BTCkey = 27712517064455012
const DAIkey = 28254602066752356
const ETHkey = 28556963469423460
const APPROVE_SELECTOR = 949021990203918389843157787496164629863144228991510976554585288817234167820
const DEPOSIT_SELECTOR = 352040181584456735608515580760888541466059565068553383579463728554843487745
const REEDEM_SELECTOR = 481719463807444873104482035153189208627524278231225222947146558976722465517

const DAY = 86400 


struct integration:
    member contract : felt
    member selector : felt
end

struct AssetInfo:
    member address : felt
    member amount : Uint256
    member valueInDeno : Uint256
end

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
    tempvar f1_contract
    tempvar f2_contract
    tempvar f3_contract
    tempvar sd_contract

    ##Vault Factory
    %{ 
    context.VF = deploy_contract("./contracts/VaultFactory.cairo",[ids.ADMIN]).contract_address 
    ids.vf_contract = context.VF
    %}    
    #Extensions
    %{ 
    context.PM = deploy_contract("./contracts/extensions/PolicyManager.cairo",[context.VF]).contract_address 
    ids.pm_contract = context.PM
    context.IM = deploy_contract("./contracts/extensions/IntegrationManager.cairo",[context.VF]).contract_address 
    ids.im_contract = context.IM
    context.FM = deploy_contract("./contracts/extensions/FeeManager.cairo",[context.VF]).contract_address 
    ids.fm_contract = context.FM
    %}

    #stackingDispute
    %{ 
    context.SD = deploy_contract("./contracts/StackingDipsute.cairo",[context.VF]).contract_address 
    ids.sd_contract = context.SD
    %}

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.vf_contract] ] %}

    
     IVaultFactory.setFeeManager(vf_contract, fm_contract)
     IVaultFactory.setPolicyManager(vf_contract, pm_contract)
     IVaultFactory.setIntegrationManager(vf_contract, im_contract)
     IVaultFactory.setMaxFundLevel(vf_contract, 2)
     IVaultFactory.setStackingDispute(vf_contract, sd_contract)
     IVaultFactory.setGuaranteeRatio(vf_contract, 5)
     IVaultFactory.setExitTimestamp(vf_contract, DAY)

    %{ [stop_prank() for stop_prank in stop_pranks] %}


    #Coins
    %{ 
    context.ETH = deploy_contract("./contracts/mock/ERC20.cairo",[400,401, 18, 10000000000000000000, 0, ids.ADMIN, ids.ADMIN]).contract_address 
    ids.eth_contract = context.ETH 
    context.BTC = deploy_contract("./contracts/mock/ERC20.cairo",[400,401, 18, 10000000000000000000, 0, ids.ADMIN, ids.ADMIN]).contract_address 
    ids.btc_contract = context.BTC
    context.DAI = deploy_contract("./contracts/mock/ERC20.cairo",[400,401, 6, 100000000, 0, ids.ADMIN, ids.ADMIN]).contract_address
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
    context.SP = deploy_contract("contracts/valueInterpretor/derivativePriceFeed/MgtyShare.cairo",[]).contract_address 
    ids.sp_contract = context.SP
    %}

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.vf_contract] ] %}
    IVaultFactory.setSharePriceFeed(vf_contract, sp_contract)
    IVaultFactory.setApprovePreLogic(vf_contract, la_contract)
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    #Initial PreLogic
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.vf_contract] ] %}
    IVaultFactory.setStackingVault(vf_contract, STACKINGVAULT)
    IVaultFactory.setDaoTreasury(vf_contract, DAOTREASURY)
    IVaultFactory.setStackingVaultFee(vf_contract, 16)
    IVaultFactory.setDaoTreasuryFee(vf_contract, 4)
    %{ [stop_prank() for stop_prank in stop_pranks] %}


    ## deploy 3 Funds
    %{ 
    context.F1 = deploy_contract("./contracts/Fuccount.cairo",[123,context.VF]).contract_address 
    context.F2 = deploy_contract("./contracts/Fuccount.cairo",[231,context.VF]).contract_address 
    context.F3 = deploy_contract("./contracts/Fuccount.cairo",[312,context.VF]).contract_address 
    ids.f1_contract = context.F1
    ids.f2_contract = context.F2
    ids.f3_contract = context.F3
    %}

    #Add asset and deploy 3 Funds
    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.vf_contract] ] %}
    let (local assets : felt*) = alloc()
    assert [assets] = eth_contract
    assert [assets + 1] = btc_contract
    assert [assets + 2] = dai_contract
     IVaultFactory.addGlobalAllowedAsset(vf_contract,3, assets)
    %{ [stop_prank() for stop_prank in stop_pranks] %}
    return ()
end



@external
func test_initialize_fuccount{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
alloc_locals
    let (f1_contract) = fund_instance.deployed()
    let (vf_contract) = vf_instance.deployed()
    let (eth_contract) = eth_instance.deployed()
    let (dai_contract) = dai_instance.deployed()
    let (fm_contract) = fm_instance.deployed()
    let (im_contract) = im_instance.deployed()

    %{ stop_prank = start_prank(ids.ADMIN, ids.eth_contract) %}
     IERC20.approve(eth_contract, vf_contract, Uint256(10000000000000000000,0))
    %{ stop_prank() %}
    
    let (local data : felt*) = alloc()
    let (local feeConfig : felt*) = alloc()
    assert [feeConfig] = 10
    assert [feeConfig + 1] = 10
    assert [feeConfig + 2] = 10
    assert [feeConfig + 3] = 10
    %{ stop_prank = start_prank(ids.ADMIN, ids.vf_contract) %}
    let (name_) = IFuccountMock.getName(f1_contract)
    IVaultFactory.initializeFund(
    vf_contract, f1_contract, 1, 420, 42, 24, eth_contract, Uint256(1000000000000000000,0), Uint256(10000000000000000000,0), 0, data, 4, feeConfig, Uint256(100000000000000000000,0), Uint256(10000000000000000,0), 100, 1)
    %{ stop_prank()  %}

    let (entranceFee) = IFeeManager.getFeeConfig(fm_contract, f1_contract,FeeConfig.ENTRANCE_FEE)
    let (exitFee) = IFeeManager.getFeeConfig(fm_contract, f1_contract,FeeConfig.EXIT_FEE)
    let (managementFee) = IFeeManager.getFeeConfig(fm_contract, f1_contract,FeeConfig.MANAGEMENT_FEE)
    let (performanceFee) = IFeeManager.getFeeConfig(fm_contract, f1_contract,FeeConfig.PERFORMANCE_FEE)
    assert entranceFee = 10
    assert exitFee = 10
    assert managementFee = 10
    assert performanceFee = 10


    let (availableIntegrations_len:felt, availableIntegrations: integration*) = IIntegrationManager.getAvailableIntegrations(im_contract)
    assert availableIntegrations_len = 5
    let integr_:integration = availableIntegrations[3]

    assert integr_.contract = f1_contract
    assert integr_.selector = DEPOSIT_SELECTOR

    let integr_:integration = availableIntegrations[4]
    assert integr_.contract = f1_contract
    assert integr_.selector = REEDEM_SELECTOR

    # %{ stop_prank = start_prank(ids.ADMIN, ids.f1_contract_bis) %}
    # %{ stop_prank()  %}

    let (assetId_len:felt, assetId:Uint256*, assetAmount_len:felt,assetAmount:Uint256*) = IFuccountMock.ownerShares(f1_contract,ADMIN)
    assert assetId_len = 1
    let id = assetId[0]
    let amount = assetAmount[0]
    %{
        print('owner shares')
        print(ids.id.low)
        print(ids.amount.low)
    %}

    let (mintedBlockTimesTamp_:felt) =  IFuccountMock.getMintedTimesTamp(f1_contract, id )
    let (sharePricePurchased_:Uint256) = IFuccountMock.getSharePricePurchased(f1_contract, id)
    let (totalId_:Uint256) = IFuccountMock.totalId(f1_contract)
    let (sharesTotalSupply:Uint256) = IFuccountMock.sharesTotalSupply(f1_contract)
    
    # assert mintedBlockTimesTamp_ = 0
    # assert sharePricePurchased_.low = 100000000000000000
    # assert totalId_.low = 1
    # assert sharesTotalSupply.low = 10000000000000000000

    # %{
    #     print('shares info')
    #     print(ids.mintedBlockTimesTamp_) 
    #     print(ids.sharePricePurchased_.low)
    #     print(ids.totalId_.low)
    #     print(ids.sharesTotalSupply.low)
    # %}

    # let (notNulAssets_len:felt, notNulAssets: AssetInfo*) = IFuccountMock.getNotNulAssets(f1_contract_bis)
    # let (notNulPositions_len:felt, notNulPositions: felt*) = IFuccountMock.getNotNulPositions(f1_contract_bis)
    # let (sharePrice_) = IFuccountMock.getSharePrice(f1_contract_bis)
    # let (liquidGav) = IFuccountMock.calculLiquidGav(f1_contract_bis)
    # let (notLiquidGav) = IFuccountMock.calculNotLiquidGav(f1_contract_bis)
    # let (gav) = IFuccountMock.calculGav(f1_contract_bis)
    # assert notNulAssets_len = 1
    # assert notNulPositions_len = 0
    # let notNulAssets1 =  notNulAssets[0]
    # # let notNulPosition__ = notNulPositions[0]
    # assert notNulPositions_len = 0
    #     %{
    #     print('fund info')
    #     print(ids.notNulAssets1.address)
    #     print(ids.notNulAssets1.amount.low)
    #     print(ids.notNulAssets1.valueInDeno.low)
    #     print(ids.sharePrice_.low)
    #     print(ids.liquidGav.low)
    #     print(ids.gav.low)
    #     print(ids.notLiquidGav.low)
    # %}
    # let (assetId_len:felt, assetId:Uint256*, assetAmount_len:felt,assetAmount:Uint256*) = IFuccountMock.ownerShares(f1_contract,ADMIN)

    

    let (local data2 : felt*) = alloc()
    %{ stop_prank = start_prank(ids.ADMIN, ids.eth_contract) %}
     IERC20.approve(eth_contract, f1_contract, Uint256(10000000000000000000,0))
    %{ stop_prank() %}

    %{ stop_prank = start_prank(ids.ADMIN, ids.f1_contract) %}
    IFuccountMock.deposit(f1_contract, Uint256(1000000000000000000,0),0, data2)
    %{ stop_prank()  %}

    let (notNulAssets_len:felt, notNulAssets: AssetInfo*) = IFuccountMock.getNotNulAssets(f1_contract)
    let (notNulPositions_len:felt, notNulPositions: felt*) = IFuccountMock.getNotNulPositions(f1_contract)
    let firstAsset = notNulAssets[0]
    %{
        print(ids.notNulAssets_len)
        print(ids.firstAsset.address)
        print(ids.firstAsset.valueInDeno.low)
        print(ids.firstAsset.amount.low)

    %}

    let (sharePrice_) = IFuccountMock.getSharePrice(f1_contract)

    let (liquidGav) = IFuccountMock.calculLiquidGav(f1_contract)

    let (notLiquidGav) = IFuccountMock.calculNotLiquidGav(f1_contract)

    let (gav) = IFuccountMock.calculGav(f1_contract)

        %{
        print('fund info')
        print(ids.sharePrice_.low)
        print(ids.liquidGav.low)
        print(ids.gav.low)
        print(ids.notLiquidGav.low)
    %}


    %{ stop_prank = start_prank(ids.ADMIN, ids.dai_contract) %}
    IERC20.transfer(dai_contract, f1_contract, Uint256(10000000,0))
    %{ stop_prank()  %}
    let (notNulAssets_len:felt, notNulAssets: AssetInfo*) = IFuccountMock.getNotNulAssets(f1_contract)

    let secondAsset = notNulAssets[0]
    %{
        print(ids.notNulAssets_len)
        print(ids.secondAsset.address)
        print(ids.secondAsset.valueInDeno.low)
        print(ids.secondAsset.amount.low)

    %}
   
    let (sharePrice2_) = IFuccountMock.getSharePrice(f1_contract)

    let (liquidGav2) = IFuccountMock.calculLiquidGav(f1_contract)

    let (notLiquidGav2) = IFuccountMock.calculNotLiquidGav(f1_contract)

    let (gav2) = IFuccountMock.calculGav(f1_contract)

        %{
        print('fund info')
        print(ids.sharePrice2_.low)
        print(ids.liquidGav2.low)
        print(ids.gav2.low)
        print(ids.notLiquidGav2.low)
    %}



    # let (totalId_:Uint256) = IFuccountMock.totalId(f1_contract)
    # %{
    #     print(ids.totalId_.low)
    # %}

    # let (assetId_len:felt, assetId:Uint256*, assetAmount_len:felt,assetAmount:Uint256*) = IFuccountMock.ownerShares(f1_contract,ADMIN)

    # assert assetId_len = 2
    # let id1 = assetId[0]
    # let amount1 = assetAmount[0]
    # let id2 = assetId[1]
    # let amount2 = assetAmount[1]

    # assert id1.low = 1
    # assert amount1.low = 9000000000000000000
    # assert id2.low = 0
    # assert amount2.low = 10000000000000000000

    # let (assetManagerBalance_: Uint256) = IERC20.balanceOf(eth_contract, ADMIN)
    # let (stackingVaultBalance_: Uint256) = IERC20.balanceOf(eth_contract, STACKINGVAULT)
    # let (daoTreasuryBalance_: Uint256) = IERC20.balanceOf(eth_contract, DAOTREASURY)
    # assert assetManagerBalance_.low = 8080000000000000000
    # assert stackingVaultBalance_.low = 16000000000000000
    # assert daoTreasuryBalance_.low = 4000000000000000

    # let (mintedBlockTimesTamp_:felt) =  IFuccountMock.getMintedTimesTamp(f1_contract, id2 )
    # let (sharePricePurchased_:Uint256) = IFuccountMock.getSharePricePurchased(f1_contract, id2)
    # let (totalId_:Uint256) = IFuccountMock.totalId(f1_contract)
    # let (sharesTotalSupply:Uint256) = IFuccountMock.sharesTotalSupply(f1_contract)
    
    # assert mintedBlockTimesTamp_ = 0
    # assert sharePricePurchased_.low = 100000000000000000
    # assert totalId_.low = 2
    # assert sharesTotalSupply.low = 19000000000000000000





    return ()
end

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

# @external
# func test_ctor_basic{syscall_ptr : felt*,pedersen_ptr : HashBuiltin*, range_check_ptr}():
#     alloc_locals
#     tempvar contract_address
#     %{ ids.contract_address = context.VF_address %}
#     let (res) = IVaultFactory.getOwner(contract_address)
#     assert res = 111
#     return ()
# end


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


namespace fund_instance:
    func deployed() -> (fund_contract : felt):
        tempvar fund_contract
        %{ ids.fund_contract = context.F1 %}
        return (fund_contract)
    end
end

namespace vf_instance:
    func deployed() -> (vf_contract : felt):
        tempvar vf_contract
        %{ ids.vf_contract = context.VF %}
        return (vf_contract)
    end
end

namespace eth_instance:
    func deployed() -> (eth_contract : felt):
        tempvar eth_contract
        %{ ids.eth_contract = context.ETH %}
        return (eth_contract)
    end
end

namespace dai_instance:
    func deployed() -> (dai_contract : felt):
        tempvar dai_contract
        %{ ids.dai_contract = context.DAI %}
        return (dai_contract)
    end
end

namespace fm_instance:
    func deployed() -> (fm_contract : felt):
        tempvar fm_contract
        %{ ids.fm_contract = context.FM %}
        return (fm_contract)
    end
end

namespace im_instance:
    func deployed() -> (im_instance : felt):
        tempvar im_instance
        %{ ids.im_instance = context.IM %}
        return (im_instance)
    end
end

