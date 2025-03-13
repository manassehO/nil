// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IL1BridgeRouter {
  /*//////////////////////////////////////////////////////////////////////////
                             ERRORS   
    //////////////////////////////////////////////////////////////////////////*/

  /// @dev Invalid owner address.
  error ErrorInvalidOwner();

  error ErrorUnauthorizedCaller();

  error ErrorWETHTokenNotSupported();

  /// @dev Invalid default admin address.
  error ErrorInvalidDefaultAdmin();

  error ErrorERC20PullFailed();

  error ErrorInvalidTokenAddress();

  error ErrorInvalidL1ERC20BridgeAddress();

  error ErrorInvalidDepositType();

  error ErrorEmptyDeposit();

  error ErrorInvalidNilGasLimit();

  error ErrorInvalidL1ETHBridgeAddress();

  error ErrorInvalidL2DepositRecipient();

  error ErrorInvalidL2FeeRefundRecipient();

  /**
   * @notice Emitted when the L1ERC20Bridge address is set.
   * @param oldL1ERC20Bridge The previous L1ERC20Bridge address.
   * @param newL1ERC20Bridge The new L1ERC20Bridge address.
   */
  event L1ERC20BridgeSet(address indexed oldL1ERC20Bridge, address indexed newL1ERC20Bridge);

  /**
   * @notice Emitted when the L1ETHBridge address is set.
   * @param oldL1ETHBridge The previous L1ETHBridge address.
   * @param newL1ETHBridge The new L1ETHBridge address.
   */
  event L1ETHBridgeSet(address indexed oldL1ETHBridge, address indexed newL1ETHBridge);

  /**
   * @notice Emitted when the L1BridgeMessenger address is set.
   * @param oldL1BridgeMessenger The previous L1BridgeMessenger address.
   * @param newL1BridgeMessenger The new L1BridgeMessenger address.
   */
  event L1BridgeMessengerSet(address indexed oldL1BridgeMessenger, address indexed newL1BridgeMessenger);

  /**
   * @notice Returns the L2 token address corresponding to the given L1 token address.
   * @param l1TokenAddress The address of the L1 token.
   * @return The address of the corresponding L2 token.
   */
  function getL2TokenAddress(address l1TokenAddress) external view returns (address);

  /**
   * @notice Returns the address of the L1ERC20Bridge contract.
   * @return The address of the L1ERC20Bridge contract.
   */
  function l1ERC20Bridge() external view returns (address);

  /**
   * @notice Returns the address of the L1ETHBridge contract.
   * @return The address of the L1ETHBridge contract.
   */
  function l1ETHBridge() external view returns (address);

  /**
   * @notice Returns the address of the L1WETH contract.
   * @return The address of the L1WETH contract.
   */
  function l1WETHAddress() external view returns (address);

  /**
   * @notice Sets the address of the L1ERC20Bridge contract.
   * @param newERC20Bridge The new address of the L1ERC20Bridge contract.
   */
  function setL1ERC20Bridge(address newERC20Bridge) external;

  /**
   * @notice Sets the address of the L1ETHBridge contract.
   * @param newL1ETHBridge The new address of the L1ETHBridge contract.
   */
  function setL1ETHBridge(address newL1ETHBridge) external;

  /**
   * @notice Pulls ERC20 tokens from the sender to the bridge contract.
   * @dev This function can only be called by authorized bridge contracts.
   * @dev All bridge contracts must have reentrancy guard to prevent potential attack through this function.
   * @dev L1Bridge Contract - L1ERC20Bridge will call this function to let the router pull the tokens from the depositor to the corresponding bridge address.
   * @dev This function is invoked only when the depositor calls L1BridgeRouter for bridging.
   * @param sender The address of the sender from whom the tokens will be pulled.
   * @param token The address of the ERC20 token to be pulled.
   * @param amount The amount of tokens to be pulled.
   * @return The actual amount of tokens pulled.
   */
  function pullERC20(address sender, address token, uint256 amount) external returns (uint256);

  /**
   * @notice Initiates the ERC20 tokens to the nil-chain. for a specified recipient.
   * @param token The address of the ERC20 in L1 token to deposit.
   * @param l2DepositRecipient The recipient address to receive the token in nil-chain.
   * @param depositAmount The amount of tokens to deposit.
   * @param l2FeeRefundRecipient The recipient address to recieve the excess fee refund on nil-chain
   * @param nilGasLimit The gas limit required to complete the deposit on nil-chain.
   */
  function depositERC20(
    address token,
    address l2DepositRecipient,
    uint256 depositAmount,
    address l2FeeRefundRecipient,
    uint256 nilGasLimit,
    uint256 userMaxFeePerGas,
    uint256 userMaxPriorityFeePerGas
  ) external payable;

  /**
   * @notice Deposits ERC20 tokens to the nil-chain for a specified recipient and calls a function on the recipient's
   * contract.
   * @param token The address of the ERC20 in L1 token to deposit.
   * @param l2DepositRecipient The recipient address to receive the token in nil-chain.
   * @param depositAmount The amount of tokens to deposit.
   * @param depositAmount The recipient address to recieve the excess fee refund on nil-chain
   * @param data Optional data to forward to the recipient's account.
   * @param nilGasLimit The gas limit required to complete the deposit on nil-chain.
   */
  function depositERC20AndCall(
    address token,
    address l2DepositRecipient,
    uint256 depositAmount,
    address l2FeeRefundRecipient,
    bytes memory data,
    uint256 nilGasLimit,
    uint256 userFeePerGas,
    uint256 userMaxFeePerGas
  ) external payable;

  /**
   * @notice Initiates the ETH to the nil-chain. for a specified recipient.
   * @param l2DepositRecipient The recipient address to receive the token in nil-chain.
   * @param depositAmount The amount of ETH to deposit.
   * @param l2FeeRefundRecipient The recipient address for excess-fee refund on nil-chain
   * @param nilGasLimit The gas limit required to complete the deposit on nil-chain..
   */
  function depositETH(
    address l2DepositRecipient,
    uint256 depositAmount,
    address l2FeeRefundRecipient,
    uint256 nilGasLimit,
    uint256 userFeePerGas,
    uint256 userMaxFeePerGas
  ) external payable;

  /**
   * @notice Deposits ETH to the nil-chain for a specified recipient and calls a function on the recipient's
   * contract.
   * @param l2DepositRecipient The recipient address to receive the ETH in nil-chain.
   * @param depositAmount The amount of ETH to deposit.
   * @param l2FeeRefundRecipient The recipient address for excess-fee refund on nil-chain
   * @param data Optional data to forward to the recipient's account.
   * @param nilGasLimit The gas limit required to complete the deposit on nil-chain.
   */
  function depositETHAndCall(
    address l2DepositRecipient,
    uint256 depositAmount,
    address l2FeeRefundRecipient,
    bytes memory data,
    uint256 nilGasLimit,
    uint256 userFeePerGas,
    uint256 userMaxFeePerGas
  ) external payable;

  function cancelDeposit(bytes32 messageHash) external payable;

  function claimFailedDeposit(bytes32 messageHash, bytes32[] memory claimProof) external;

  /**
   * @notice Pauses or unpauses the contract.
   * @dev This function allows the owner to pause or unpause the contract.
   * @param statusValue The pause status to update.
   */
  function setPause(bool statusValue) external;

  /**
   * @notice transfers ownership to the newOwner.
   * @dev This function revokes the `OWNER_ROLE` from the current owner, calls `acceptOwnership` using
   * OwnableUpgradeable's `transferOwnership` transfer the owner rights to newOwner
   * @param newOwner The address of the new owner.
   */
  function transferOwnershipRole(address newOwner) external;
}
