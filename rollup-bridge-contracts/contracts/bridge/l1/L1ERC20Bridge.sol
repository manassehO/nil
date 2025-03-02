// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { NilAccessControl } from "../../NilAccessControl.sol";
import { IL1ERC20Bridge } from "./interfaces/IL1ERC20Bridge.sol";
import { IL2ERC20Bridge } from "../l2/interfaces/IL2ERC20Bridge.sol";
import { IL1BridgeRouter } from "./interfaces/IL1BridgeRouter.sol";
import { IL1Bridge } from "./interfaces/IL1Bridge.sol";
import { IBridge } from "../interfaces/IBridge.sol";
import { IL1BridgeMessenger } from "./interfaces/IL1BridgeMessenger.sol";
import { INilGasPriceOracle } from "./interfaces/INilGasPriceOracle.sol";

/// @title L1ERC20Bridge
/// @notice The `L1ERC20Bridge` contract for ERC20Bridging in L1.
contract L1ERC20Bridge is
    OwnableUpgradeable,
    PausableUpgradeable,
    NilAccessControl,
    ReentrancyGuardUpgradeable,
    IL1ERC20Bridge
{
    using SafeTransferLib for ERC20;

    /*//////////////////////////////////////////////////////////////////////////
                             STATE-VARIABLES   
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IL1Bridge
    address public override router;

    /// @inheritdoc IL1Bridge
    address public override counterpartyBridge;

    /// @inheritdoc IL1Bridge
    address public override messenger;

    /// @inheritdoc IL1Bridge
    address public override nilGasPriceOracle;

    address public override wethToken;

    /// @notice Mapping from l1 token address to l2 token address for ERC20 token.
    mapping(address => address) public tokenMapping;

    /// @dev The storage slots for future usage.
    uint256[50] private __gap;

    /*//////////////////////////////////////////////////////////////////////////
                             CONSTRUCTOR   
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Constructor for `L1ERC20Bridge` implementation contract.
    constructor() {
        _disableInitializers();
    }

    /// @notice Initialize the storage of L1ERC20Bridge.
    /// @param _owner The owner of L1ERC20Bridge in layer-1.
    /// @param _counterPartyERC20Bridge The address of ERC20Bridge on nil-chain
    /// @param _messenger The address of NilMessenger in layer-1.
    function initialize(
        address _owner,
        address _defaultAdmin,
        address _wethToken,
        address _counterPartyERC20Bridge,
        address _messenger,
        address _nilGasPriceOracle
    )
        external
        initializer
    {
        // Validate input parameters
        if (_owner == address(0)) {
            revert ErrorInvalidOwner();
        }

        if (_defaultAdmin == address(0)) {
            revert ErrorInvalidDefaultAdmin();
        }

        if (_wethToken == address(0)) {
            revert ErrorInvalidWethToken();
        }

        if (_counterPartyERC20Bridge == address(0)) {
            revert ErrorInvalidCounterpartyERC20Bridge();
        }

        if (_messenger == address(0)) {
            revert ErrorInvalidMessenger();
        }

        if (_nilGasPriceOracle == address(0)) {
            revert ErrorInvalidNilGasPriceOracle();
        }

        // Initialize the Ownable contract with the owner address
        OwnableUpgradeable.__Ownable_init(_owner);

        // Initialize the Pausable contract
        PausableUpgradeable.__Pausable_init();

        // Initialize the AccessControlEnumerable contract
        __AccessControlEnumerable_init();

        // Set role admins
        // The OWNER_ROLE is set as its own admin to ensure that only the current owner can manage this role.
        _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);

        // The DEFAULT_ADMIN_ROLE is set as its own admin to ensure that only the current default admin can manage this
        // role.
        _setRoleAdmin(DEFAULT_ADMIN_ROLE, OWNER_ROLE);

        // Grant roles to defaultAdmin and owner
        // The DEFAULT_ADMIN_ROLE is granted to both the default admin and the owner to ensure that both have the
        // highest level of control.
        // The PROPOSER_ROLE_ADMIN is granted to both the default admin and the owner to allow them to manage proposers.
        // The OWNER_ROLE is granted to the owner to ensure they have the highest level of control over the contract.
        _grantRole(OWNER_ROLE, _owner);
        _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);

        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

        wethToken = _wethToken;
        counterpartyBridge = _counterPartyERC20Bridge;
        messenger = _messenger;
        nilGasPriceOracle = _nilGasPriceOracle;
    }

    /// @inheritdoc IL1Bridge
    function setRouter(address _router) external override onlyOwner {
        router = _router;
    }

    /// @inheritdoc IL1Bridge
    function setMessenger(address _messenger) external override onlyOwner {
        messenger = _messenger;
    }

    /// @inheritdoc IL1Bridge
    function setNilGasPriceOracle(address _nilGasPriceOracle) external override onlyOwner {
        nilGasPriceOracle = _nilGasPriceOracle;
    }

    /*//////////////////////////////////////////////////////////////////////////
                             PUBLIC MUTATING FUNCTIONS   
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IL1ERC20Bridge
    function depositERC20(
        address token,
        address l2DepositRecipient,
        uint256 depositAmount,
        address l2FeeRefundRecipient,
        uint256 l2GasLimit,
        uint256 userFeePerGas,
        uint256 userMaxPriorityFeePerGas
    )
        external
        payable
        override
    {
        _deposit(
            token,
            l2DepositRecipient,
            depositAmount,
            l2FeeRefundRecipient,
            new bytes(0),
            l2GasLimit,
            userFeePerGas,
            userMaxPriorityFeePerGas
        );
    }

    /// @inheritdoc IL1ERC20Bridge
    function depositERC20AndCall(
        address token,
        address l2DepositRecipient,
        uint256 depositAmount,
        address l2FeeRefundRecipient,
        bytes memory data,
        uint256 l2GasLimit,
        uint256 userFeePerGas,
        uint256 userMaxPriorityFeePerGas
    )
        external
        payable
        override
    {
        _deposit(
            token,
            l2DepositRecipient,
            depositAmount,
            l2FeeRefundRecipient,
            data,
            l2GasLimit,
            userFeePerGas,
            userMaxPriorityFeePerGas
        );
    }

    /// @inheritdoc IL1ERC20Bridge
    function getL2TokenAddress(address _l1TokenAddress) external view override returns (address) {
        return tokenMapping[_l1TokenAddress];
    }

    /// @inheritdoc IL1Bridge
    function cancelDeposit(bytes32 messageHash) external payable override nonReentrant {
        address caller = _msgSender();

        // get DepositMessageDetails
        IL1BridgeMessenger.DepositMessage memory depositMessage =
            IL1BridgeMessenger(messenger).getDepositMessage(messageHash);

        // Decode the message to extract the token address and the original sender (_from)
        (address l1TokenAddress,, address depositorAddress,, uint256 l1TokenAmount,) =
            abi.decode(depositMessage.message, (address, address, address, address, uint256, bytes));

        if (caller != router && caller != depositorAddress) {
            revert UnAuthorizedCaller();
        }

        if (depositMessage.depositType != IL1BridgeMessenger.DepositType.ERC20) {
            revert InvalidDepositType();
        }

        // L1BridgeMessenger to verify if the deposit can be cancelled
        IL1BridgeMessenger(messenger).cancelDeposit(messageHash);

        // refund the deposited ERC20 tokens to the depositor
        ERC20(l1TokenAddress).safeTransfer(depositorAddress, l1TokenAmount);

        emit DepositCancelled(messageHash, l1TokenAddress, depositorAddress, l1TokenAmount);
    }

    /*//////////////////////////////////////////////////////////////////////////
                             INTERNAL-FUNCTIONS   
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Internal function to transfer ERC20 token to this contract.
    /// @param _token The address of token to transfer.
    /// @param _depositAmount The amount of token to transfer.
    /// @param _encodedERC20TransferData The data passed by router or the caller on to bridge.
    /// @dev when depositor calls router, then _encodedERC20TransferData will contain the encoded bytes of
    /// depositorAddress and calldata for the l2 target address
    /// @dev when depositor calls L1ERC20Bridge, then _encodedERC20TransferData will contain calldata for the l2 target
    /// address
    function _transferERC20In(
        address _token,
        uint256 _depositAmount,
        bytes memory _encodedERC20TransferData
    )
        internal
        returns (address, uint256, bytes memory)
    {
        // If the depositor called depositERC20 via L1BridgeRouter, then _sender will be the l1BridgeRouter-address
        // If the depositor called depositERC20 directly on L1ERC20Bridge, then _sender will be the
        // l1ERC20Bridge-address
        address _sender = _msgSender();

        // retain the depositor address
        address _depositor = _sender;

        uint256 _amountPulled = 0;

        // initialize _data to hold the Optional data to forward to recipient's account.
        bytes memory _data = _encodedERC20TransferData;

        if (router == _sender) {
            // as the depositor called depositWETH function via L1BridgeRouter, extract the depositor-address from the
            // _data AKA routerData
            // _data is the data to be sent on the target address on nil-chain
            (_depositor, _data) = abi.decode(_encodedERC20TransferData, (address, bytes));

            // _depositor will be derived from the routerData as the depositor called on router directly
            // _sender will be router-address and its router's responsibility to pull the ERC20Token from depositor to
            // L1ERC20Bridge
            _amountPulled = IL1BridgeRouter(router).pullERC20(_depositor, _token, _depositAmount);
        } else {
            uint256 _tokenBalanceBeforePull = ERC20(_token).balanceOf(address(this));

            // L1ERC20Bridge to transfer ERC20 Tokens from depositor address to the L1ERC20Bridge
            // L1ERC20Bridge must have sufficient approval of spending on ERC20Token
            ERC20(_token).safeTransferFrom(_depositor, address(this), _depositAmount);

            _amountPulled = ERC20(_token).balanceOf(address(this)) - _tokenBalanceBeforePull;
        }

        if (_amountPulled != _depositAmount) {
            revert ErrorIncorrectAmountPulledByBridge();
        }

        return (_depositor, _depositAmount, _data);
    }

    /// @dev Internal function to do all the deposit operations.
    /// @param _token The token to deposit.
    /// @param _l2DepositRecipient The recipient address to recieve the token in L2.
    /// @param _depositAmount The amount of token to deposit.
    /// @param _l2FeeRefundRecipient the address of recipient for excess fee refund on L2.
    /// @param _data Optional data to forward to recipient's account.
    /// @param _nilGasLimit Gas limit required to complete the deposit on L2.
    /// @param _userMaxFeePerGas The maximum Fee per gas unit that the user is willing to pay.
    /// @param _userMaxPriorityFeePerGas The maximum priority fee per gas unit that the user is willing to pay.
    function _deposit(
        address _token,
        address _l2DepositRecipient,
        uint256 _depositAmount,
        address _l2FeeRefundRecipient,
        bytes memory _data,
        uint256 _nilGasLimit,
        uint256 _userMaxFeePerGas,
        uint256 _userMaxPriorityFeePerGas
    )
        internal
        virtual
        nonReentrant
    {
        if (_token == address(0)) {
            revert ErrorInvalidTokenAddress();
        }

        if (_token == wethToken) {
            revert ErrorWETHTokenNotSupportedOnERC20Bridge();
        }

        if (_l2DepositRecipient == address(0)) {
            revert ErrorInvalidL2DepositRecipient();
        }

        if (_depositAmount == 0) {
            revert ErrorEmptyDeposit();
        }

        if (_l2FeeRefundRecipient == address(0)) {
            revert ErrorInvalidL2FeeRefundRecipient();
        }

        if (_nilGasLimit == 0) {
            revert ErrorInvalidNilGasLimit();
        }

        address _l2Token = tokenMapping[_token];

        //TODO compute l2TokenAddress
        // update the mapping

        if (_l2Token == address(0)) {
            revert ErrorInvalidL2Token();
        }

        // Transfer token into Bridge contract
        (address _depositorAddress,,) = _transferERC20In(_token, _depositAmount, _data);

        INilGasPriceOracle.FeeCreditData memory feeCreditData = INilGasPriceOracle(nilGasPriceOracle).computeFeeCredit(
            _nilGasLimit, _userMaxFeePerGas, _userMaxPriorityFeePerGas
        );

        if (msg.value < feeCreditData.feeCredit) {
            revert ErrorInsufficientValueForFeeCredit();
        }

        // Generate message passed to L2ERC20Bridge
        bytes memory _message = abi.encodeCall(
            IL2ERC20Bridge.finalizeDepositERC20,
            (_token, _l2Token, _depositorAddress, _l2DepositRecipient, _l2FeeRefundRecipient, _depositAmount, _data)
        );

        // Send message to L1BridgeMessenger.
        IL1BridgeMessenger(messenger).sendMessage{ value: msg.value }(
            IL1BridgeMessenger.DepositType.ERC20,
            counterpartyBridge,
            0,
            _message,
            _nilGasLimit,
            _depositorAddress,
            feeCreditData
        );

        emit DepositERC20(_token, _l2Token, _depositorAddress, _l2DepositRecipient, _depositAmount, _data);
    }

    /*//////////////////////////////////////////////////////////////////////////
                             RESTRICTED FUNCTIONS   
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBridge
    function setPause(bool _status) external onlyOwner {
        if (_status) {
            _pause();
        } else {
            _unpause();
        }
    }

    /// @inheritdoc IBridge
    function transferOwnershipRole(address newOwner) external override onlyOwner {
        _revokeRole(OWNER_ROLE, owner());
        super.transferOwnership(newOwner);
        _grantRole(OWNER_ROLE, newOwner);
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == type(IL1Bridge).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}
